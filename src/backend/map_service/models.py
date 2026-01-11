from django.db import models


class Location(models.Model):
    latitude = models.FloatField()
    longitude = models.FloatField()
    street_name = models.CharField(
        max_length=255,
        blank=True
    )

    def __str__(self):
        if self.street_name:
            return f"{self.street_name} ({self.latitude:.2f}, {self.longitude:.2f})"
        return f"({self.latitude:.2f}, {self.longitude:.2f})"

    def validate_coordinates(self):
        return -90 <= self.latitude <= 90 and -180 <= self.longitude <= 180
