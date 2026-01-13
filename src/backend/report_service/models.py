from django.db import models
from django.contrib.auth.models import User
from map_service.models import Location
from django.utils.text import slugify
import uuid


class Report(models.Model):
    class ReportStatus(models.TextChoices):
        PENDING = "PENDING", "Pending"
        VERIFIED = "VERIFIED", "Verified"
        REJECTED = "REJECTED", "Rejected"
        CLEANED = "CLEANED", "Cleaned"

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE
    )
    title = models.CharField(max_length=255)
    slug = models.SlugField(
        max_length=255,
        unique=True,
        blank=True,
        editable=False
    )
    location = models.ForeignKey(
        Location,
        on_delete=models.CASCADE
    )
    observation = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=ReportStatus.choices,
        default=ReportStatus.PENDING
    )
    severity = models.ForeignKey(
        'ReportSeverity',
        on_delete=models.PROTECT,
        related_name="reports"
    )

    category = models.ForeignKey(
        'TrashCategory',
        on_delete=models.PROTECT,
        related_name="reports"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.title:
            unique_id = uuid.uuid4().hex[:8]
            self.title = f"Untitled Report {unique_id}"

        if not self.slug:
            base_slug = slugify(self.title)
            slug = base_slug
            counter = 1
            while Report.objects.filter(slug=slug).exclude(pk=self.pk).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1
            self.slug = slug

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

    def __str__(self):
        return f"Image for Report: {self.report.title}"


class TrashCategory(models.Model):
    code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = "Trash Categories"

    def __str__(self):
        return self.name


class ReportSeverity(models.Model):
    level = models.PositiveSmallIntegerField(unique=True)
    name = models.CharField(max_length=50)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ["level"]
        verbose_name_plural = "Report Severities"

    def __str__(self):
        return f"{self.name} ({self.level})"
