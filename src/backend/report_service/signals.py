from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db.utils import OperationalError, ProgrammingError
import logging

logger = logging.getLogger(__name__)

# Import Report model lazily for decorator sender assignment
try:
    from report_service.models import Report as ReportModel
except Exception:
    ReportModel = None

# Import ReportImage model lazily for image handlers
try:
    from report_service.models import ReportImage as ReportImageModel
except Exception:
    ReportImageModel = None


if ReportModel is not None:
    @receiver(post_save, sender=ReportModel)
    def report_post_save(sender, instance, created, **kwargs):
        """
        Handle post_save for Report creation.

        We no longer award points here on creation because in the admin the report is
        created before inlines (images) are saved; doing so would compute points
        without images. Instead admin and API explicitly call the score service after
        all related objects are saved.
        """
        # Do not award points here on creation; admin will call award after inlines.
        if created:
            return

        # For now we don't handle non-creation updates here. Specific events
        # (e.g., verification) can be handled with dedicated logic.
        return


# If ReportImage model exists, attach handlers to recalculate/adjust points when images change
if ReportImageModel is not None:
    @receiver(post_save, sender=ReportImageModel)
    def report_image_saved(sender, instance, created, **kwargs):
        """When an image is added to a report, recalculate points and award delta."""
        try:
            from leaderboard_service.models import ScoreTransaction
            from leaderboard_service.services import score_service
        except (OperationalError, ProgrammingError, ImportError) as e:
            logger.debug("Skipping image-based point award: %s", e)
            return
        except Exception as e:
            logger.exception("Unexpected error importing leaderboard components for image: %s", e)
            return

        report = getattr(instance, 'report', None)
        if not report:
            logger.debug("ReportImage %s has no report; skipping point recalculation.", getattr(instance, 'pk', None))
            return

        try:
            score_service.award_report_points(report)
            logger.info("Adjusted points after image save for report %s", report.pk)
        except Exception as exc:
            logger.exception("Failed to adjust points after image save for report %s: %s", report.pk, exc)


    @receiver(post_delete, sender=ReportImageModel)
    def report_image_deleted(sender, instance, **kwargs):
        """When an image is removed from a report, recalculate points and apply delta (possibly penalty)."""
        try:
            from leaderboard_service.models import ScoreTransaction
            from leaderboard_service.services import score_service
        except (OperationalError, ProgrammingError, ImportError) as e:
            logger.debug("Skipping image-deletion point adjustment: %s", e)
            return
        except Exception as e:
            logger.exception("Unexpected error importing leaderboard components for image delete: %s", e)
            return

        report = getattr(instance, 'report', None)
        if not report:
            logger.debug("ReportImage deleted but no associated report found (image id=%s)", getattr(instance, 'pk', None))
            return

        try:
            score_service.award_report_points(report)
            logger.info("Adjusted points after image delete for report %s", report.pk)
        except Exception as exc:
            logger.exception("Failed to adjust points after image delete for report %s: %s", report.pk, exc)
