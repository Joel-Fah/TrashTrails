from rest_framework.viewsets import ModelViewSet, ReadOnlyModelViewSet
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import Report, TrashCategory, ReportSeverity
from .permissions import IsOwnerOrReadOnly
from .serializers import (
    ReportSerializer,
    ReportCreateUpdateSerializer,
    TrashCategorySerializer,
    ReportSeveritySerializer,
)
from leaderboard_service.services import score_service, get_user_ranks
import logging

logger = logging.getLogger(__name__)


class ReportViewSet(ModelViewSet):
    permission_classes = [IsAuthenticated, IsOwnerOrReadOnly]
    parser_classes = (MultiPartParser, FormParser, JSONParser)
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ["title", "observation"]
    ordering_fields = ["created_at"]
    ordering = ["-created_at"]

    def get_queryset(self):
        return Report.objects.select_related("category", "severity", "location", "user").prefetch_related('images')

    def get_permissions(self):
        # Allow anyone to list and retrieve reports
        if self.action in ["list", "retrieve"]:
            return [AllowAny()]
        return super().get_permissions()

    def get_serializer_class(self):
        if self.action in ["create", "update", "partial_update"]:
            return ReportCreateUpdateSerializer
        return ReportSerializer

    def perform_create(self, serializer):
        # serializer should handle creation of ReportImage from validated_data['images']
        serializer.save(user=self.request.user)

    def create(self, request, *args, **kwargs):
        """
        Create a new report and calculate points for the user.
        Accepts multipart/form-data with images or JSON body with images as base64/list.
        """
        # Note: DRF merges request.data and request.FILES when using MultiPartParser,
        # so passing request.data is sufficient. The serializer's ImageListField
        # also supports dict mapping of files.
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        # Get the created report with all related data
        report = Report.objects.select_related(
            'category', 'severity', 'location', 'user'
        ).prefetch_related('images').get(pk=serializer.instance.pk)

        # Calculate and award points
        points_result = score_service.award_report_points(report)

        # Prepare response with report data and points
        response_serializer = ReportSerializer(report, context={'request': request})
        response_data = response_serializer.data

        try:
            ranks = get_user_ranks(request.user)
            # placer le overall rank au top-level de la response
            response_data['overall_rank'] = ranks.get('overall_rank')
        except Exception:
            logger.exception('Failed to compute overall rank for user=%s', getattr(request.user, 'id', None))
            response_data['overall_rank'] = None

        response_data['points'] = {
            'points_awarded': points_result['points_awarded'],
            'breakdown': points_result['breakdown'],
            'total_user_points': points_result['total_user_points'],
        }

        # Include applied transaction details (if available) to clarify why points_awarded may be 0
        tx_id = points_result.get('transaction_id')
        if tx_id:
            try:
                from leaderboard_service.models import ScoreTransaction
                tx = ScoreTransaction.objects.filter(id=tx_id).values('id', 'points', 'transaction_type', 'created_at').first()
                if tx:
                    response_data['points']['applied_transaction'] = tx
                    # If service returned 0 because transaction already existed, report the actual awarded points
                    if response_data['points']['points_awarded'] == 0 and tx['transaction_type'] == ScoreTransaction.TransactionType.REPORT_CREATED:
                        response_data['points']['points_awarded'] = tx['points']
                        response_data['points']['note'] = 'points were awarded earlier (transaction exists)'
            except Exception:
                logger.exception('Failed to fetch applied transaction info for tx_id=%s', tx_id)

        headers = self.get_success_headers(serializer.data)
        return Response(response_data, status=status.HTTP_201_CREATED, headers=headers)

    @action(detail=False, methods=["get"], permission_classes=[IsAuthenticated], url_path="me")
    def my_reports(self, request):
        """Get reports for the currently authenticated user (for profile page)"""
        queryset = self.get_queryset().filter(user=request.user)
        queryset = self.filter_queryset(queryset)

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class TrashCategoryViewSet(ReadOnlyModelViewSet):
    queryset = TrashCategory.objects.all()
    serializer_class = TrashCategorySerializer
    permission_classes = [IsAuthenticated]


class ReportSeverityViewSet(ReadOnlyModelViewSet):
    queryset = ReportSeverity.objects.all()
    serializer_class = ReportSeveritySerializer
    permission_classes = [IsAuthenticated]
