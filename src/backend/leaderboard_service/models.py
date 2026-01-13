from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.db.models import Sum
from datetime import timedelta


class PointConfiguration(models.Model):
    """
    Configuration for point attribution rules.
    Each category of contribution has configurable point values.
    """

    class ConfigType(models.TextChoices):
        TITLE = "TITLE", "Proper Title"
        SEVERITY = "SEVERITY", "Severity Level"
        CATEGORY_RARE = "CATEGORY_RARE", "Rare Category"
        CATEGORY_COMMON = "CATEGORY_COMMON", "Common Category"
        CATEGORY_GENERIC = "CATEGORY_GENERIC", "Generic Category"
        OBSERVATION_MIN = "OBSERVATION_MIN", "Observation Minimum"
        OBSERVATION_PER_CHAR = "OBSERVATION_PER_CHAR", "Observation Per Character"
        OBSERVATION_DEFAULT = "OBSERVATION_DEFAULT", "Observation Default"
        LOCATION = "LOCATION", "Location Filled"
        IMAGE_FIRST = "IMAGE_FIRST", "First Image"
        IMAGE_ADDITIONAL = "IMAGE_ADDITIONAL", "Additional Image"
        IMAGE_MAX_COUNT = "IMAGE_MAX_COUNT", "Max Images Count for Points"

    config_type = models.CharField(
        max_length=50,
        choices=ConfigType.choices,
        unique=True
    )
    points = models.IntegerField(default=0)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Point Configuration"
        verbose_name_plural = "Point Configurations"

    def __str__(self):
        return f"{self.get_config_type_display()}: {self.points} pts"


class CategoryPointMultiplier(models.Model):
    """
    Custom point multipliers for specific trash categories.
    Rarer categories get higher multipliers.
    """
    category = models.OneToOneField(
        'report_service.TrashCategory',
        on_delete=models.CASCADE,
        related_name='point_multiplier'
    )
    multiplier = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        default=1.0,
        help_text="Point multiplier for this category (e.g., 1.5 = 50% more points)"
    )
    rarity_level = models.CharField(
        max_length=20,
        choices=[
            ('COMMON', 'Common'),
            ('UNCOMMON', 'Uncommon'),
            ('RARE', 'Rare'),
            ('VERY_RARE', 'Very Rare'),
        ],
        default='COMMON'
    )

    class Meta:
        verbose_name = "Category Point Multiplier"
        verbose_name_plural = "Category Point Multipliers"

    def __str__(self):
        return f"{self.category.name}: x{self.multiplier}"


class SeverityPointValue(models.Model):
    """
    Point values for each severity level.
    Higher severity = more points.
    """
    severity = models.OneToOneField(
        'report_service.ReportSeverity',
        on_delete=models.CASCADE,
        related_name='point_value'
    )
    points = models.IntegerField(default=10)

    class Meta:
        verbose_name = "Severity Point Value"
        verbose_name_plural = "Severity Point Values"

    def __str__(self):
        return f"{self.severity.name}: {self.points} pts"


class ScoreTransaction(models.Model):
    """
    Log of every point transaction for audit and history.
    """

    class TransactionType(models.TextChoices):
        REPORT_CREATED = "REPORT_CREATED", "Report Created"
        REPORT_VERIFIED = "REPORT_VERIFIED", "Report Verified"
        REPORT_CLEANED = "REPORT_CLEANED", "Report Cleaned"
        ENDORSEMENT_RECEIVED = "ENDORSEMENT_RECEIVED", "Endorsement Received"
        ENDORSEMENT_GIVEN = "ENDORSEMENT_GIVEN", "Endorsement Given"
        BONUS = "BONUS", "Bonus Points"
        PENALTY = "PENALTY", "Penalty"

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='score_transactions'
    )
    report = models.ForeignKey(
        'report_service.Report',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='score_transactions'
    )
    transaction_type = models.CharField(
        max_length=30,
        choices=TransactionType.choices
    )
    points = models.IntegerField()
    breakdown = models.JSONField(
        default=dict,
        blank=True,
        help_text="Detailed breakdown of how points were calculated"
    )
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Score Transaction"
        verbose_name_plural = "Score Transactions"

    def __str__(self):
        return f"{self.user.username}: {self.points:+d} pts ({self.get_transaction_type_display()})"


class UserScore(models.Model):
    """
    Aggregated scores for users with caching for performance.
    Updated whenever a new transaction is added.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='score'
    )
    total_points = models.IntegerField(default=0)
    weekly_points = models.IntegerField(default=0)
    monthly_points = models.IntegerField(default=0)
    yearly_points = models.IntegerField(default=0)

    total_reports = models.IntegerField(default=0)
    verified_reports = models.IntegerField(default=0)

    # Timestamps for cache invalidation
    last_calculated_at = models.DateTimeField(auto_now=True)
    weekly_reset_at = models.DateTimeField(null=True, blank=True)
    monthly_reset_at = models.DateTimeField(null=True, blank=True)
    yearly_reset_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-total_points']
        verbose_name = "User Score"
        verbose_name_plural = "User Scores"

    def __str__(self):
        return f"{self.user.username}: {self.total_points} pts"

    def recalculate_periodic_scores(self):
        """Recalculate weekly, monthly, and yearly scores from transactions."""
        now = timezone.now()

        # Weekly: last 7 days
        week_start = now - timedelta(days=7)
        self.weekly_points = ScoreTransaction.objects.filter(
            user=self.user,
            created_at__gte=week_start
        ).aggregate(total=Sum('points'))['total'] or 0

        # Monthly: last 30 days
        month_start = now - timedelta(days=30)
        self.monthly_points = ScoreTransaction.objects.filter(
            user=self.user,
            created_at__gte=month_start
        ).aggregate(total=Sum('points'))['total'] or 0

        # Yearly: last 365 days
        year_start = now - timedelta(days=365)
        self.yearly_points = ScoreTransaction.objects.filter(
            user=self.user,
            created_at__gte=year_start
        ).aggregate(total=Sum('points'))['total'] or 0

        self.save()

    def add_points(self, points: int):
        """Add points to user's score."""
        self.total_points += points
        self.weekly_points += points
        self.monthly_points += points
        self.yearly_points += points
        self.save()


class Endorsement(models.Model):
    """Users can endorse reports to give additional points to the author."""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='endorsements_given'
    )
    report = models.ForeignKey(
        'report_service.Report',
        on_delete=models.CASCADE,
        related_name='endorsements'
    )
    endorsed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'report')
        verbose_name = "Endorsement"
        verbose_name_plural = "Endorsements"

    def __str__(self):
        return f"{self.user.username} endorsed {self.report.title}"


class ScoreRule(models.Model):
    """Legacy/custom scoring rules for special actions."""
    action_type = models.CharField(max_length=100, unique=True)
    points = models.IntegerField()
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = "Score Rule"
        verbose_name_plural = "Score Rules"

    def __str__(self):
        return f"{self.action_type}: {self.points} pts"
