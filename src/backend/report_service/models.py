from django.db import models
from django.contrib.auth.models import User
from map_service.models import Location

class Report(models.Model):
    class Status(models.TextChoices):
        PENDING = 'PENDING'
        APPROVED = 'APPROVED'
        REJECTED = 'REJECTED'

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE
    )
    title = models.CharField(max_length=255)
    street_name = models.CharField(max_length=255)
    location = models.ForeignKey(
        Location,
        on_delete=models.CASCADE
    )
    observation = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.APPROVED
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.title:
            self.title = "Untitled Report"
        super().save(*args, **kwargs)

    def __str__(self):
        return self.title


class ReportImage(models.Model):
    report = models.ForeignKey(
        Report,
        on_delete=models.CASCADE,
        related_name='images'
    )
    image = models.ImageField(upload_to='reports/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
