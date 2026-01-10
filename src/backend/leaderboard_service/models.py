from django.db import models
from django.contrib.auth.models import User
from report_service.models import Report


class Endorsement(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE
    )
    report = models.ForeignKey(
        Report,
        on_delete=models.CASCADE
    )
    endorsed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'report')


class ScoreRule(models.Model):
    action_type = models.CharField(max_length=100)
    points = models.IntegerField()
    description = models.TextField(blank=True)
