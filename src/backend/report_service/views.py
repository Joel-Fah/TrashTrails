from rest_framework.viewsets import ModelViewSet, ReadOnlyModelViewSet
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response
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


class ReportViewSet(ModelViewSet):
    permission_classes = [IsAuthenticated, IsOwnerOrReadOnly]
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
        serializer.save(user=self.request.user)

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
