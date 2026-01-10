from django.db import models


class Location(models.Model):
    latitude = models.FloatField()
    longitude = models.FloatField()
    address = models.CharField(
        max_length=255,
        blank=True
    )

    def __str__(self):
        return f"{self.latitude}, {self.longitude}"

    def validate_coordinates(self):
        return -90 <= self.latitude <= 90 and -180 <= self.longitude <= 180
