from typing import Dict, Any

from django.contrib.auth.models import User
from django.db import transaction

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

        return {"points": int(points), "reason": str(reason)}

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

        return {"points": int(points), "reason": str(reason)}

    def calculate_category_points(self, report) -> Dict[str, Any]:
        """
        Calculate points based on trash category.
        Rarer categories get more points to incentivize diverse reporting.
        """
        category = report.category
        points = 0
        reason = ""
        rarity = "common"
        multiplier = 1.0

        # Check if there's a custom multiplier for this category
        try:
            multiplier_obj = CategoryPointMultiplier.objects.get(category=category)
            multiplier = float(multiplier_obj.multiplier)
            rarity = multiplier_obj.rarity_level.lower()

            if multiplier_obj.rarity_level == 'VERY_RARE':
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_RARE)
                points = int(base * multiplier * 1.5)
            elif multiplier_obj.rarity_level == 'RARE':
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_RARE)
                points = int(base * multiplier)
            elif multiplier_obj.rarity_level == 'UNCOMMON':
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_COMMON)
                points = int(base * multiplier)
            else:
                base = self.get_config(PointConfiguration.ConfigType.CATEGORY_COMMON)
                points = int(base * multiplier)

            reason = f"Category: {category.name} ({rarity}, x{multiplier})"

        except CategoryPointMultiplier.DoesNotExist:
            # Fallback to generic classification
            if category.code.upper() in GENERIC_CATEGORY_CODES:
                points = self.get_config(PointConfiguration.ConfigType.CATEGORY_GENERIC)
                reason = f"Category: {category.name} (generic)"
                rarity = "generic"
            else:
                points = self.get_config(PointConfiguration.ConfigType.CATEGORY_COMMON)
                reason = f"Category: {category.name} (common)"
                rarity = "common"

        return {
            "points": int(points),
            "reason": str(reason),
            "rarity": str(rarity),
            "multiplier": float(multiplier)
        }

    def calculate_observation_points(self, observation: str) -> Dict[str, Any]:
        """
        Calculate points for observation/description.
        More detailed observations get more points.
        """
        min_chars = self.get_config(PointConfiguration.ConfigType.OBSERVATION_MIN)
        per_char_points = self.get_config(PointConfiguration.ConfigType.OBSERVATION_PER_CHAR)
        default_points = self.get_config(PointConfiguration.ConfigType.OBSERVATION_DEFAULT)

        if not observation:
            return {
                "points": 0,
                "reason": "No observation provided",
                "character_count": 0
            }

        char_count = len(observation.strip())

        if char_count < min_chars:
            points = default_points
            reason = f"Brief observation ({char_count} chars)"
        else:
            # Points based on content amount (per 50 characters after minimum)
            extra_chars = char_count - min_chars
            extra_points = (extra_chars // 50) * per_char_points
            points = default_points + min(extra_points, 30)  # Cap at 30 extra points
            reason = f"Detailed observation ({char_count} chars)"

        return {
            "points": int(points),
            "reason": str(reason),
            "character_count": int(char_count)
        }

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

        return {"points": int(points), "reason": str(reason)}

    def calculate_image_points(self, image_count: int) -> Dict[str, Any]:
        """
        Calculate points for images.
        Ensures int values and takes into account a configured image ceiling.
        """
        try:
            image_count = int(image_count or 0)
        except Exception:
            image_count = 0

        if image_count == 0:
            return {
                "points": 0,
                "reason": "No images provided",
                "image_count": 0,
                "first_image_points": 0,
                "additional_image_points": 0
            }

        first_image_points = int(self.get_config(PointConfiguration.ConfigType.IMAGE_FIRST) or 0)
        additional_image_points = int(self.get_config(PointConfiguration.ConfigType.IMAGE_ADDITIONAL) or 0)
        max_images = int(self.get_config(PointConfiguration.ConfigType.IMAGE_MAX_COUNT) or 0)

        # If max_images <= 0, consider there's no ceiling
        if max_images <= 0:
            counted_images = image_count
        else:
            counted_images = min(image_count, max_images)

        # First image is worth more, following are worth less
        points = first_image_points
        additional_points = 0
        if counted_images > 1:
            additional_points = (counted_images - 1) * additional_image_points
            points += additional_points

        reason = f"{image_count} image(s) provided"
        if 0 < max_images < image_count:
            reason += f" (max {max_images} counted for points)"

        return {
            "points": int(points),
            "reason": str(reason),
            "image_count": int(image_count),
            "first_image_points": int(first_image_points),
            "additional_image_points": int(additional_points)
        }

    def calculate_report_points(self, report) -> Dict[str, Any]:
        """
        Calculate total and breakdown for a report.
        Uses resilient image counting to handle prefetch and transactional cases.
        """
        breakdown = {}
        total_points = 0

        # Title points
        title_result = self.calculate_title_points(report.title)
        breakdown['title'] = {
            "points": int(title_result.get("points", 0)),
            "reason": str(title_result.get("reason", ""))
        }
        total_points += int(title_result.get('points', 0))

        # Severity points
        severity_result = self.calculate_severity_points(report)
        breakdown['severity'] = {
            "points": int(severity_result.get("points", 0)),
            "reason": str(severity_result.get("reason", ""))
        }
        total_points += int(severity_result.get('points', 0))

        # Category points
        category_result = self.calculate_category_points(report)
        breakdown['category'] = {
            "points": int(category_result.get("points", 0)),
            "reason": str(category_result.get("reason", "")),
            "rarity": str(category_result.get("rarity", "common")),
            "multiplier": float(category_result.get("multiplier", 1.0))
        }
        total_points += int(category_result.get('points', 0))

        # Observation points
        observation_result = self.calculate_observation_points(report.observation or "")
        breakdown['observation'] = {
            "points": int(observation_result.get("points", 0)),
            "reason": str(observation_result.get("reason", "")),
            "character_count": int(observation_result.get("character_count", 0))
        }
        total_points += int(observation_result.get('points', 0))

        # Location points
        location_result = self.calculate_location_points(report)
        breakdown['location'] = {
            "points": int(location_result.get("points", 0)),
            "reason": str(location_result.get("reason", ""))
        }
        total_points += int(location_result.get('points', 0))

        # Image points - robust counting
        try:
            # Try prefetch cache first
            if hasattr(report, "_prefetched_objects_cache") and "images" in report._prefetched_objects_cache:
                image_count = len(report._prefetched_objects_cache["images"])
            else:
                # Use .all() to ensure we get all images, even those just saved
                image_count = report.images.all().count()
        except Exception:
            try:
                image_qs = report.images.all()
                image_count = len(list(image_qs))
            except Exception:
                image_count = 0

        image_result = self.calculate_image_points(image_count)
        breakdown['images'] = {
            "points": int(image_result.get("points", 0)),
            "reason": str(image_result.get("reason", "")),
            "image_count": int(image_result.get("image_count", 0)),
            "first_image_points": int(image_result.get("first_image_points", 0)),
            "additional_image_points": int(image_result.get("additional_image_points", 0))
        }
        total_points += int(image_result.get('points', 0))

        return {
            'total_points': int(total_points),
            'breakdown': breakdown
        }


class ScoreService:
    """
    Service for managing user scores and transactions.
    """

    def __init__(self):
        self.calculator = PointCalculator()

    @transaction.atomic
    def award_report_points(self, report_or_id) -> Dict[str, Any]:
        from report_service.models import Report
        from .models import ScoreTransaction

        try:
            report_id = report_or_id.pk if hasattr(report_or_id, "pk") else int(report_or_id)
        except Exception:
            return {
                "points_awarded": 0,
                "breakdown": {},
                "total_user_points": 0,
                "transaction_id": None,
                "error": "invalid_report_identifier",
            }

        try:
            report = Report.objects.select_related(
                "user", "severity", "category", "location"
            ).prefetch_related("images").get(pk=report_id)
        except Report.DoesNotExist:
            return {
                "points_awarded": 0,
                "breakdown": {},
                "total_user_points": 0,
                "transaction_id": None,
                "error": "report_not_found",
            }

        user = report.user

        # Calculate points
        result = self.calculator.calculate_report_points(report)
        new_total_points = int(result.get("total_points", 0))
        breakdown = result.get("breakdown", {})

        # Ensure breakdown values are properly serializable
        breakdown = {
            key: {
                "points": int(val.get("points", 0)),
                "reason": str(val.get("reason", "")),
                **{k: v for k, v in val.items() if k not in ["points", "reason"]}
            }
            for key, val in breakdown.items()
        }

        # Get existing REPORT_CREATED transaction
        existing_tx = ScoreTransaction.objects.filter(
            report=report,
            transaction_type=ScoreTransaction.TransactionType.REPORT_CREATED,
        ).order_by("created_at").first()

        user_score, _ = UserScore.objects.get_or_create(user=user)

        # CASE 1: First time awarding points (no REPORT_CREATED transaction exists)
        if existing_tx is None:
            score_transaction = ScoreTransaction.objects.create(
                user=user,
                report=report,
                transaction_type=ScoreTransaction.TransactionType.REPORT_CREATED,
                points=new_total_points,
                breakdown=breakdown,
                description=f"Points for report: {report.title}"
            )

            user_score.add_points(new_total_points)
            user_score.total_reports = (user_score.total_reports or 0) + 1
            user_score.save()

            return {
                "points_awarded": int(new_total_points),
                "breakdown": breakdown,
                "total_user_points": int(user_score.total_points),
                "transaction_id": int(score_transaction.id),
            }

        # CASE 2: Update - calculate delta from original REPORT_CREATED
        old_points = int(existing_tx.points or 0)
        delta = new_total_points - old_points

        # No change in points
        if delta == 0:
            return {
                "points_awarded": int(new_total_points),
                "breakdown": breakdown,
                "total_user_points": int(user_score.total_points),
                "transaction_id": int(existing_tx.id),
            }

        # CASE 3: Points changed - create adjustment transaction
        tx_type = ScoreTransaction.TransactionType.BONUS if delta > 0 else ScoreTransaction.TransactionType.PENALTY
        description = f"Adjustment for report '{report.title}': {old_points} -> {new_total_points}"
        adjustment_breakdown = {
            "before": int(old_points),
            "after": int(new_total_points),
            "delta": int(delta),
            "detail": breakdown,
        }

        adj_tx = ScoreTransaction.objects.create(
            user=user,
            report=report,
            transaction_type=tx_type,
            points=int(delta),
            breakdown=adjustment_breakdown,
            description=description
        )

        user_score.add_points(delta)
        user_score.save()

        return {
            "points_awarded": int(delta),
            "breakdown": breakdown,
            "total_user_points": int(user_score.total_points),
            "transaction_id": int(adj_tx.id),
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
            'total_points': int(score.total_points),
            'weekly_points': int(score.weekly_points),
            'monthly_points': int(score.monthly_points),
            'yearly_points': int(score.yearly_points),
            'total_reports': int(score.total_reports),
            'verified_reports': int(score.verified_reports),
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
                'points': int(getattr(score, point_field)),
                'total_reports': int(score.total_reports),
            })

        return leaderboard


def get_user_ranks(user):
    """
    Returns the ranks (overall, weekly, monthly, yearly) for the given user.
    """
    try:
        user_score = user.score
    except UserScore.DoesNotExist:
        return {
            'overall_rank': None,
            'weekly_rank': None,
            'monthly_rank': None,
            'yearly_rank': None,
            'total_users': UserScore.objects.count()
        }

    overall_rank = UserScore.objects.filter(total_points__gt=user_score.total_points).count() + 1
    weekly_rank = UserScore.objects.filter(weekly_points__gt=user_score.weekly_points).count() + 1
    monthly_rank = UserScore.objects.filter(monthly_points__gt=user_score.monthly_points).count() + 1
    yearly_rank = UserScore.objects.filter(yearly_points__gt=user_score.yearly_points).count() + 1

    return {
        'overall_rank': int(overall_rank),
        'weekly_rank': int(weekly_rank),
        'monthly_rank': int(monthly_rank),
        'yearly_rank': int(yearly_rank),
        'total_users': int(UserScore.objects.count())
    }


# Singleton instance for easy import
score_service = ScoreService()
