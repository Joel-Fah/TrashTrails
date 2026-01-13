from django.apps import AppConfig
from django.db.utils import OperationalError, ProgrammingError


class ReportServiceConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "report_service"
    verbose_name = "Report Service"

    def ready(self):
        from .models import TrashCategory, ReportSeverity

        try:
            self._seed_trash_categories(TrashCategory)
            self._seed_report_severities(ReportSeverity)
        except (OperationalError, ProgrammingError):
            # DB not ready yet (e.g. during migrations)
            pass

        # Import signals safely (don't break during migrations)
        try:
            from . import signals  # noqa: F401
        except (OperationalError, ProgrammingError, ImportError):
            # Signals may depend on DB tables or other modules not ready during migrate
            pass

    def _seed_trash_categories(self, trash_category):
        categories = [
            ("household", "Household Waste", "Daily domestic waste"),
            ("construction", "Construction Debris", "Bricks, cement, rubble"),
            ("electronic", "E-Waste", "Electronic devices and components"),
            ("hazardous", "Hazardous Materials", "Toxic or dangerous waste"),
            ("organic", "Organic Waste", "Biodegradable waste"),
            ("plastic", "Plastic", "Plastic materials"),
            ("metal", "Metal", "Metal waste"),
            ("glass", "Glass", "Glass waste"),
            ("mixed", "Mixed Waste", "Multiple waste types"),
            ("other", "Other", "Unclassified waste"),
        ]

        for code, name, description in categories:
            trash_category.objects.get_or_create(
                code=code,
                defaults={
                    "name": name,
                    "description": description,
                },
            )

    def _seed_report_severities(self, report_severity):
        severities = [
            (1, "Low", "Minor issue"),
            (2, "Medium", "Needs attention"),
            (3, "High", "Serious issue"),
            (4, "Critical", "Immediate action required"),
        ]

        for level, name, description in severities:
            report_severity.objects.get_or_create(
                level=level,
                defaults={
                    "name": name,
                    "description": description,
                },
            )
