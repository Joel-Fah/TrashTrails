from rest_framework import serializers

from .models import (
    PointConfiguration,
    UserScore,
    ScoreTransaction,
)


class PointConfigurationSerializer(serializers.ModelSerializer):
    config_type_display = serializers.CharField(
        source='get_config_type_display',
        read_only=True
    )

    class Meta:
        model = PointConfiguration
        fields = ['id', 'config_type', 'config_type_display', 'points', 'description', 'is_active']


class UserScoreSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    full_name = serializers.SerializerMethodField()
    avatar = serializers.SerializerMethodField()

    class Meta:
        model = UserScore
        fields = [
            'user_id',
            'username',
            'full_name',
            'avatar',
                'total_points',
            'weekly_points',
            'monthly_points',
            'yearly_points',
            'total_reports',
            'verified_reports',
            'last_calculated_at',
        ]
        read_only_fields = fields

    def get_full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username

    def get_avatar(self, obj):
        try:
            return obj.user.userprofile.avatar
        except Exception:
            return None


class ScoreTransactionSerializer(serializers.ModelSerializer):
    transaction_type_display = serializers.CharField(
        source='get_transaction_type_display',
        read_only=True
    )
    report_title = serializers.CharField(source='report.title', read_only=True, allow_null=True)

    class Meta:
        model = ScoreTransaction
        fields = [
            'id',
            'transaction_type',
            'transaction_type_display',
            'points',
            'breakdown',
            'description',
            'report_title',
            'created_at',
        ]
        read_only_fields = fields


class LeaderboardEntrySerializer(serializers.Serializer):
    """Serializer for leaderboard entries."""
    rank = serializers.IntegerField()
    user_id = serializers.IntegerField()
    username = serializers.CharField()
    full_name = serializers.CharField()
    avatar = serializers.URLField(allow_null=True)
    points = serializers.IntegerField()
    total_reports = serializers.IntegerField()


class PointBreakdownSerializer(serializers.Serializer):
    """Serializer for point breakdown returned after report creation."""
    points = serializers.IntegerField()
    reason = serializers.CharField()


class ReportPointsResultSerializer(serializers.Serializer):
    """Serializer for the result of point calculation."""
    points_awarded = serializers.IntegerField()
    breakdown = serializers.DictField(child=PointBreakdownSerializer())
    total_user_points = serializers.IntegerField()
    transaction_id = serializers.IntegerField()


class UserStatsSerializer(serializers.Serializer):
    """Serializer for user statistics."""
    total_points = serializers.IntegerField()
    weekly_points = serializers.IntegerField()
    monthly_points = serializers.IntegerField()
    yearly_points = serializers.IntegerField()
    total_reports = serializers.IntegerField()
    verified_reports = serializers.IntegerField()

