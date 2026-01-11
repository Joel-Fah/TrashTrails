from rest_framework import serializers

from map_service.models import Location


class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        fields = ["id", "latitude", "longitude", "street_name"]