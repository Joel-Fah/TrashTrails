from rest_framework import serializers
from django.contrib.auth.models import User

from map_service.serializers import LocationSerializer
from map_service.models import Location
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


class LocationRelatedField(serializers.PrimaryKeyRelatedField):
    """
    Accept either a primary key (int) pointing to an existing Location
    or a dict with {lat|latitude, long|lng|longitude, street_name} to create/get a Location.
    Also accepts a JSON-encoded string for multipart/form-data.
    """

    def to_internal_value(self, data):
        # If data is a JSON string (common in multipart form posts), try to parse it
        if isinstance(data, str):
            data_str = data.strip()
            if (data_str.startswith('{') and data_str.endswith('}')) or (data_str.startswith('[') and data_str.endswith(']')):
                try:
                    import json
                    parsed = json.loads(data_str)
                    data = parsed
                except Exception:
                    # fall through and treat as scalar (pk)
                    pass

        # If dict, create or get Location by coordinates
        if isinstance(data, dict):
            lat = data.get('lat') or data.get('latitude')
            lng = data.get('long') or data.get('lng') or data.get('longitude')
            street = data.get('street_name') or data.get('streetName') or ''

            if lat is None or lng is None:
                raise serializers.ValidationError("location must include latitude and longitude")

            try:
                lat_f = float(lat)
                lng_f = float(lng)
            except (TypeError, ValueError):
                raise serializers.ValidationError("latitude and longitude must be numeric")

            # get_or_create to avoid exact duplicates at identical coords
            obj, created = Location.objects.get_or_create(
                latitude=lat_f,
                longitude=lng_f,
                defaults={'street_name': street or ''}
            )
            return obj

        # If scalar (assume ID), use default PK related behaviour
        return super().to_internal_value(data)


class ImageListField(serializers.ListField):
    """Field that accepts either a list of images or a dict mapping to images."""

    child = serializers.ImageField()

    def to_internal_value(self, data):
        # If data is a dict (e.g., {"0": <file>, "1": <file>}) convert to list
        if isinstance(data, dict):
            # Keep ordering if integer keys; otherwise just values
            try:
                # keys might be like '0','1' or filenames
                items = [data[k] for k in sorted(data.keys(), key=lambda x: int(x) if str(x).isdigit() else x)]
            except Exception:
                items = list(data.values())
            return super().to_internal_value(items)

        # If single file provided (not a list), wrap it
        if not isinstance(data, (list, tuple)):
            data = [data]
        return super().to_internal_value(data)


class ReportCreateUpdateSerializer(serializers.ModelSerializer):
    # Accept ID or object for location
    location = LocationRelatedField(queryset=Location.objects.all(), required=False, allow_null=True)
    # Accept images as list or dict (files) — write-only
    images = ImageListField(child=serializers.ImageField(), write_only=True, required=False)

    class Meta:
        model = Report
        fields = [
            "title",
            "observation",
            "severity",
            "category",
            "location",
            "images",
        ]

    def create(self, validated_data):
        images = validated_data.pop('images', None)
        report = super().create(validated_data)
        if images:
            for img in images:
                ReportImage.objects.create(report=report, image=img)
        return report

    def update(self, instance, validated_data):
        images = validated_data.pop('images', None)
        report = super().update(instance, validated_data)
        if images:
            for img in images:
                ReportImage.objects.create(report=report, image=img)
        return report
