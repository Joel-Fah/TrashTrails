from rest_framework.viewsets import ModelViewSet, ReadOnlyModelViewSet
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db import transaction

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

        IMPORTANT: All point calculation happens synchronously AFTER images are saved,
        ensuring the response includes accurate points.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Save the report and all images (serializer handles this)
        with transaction.atomic():
            self.perform_create(serializer)
            report_id = serializer.instance.pk

        # NOW fetch the report with ALL related data (outside transaction, fully committed)
        report = Report.objects.select_related(
            'category', 'severity', 'location', 'user'
        ).prefetch_related('images').get(pk=report_id)

        # Log image count for debugging
        image_count = report.images.count()
        logger.info(f"Report {report.pk} created with {image_count} images")

        # Calculate and award points SYNCHRONOUSLY after all images are saved
        # This happens WITHIN the transaction, so the response will wait for completion
        points_result = score_service.award_report_points(report)

        logger.info(f"Points calculated for report {report.pk}: {points_result}")

        # Prepare response with report data and points
        response_serializer = ReportSerializer(report, context={'request': request})
        response_data = response_serializer.data

        # Add user rank to response
        try:
            ranks = get_user_ranks(request.user)
            response_data['overall_rank'] = ranks.get('overall_rank')
            response_data['user_rank'] = ranks  # Include all ranks
        except Exception as e:
            logger.exception('Failed to compute ranks for user=%s: %s', getattr(request.user, 'id', None), str(e))
            response_data['overall_rank'] = None
            response_data['user_rank'] = None

        # Add points breakdown to response
        breakdown = points_result.get('breakdown', {}) or {}

        # Calculate sum from breakdown for consistency
        try:
            sum_breakdown = sum(int(v.get('points', 0)) for v in breakdown.values() if isinstance(v, dict))
        except Exception:
            sum_breakdown = 0

        # Use the points_awarded from service (should match breakdown sum for new reports)
        raw_awarded = points_result.get('points_awarded')
        try:
            awarded = int(raw_awarded) if raw_awarded is not None else sum_breakdown
        except Exception:
            awarded = sum_breakdown

        # For new reports (REPORT_CREATED), awarded should equal breakdown sum
        # Log warning if there's a mismatch
        if awarded != sum_breakdown:
            logger.warning(
                "Points mismatch for report %s: points_awarded=%s but breakdown sum=%s. Using breakdown sum.",
                report.pk, awarded, sum_breakdown
            )
            awarded = sum_breakdown

        response_data['points'] = {
            'points_awarded': int(awarded),
            'breakdown': breakdown,
            'total_user_points': int(points_result.get('total_user_points', 0)),
        }

        # Include transaction details if available
        tx_id = points_result.get('transaction_id')
        if tx_id:
            try:
                from leaderboard_service.models import ScoreTransaction
                tx = ScoreTransaction.objects.filter(id=tx_id).values(
                    'id', 'points', 'transaction_type', 'created_at'
                ).first()
                if tx:
                    response_data['points']['transaction'] = {
                        'id': tx['id'],
                        'points': int(tx['points']),
                        'type': tx['transaction_type'],
                        'created_at': tx['created_at'].isoformat() if tx['created_at'] else None
                    }
            except Exception as e:
                logger.exception('Failed to fetch transaction info for tx_id=%s: %s', tx_id, str(e))

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