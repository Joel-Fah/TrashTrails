from django.db import models
from django.contrib.auth.models import User
from report_service.models import Report

class MLResult(models.Model):
    report = models.OneToOneField(
        Report,
        on_delete=models.CASCADE
    )
    recyclable_detected = models.BooleanField()
    materials = models.JSONField()  # ["Plastic", "Glass", "Metal"]
    confidence_score = models.FloatField()
    analyzed_at = models.DateTimeField(auto_now_add=True)

    def summarize(self):
        return {
            "recyclable": self.recyclable_detected,
            "materials": self.materials,
            "confidence": self.confidence_score
        }
