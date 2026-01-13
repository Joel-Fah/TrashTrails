from typing import Dict, Any
from django.db import transaction
from django.contrib.auth.models import User

from .models import (
    PointConfiguration,
    CategoryPointMultiplier,
    SeverityPointValue,
    ScoreTransaction,
    UserScore,
)


# Default point values (used if no configuration exists in DB)
DEFAULT_POINTS = {
    PointConfiguration.ConfigType.TITLE: 15,
    PointConfiguration.ConfigType.SEVERITY: 10,  # Base, multiplied by level
    PointConfiguration.ConfigType.CATEGORY_RARE: 25,
    PointConfiguration.ConfigType.CATEGORY_COMMON: 15,
    PointConfiguration.ConfigType.CATEGORY_GENERIC: 10,
    PointConfiguration.ConfigType.OBSERVATION_MIN: 100,  # Minimum chars
    PointConfiguration.ConfigType.OBSERVATION_PER_CHAR: 1,  # Points per 50 chars
    PointConfiguration.ConfigType.OBSERVATION_DEFAULT: 5,
    PointConfiguration.ConfigType.LOCATION: 20,
    PointConfiguration.ConfigType.IMAGE_FIRST: 15,
    PointConfiguration.ConfigType.IMAGE_ADDITIONAL: 10,
    PointConfiguration.ConfigType.IMAGE_MAX_COUNT: 5,  # Max images for points
}

# Generic category codes that get average points
GENERIC_CATEGORY_CODES = ['MIXED', 'OTHER', 'UNKNOWN', 'MISC']


class PointCalculator:
    """
    Service for calculating points for report submissions.
    Similar to Google Maps Local Guide point system.
    """

    def __init__(self):
        self._config_cache: Dict[str, int] = {}
        self._config_loaded = False

    def _load_config(self):
        """Load point configuration from database into cache."""
        if self._config_loaded:
            return
        try:
            configs = PointConfiguration.objects.filter(is_active=True)
            for config in configs:
                self._config_cache[config.config_type] = config.points
            self._config_loaded = True
        except Exception:
            # Table might not exist yet (during migrations)
            pass

    def get_config(self, config_type: str) -> int:
        """Get point value for a configuration type."""
        self._load_config()  # Lazy load
        if config_type in self._config_cache:
            return self._config_cache[config_type]
        return DEFAULT_POINTS.get(config_type, 0)

    def calculate_title_points(self, title: str) -> Dict[str, Any]:
        """
        Calculate points for having a proper title.
        A proper title is non-empty and not auto-generated.
        """
        points = 0
        reason = ""

        if title and not title.startswith("Untitled Report"):
            points = self.get_config(PointConfiguration.ConfigType.TITLE)
            reason = "Proper descriptive title provided"
        else:
            reason = "No proper title (auto-generated or empty)"

        return {"points": points, "reason": reason}

    def calculate_severity_points(self, report) -> Dict[str, Any]:
        """
        Calculate points based on severity level.
        Higher severity = more points (people need to report dangerous areas).
        """
        severity = report.severity
        points = 0
        reason = ""

        # Check if there's a custom point value for this severity
        try:
            severity_points = SeverityPointValue.objects.get(severity=severity)
            points = severity_points.points
            reason = f"Severity: {severity.name} (Level {severity.level})"
        except SeverityPointValue.DoesNotExist:
            # Calculate based on level: higher level = more points
            base_points = self.get_config(PointConfiguration.ConfigType.SEVERITY)
            points = base_points * severity.level
            reason = f"Severity: {severity.name} (Level {severity.level}) - {base_points} x {severity.level}"

        return {"points": points, "reason": reason}

    def calculate_category_points(self, report) -> Dict[str, Any]:
        """
        Calculate points based on trash category.
        Rarer categories get more points to incentivize diverse reporting.
        """
        category = report.category
        points = 0
        reason = ""

        # Check if there's a custom multiplier for this category
        try:
            multiplier = CategoryPointMultiplier.objects.get(category=category)

            if multiplier.rarity_level == 'VERY_RARE':
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_RARE)
                points = int(base * float(multiplier.multiplier) * 1.5)
            elif multiplier.rarity_level == 'RARE':
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_RARE)
                points = int(base * float(multiplier.multiplier))
            elif multiplier.rarity_level == 'UNCOMMON':
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_COMMON)
                points = int(base * float(multiplier.multiplier))
            else:
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_COMMON)
                points = int(base * float(multiplier.multiplier))

            reason = f"Category: {category.name} ({multiplier.rarity_level.lower()}, x{multiplier.multiplier})"

        except CategoryPointMultiplier.DoesNotExist:
            # Fallback to generic classification
            if category.code.upper() in GENERIC_CATEGORY_CODES:
                points = self.get_config(PointConfiguration.ConfigType.CATEGORY_GENERIC)
                reason = f"Category: {category.name} (generic)"
            else:
                points = self.get_config(PointConfiguration.ConfigType.CATEGORY_COMMON)
                reason = f"Category: {category.name} (standard)"

        return {"points": points, "reason": reason}

    def calculate_observation_points(self, observation: str) -> Dict[str, Any]:
        """
        Calculate points for observation/description.
        More detailed observations get more points.
        """
        min_chars = self.get_config(PointConfiguration.ConfigType.OBSERVATION_MIN)
        per_char_points = self.get_config(PointConfiguration.ConfigType.OBSERVATION_PER_CHAR)
        default_points = self.get_config(PointConfiguration.ConfigType.OBSERVATION_DEFAULT)

        if not observation:
            return {"points": 0, "reason": "No observation provided"}

        char_count = len(observation.strip())

        if char_count < min_chars:
            points = default_points
            reason = f"Brief observation ({char_count} chars < {min_chars} minimum)"
        else:
            # Points based on content amount (per 50 characters after minimum)
            extra_chars = char_count - min_chars
            extra_points = (extra_chars // 50) * per_char_points
            points = default_points + min(extra_points, 30)  # Cap at 30 extra points
            reason = f"Detailed observation ({char_count} chars)"

        return {"points": points, "reason": reason}

    def calculate_location_points(self, report) -> Dict[str, Any]:
        """
        Calculate points for providing location data.
        """
        if report.location:
            points = self.get_config(PointConfiguration.ConfigType.LOCATION)
            location_info = getattr(report.location, 'street_name', '') or 'coordinates provided'
            reason = f"Location: {location_info}"
        else:
            points = 0
            reason = "No location provided"

        return {"points": points, "reason": reason}

    def calculate_image_points(self, image_count: int) -> Dict[str, Any]:
        """
        Calculate points for images.
        First image worth more, additional images worth less.
        """
        if image_count == 0:
            return {"points": 0, "reason": "No images provided"}

        first_image_points = self.get_config(PointConfiguration.ConfigType.IMAGE_FIRST)
        additional_image_points = self.get_config(PointConfiguration.ConfigType.IMAGE_ADDITIONAL)
        max_images = self.get_config(PointConfiguration.ConfigType.IMAGE_MAX_COUNT)

        # Limit images that count for points
        counted_images = min(image_count, max_images)

        # First image
        points = first_image_points

        # Additional images
        if counted_images > 1:
            points += (counted_images - 1) * additional_image_points

        reason = f"{image_count} image(s) provided"
        if image_count > max_images:
            reason += f" (max {max_images} counted for points)"

        return {"points": points, "reason": reason}

    def calculate_report_points(self, report) -> Dict[str, Any]:
        """
        Calculate total points for a report submission.
        Returns detailed breakdown of points.
        """
        breakdown = {}
        total_points = 0

        # Title points
        title_result = self.calculate_title_points(report.title)
        breakdown['title'] = title_result
        total_points += title_result['points']

        # Severity points
        severity_result = self.calculate_severity_points(report)
        breakdown['severity'] = severity_result
        total_points += severity_result['points']

        # Category points
        category_result = self.calculate_category_points(report)
        breakdown['category'] = category_result
        total_points += category_result['points']

        # Observation points
        observation_result = self.calculate_observation_points(report.observation)
        breakdown['observation'] = observation_result
        total_points += observation_result['points']

        # Location points
        location_result = self.calculate_location_points(report)
        breakdown['location'] = location_result
        total_points += location_result['points']

        # Image points
        image_count = report.images.count()
        image_result = self.calculate_image_points(image_count)
        breakdown['images'] = image_result
        total_points += image_result['points']

        return {
            'total_points': total_points,
            'breakdown': breakdown
        }


class ScoreService:
    """
    Service for managing user scores and transactions.
    """

    def __init__(self):
        self.calculator = PointCalculator()

    @transaction.atomic
    def award_report_points(self, report) -> Dict[str, Any]:
        """
        Award points to a user for creating a report.
        Creates a transaction record and updates user score.

        This function is idempotent: if a REPORT_CREATED transaction already exists,
        it will compute the new expected points and only award the delta (as BONUS or PENALTY).
        """
        user = report.user

        # Calculate points
        result = self.calculator.calculate_report_points(report)
        new_total_points = result['total_points']
        breakdown = result['breakdown']

        # Check for existing creation transaction
        from .models import ScoreTransaction

        existing_tx = ScoreTransaction.objects.filter(
            report=report,
            transaction_type=ScoreTransaction.TransactionType.REPORT_CREATED,
        ).order_by('created_at').first()

        user_score, _ = UserScore.objects.get_or_create(user=user)

        if existing_tx is None:
            # First-time award
            score_transaction = ScoreTransaction.objects.create(
                user=user,
                report=report,
                transaction_type=ScoreTransaction.TransactionType.REPORT_CREATED,
                points=new_total_points,
                breakdown=breakdown,
                description=f"Points for report: {report.title}"
            )

            # Update user score
            user_score.add_points(new_total_points)
            user_score.total_reports += 1
            user_score.save()

            return {
                'points_awarded': new_total_points,
                'breakdown': breakdown,
                'total_user_points': user_score.total_points,
                'transaction_id': score_transaction.id
            }

        # If an existing creation transaction exists, compute delta and award only adjustment
        old_points = existing_tx.points or 0
        delta = new_total_points - old_points

        if delta == 0:
            return {
                'points_awarded': 0,
                'breakdown': breakdown,
                'total_user_points': user_score.total_points,
                'transaction_id': existing_tx.id
            }

        # Decide transaction type for adjustment
        tx_type = ScoreTransaction.TransactionType.BONUS if delta > 0 else ScoreTransaction.TransactionType.PENALTY
        description = f"Adjustment for report '{report.title}': {old_points} -> {new_total_points}"
        adjustment_breakdown = {
            'before': old_points,
            'after': new_total_points,
            'detail': breakdown,
        }

        adj_tx = ScoreTransaction.objects.create(
            user=user,
            report=report,
            transaction_type=tx_type,
            points=delta,
            breakdown=adjustment_breakdown,
            description=description
        )

        # Apply delta to user score
        user_score.add_points(delta)
        user_score.save()

        return {
            'points_awarded': delta,
            'breakdown': adjustment_breakdown,
            'total_user_points': user_score.total_points,
            'transaction_id': adj_tx.id
        }

    @transaction.atomic
    def award_endorsement_points(self, endorsement) -> Dict[str, Any]:
        """
        Award points when a report receives an endorsement.
        The report author gets points.
        """
        report = endorsement.report
        author = report.user

        # Endorsement points (could be configurable)
        endorsement_points = 5

        # Create transaction for author
        ScoreTransaction.objects.create(
            user=author,
            report=report,
            transaction_type=ScoreTransaction.TransactionType.ENDORSEMENT_RECEIVED,
            points=endorsement_points,
            breakdown={'endorser': endorsement.user.username},
            description=f"Endorsement from {endorsement.user.username}"
        )

        # Update author score
        user_score, _ = UserScore.objects.get_or_create(user=author)
        user_score.add_points(endorsement_points)

        return {
            'points_awarded': endorsement_points,
            'to_user': author.username
        }

    @transaction.atomic
    def award_verification_bonus(self, report) -> Dict[str, Any]:
        """
        Award bonus points when a report is verified.
        """
        verification_bonus = 25

        ScoreTransaction.objects.create(
            user=report.user,
            report=report,
            transaction_type=ScoreTransaction.TransactionType.REPORT_VERIFIED,
            points=verification_bonus,
            breakdown={},
            description=f"Report verified: {report.title}"
        )

        user_score, _ = UserScore.objects.get_or_create(user=report.user)
        user_score.add_points(verification_bonus)
        user_score.verified_reports += 1
        user_score.save()

        return {
            'points_awarded': verification_bonus,
            'total_user_points': user_score.total_points
        }

    def get_user_stats(self, user: User) -> Dict[str, Any]:
        """Get user's point statistics."""
        try:
            score = user.score
        except UserScore.DoesNotExist:
            score = UserScore.objects.create(user=user)

        # Recalculate periodic scores if needed
        score.recalculate_periodic_scores()

        return {
            'total_points': score.total_points,
            'weekly_points': score.weekly_points,
            'monthly_points': score.monthly_points,
            'yearly_points': score.yearly_points,
            'total_reports': score.total_reports,
            'verified_reports': score.verified_reports,
        }

    def get_leaderboard(
        self,
        period: str = 'all',
        limit: int = 10
    ) -> list:
        """
        Get leaderboard for a specific period.
        period: 'weekly', 'monthly', 'yearly', 'all'
        """
        order_field = {
            'weekly': '-weekly_points',
            'monthly': '-monthly_points',
            'yearly': '-yearly_points',
            'all': '-total_points'
        }.get(period, '-total_points')

        point_field = {
            'weekly': 'weekly_points',
            'monthly': 'monthly_points',
            'yearly': 'yearly_points',
            'all': 'total_points'
        }.get(period, 'total_points')

        scores = UserScore.objects.select_related('user', 'user__userprofile').order_by(order_field)[:limit]

        leaderboard = []
        for rank, score in enumerate(scores, 1):
            avatar = None
            try:
                avatar = score.user.userprofile.avatar
            except Exception:
                pass

            leaderboard.append({
                'rank': rank,
                'user_id': score.user.id,
                'username': score.user.username,
                'full_name': score.user.get_full_name() or score.user.username,
                'avatar': avatar,
                'points': getattr(score, point_field),
                'total_reports': score.total_reports,
            })

        return leaderboard


# Singleton instance for easy import
score_service = ScoreService()

