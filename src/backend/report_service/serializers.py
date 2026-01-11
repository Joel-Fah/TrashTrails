from rest_framework import serializers
from django.contrib.auth.models import User

from map_service.serializers import LocationSerializer
from .models import Report, TrashCategory, ReportSeverity, ReportImage


class UserPublicSerializer(serializers.ModelSerializer):
    """Public user info - no sensitive data"""
    avatar = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "username", "first_name", "last_name", "avatar"]
        ref_name = 'ReportUserPublic'

    def get_avatar(self, obj):
        try:
            return obj.userprofile.avatar if hasattr(obj, 'userprofile') else None
        except Exception:
            return None


class TrashCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = TrashCategory
        fields = ["id", "code", "name", "description"]


class ReportSeveritySerializer(serializers.ModelSerializer):
    class Meta:
        model = ReportSeverity
        fields = ["id", "level", "name", "description"]


class ReportImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReportImage
        fields = ["id", "image", "uploaded_at"]


class ReportSerializer(serializers.ModelSerializer):
    user = UserPublicSerializer(read_only=True)
    category = TrashCategorySerializer(read_only=True)
    severity = ReportSeveritySerializer(read_only=True)
    location = LocationSerializer(read_only=True)
    images = ReportImageSerializer(many=True, read_only=True)

    class Meta:
        model = Report
        fields = [
            "id",
            "user",
            "title",
            "observation",
            "status",
            "severity",
            "category",
            "location",
            "images",
            "created_at",
            "updated_at",
        ]


class ReportCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Report
        fields = [
            "title",
            "observation",
            "severity",
            "category",
            "location",
        ]
