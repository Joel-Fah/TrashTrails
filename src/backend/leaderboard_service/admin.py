# python
import hashlib

from django.contrib import admin
from unfold.admin import ModelAdmin
from django.utils.html import format_html

from .models import (
    PointConfiguration,
    CategoryPointMultiplier,
    SeverityPointValue,
    ScoreTransaction,
    UserScore,
    Endorsement,
    ScoreRule,
)


@admin.register(PointConfiguration)
class PointConfigurationAdmin(ModelAdmin):
    list_display = ('config_type', 'config_type_display', 'points', 'is_active', 'updated_at')
    list_filter = ('is_active', 'config_type')
    search_fields = ('config_type', 'description')
    list_editable = ('points', 'is_active')
    ordering = ('config_type',)

    @admin.display(description='Type')
    def config_type_display(self, obj):
        return obj.get_config_type_display()


@admin.register(CategoryPointMultiplier)
class CategoryPointMultiplierAdmin(ModelAdmin):
    list_display = ('category', 'multiplier', 'rarity_level')
    list_filter = ('rarity_level',)
    search_fields = ('category__name', 'category__code')
    list_editable = ('multiplier', 'rarity_level')


@admin.register(SeverityPointValue)
class SeverityPointValueAdmin(ModelAdmin):
    list_display = ('severity', 'points')
    list_editable = ('points',)


@admin.register(ScoreTransaction)
class ScoreTransactionAdmin(ModelAdmin):
    list_display = ('user', 'transaction_type_display', 'points_display', 'report', 'created_at')
    list_filter = ('transaction_type', 'created_at')
    search_fields = ('user__username', 'report__title', 'description')
    date_hierarchy = 'created_at'
    readonly_fields = ('user', 'report', 'transaction_type', 'points', 'breakdown', 'description', 'created_at')
    ordering = ('-created_at',)

    @admin.display(description='Type')
    def transaction_type_display(self, obj):
        return obj.get_transaction_type_display()

    @admin.display(description='Points')
    def points_display(self, obj):
        if obj.points >= 0:
            return format_html(
                '<span style="color: #16a34a; font-weight: bold;">+{}</span>',
                obj.points
            )
        return format_html(
            '<span style="color: #dc2626; font-weight: bold;">{}</span>',
            obj.points
        )


@admin.register(UserScore)
class UserScoreAdmin(ModelAdmin):
    list_display = (
        'user_display',
        'rank_display',
        'total_points',
        'weekly_points',
        'monthly_points',
        'yearly_points',
        'total_reports',
        'verified_reports',
    )
    search_fields = ('user__username', 'user__email')
    ordering = ('-total_points',)
    readonly_fields = ('last_calculated_at',)

    fieldsets = (
        ('User', {
            'fields': ('user',)
        }),
        ('Points', {
            'fields': ('total_points', 'weekly_points', 'monthly_points', 'yearly_points'),
        }),
        ('Statistics', {
            'fields': ('total_reports', 'verified_reports'),
        }),
        ('Timestamps', {
            'fields': ('last_calculated_at', 'weekly_reset_at', 'monthly_reset_at', 'yearly_reset_at'),
            'classes': ('collapse',),
        }),
    )

    @admin.display(description='User')
    def user_display(self, obj):
        user = getattr(obj, 'user', None)
        avatar_url = None
        if user is not None:
            profile = getattr(user, 'userprofile', None)
            avatar_field = getattr(profile, 'avatar', None)
            if avatar_field:
                if hasattr(avatar_field, 'url'):
                    try:
                        avatar_url = avatar_field.url
                    except Exception:
                        avatar_url = None
                else:
                    if isinstance(avatar_field, str) and avatar_field.strip():
                        avatar_url = avatar_field.strip()

        if avatar_url:
            avatar_html = format_html(
                '<img src="{}" style="width:32px;height:32px;border-radius:50%;object-fit:cover;margin-right:8px;vertical-align:middle;">',
                avatar_url
            )
        else:
            if user and (user.first_name or user.last_name):
                initials = (user.first_name[:1] + user.last_name[:1]).upper()
            elif user and getattr(user, 'username', None):
                initials = user.username[:2].upper()
            else:
                initials = str(getattr(obj, 'pk', ''))[:2].upper() or '-'
            seed = (user.username if user and getattr(user, 'username', None) else str(getattr(obj, 'pk', ''))) or str(
                obj)
            color = '#' + hashlib.md5(seed.encode('utf-8')).hexdigest()[:6]
            avatar_html = format_html(
                '<span style="display:inline-flex;width:32px;height:32px;border-radius:50%;align-items:center;justify-content:center;margin-right:8px;vertical-align:middle;background-color:{};color:#fff;font-weight:600;">{}</span>',
                color, initials
            )

        if user and user.is_superuser:
            role_html = format_html('<span style="color: #dc2626; font-weight: bold;">&lt;superadmin&gt;</span>')
        elif user and user.is_staff:
            role_html = format_html('<span style="color: #2563eb; font-weight: bold;">&lt;admin&gt;</span>')
        else:
            role_html = ''

        username = getattr(user, 'username', '') if user else ''
        return format_html(
            '<span style="display:inline-flex;align-items:center;white-space:nowrap;">{}<span style="vertical-align:middle;font-weight:500;margin-right:6px;">{}</span>{}</span>',
            avatar_html, username, role_html
        )

    @admin.display(description='Rank', ordering='total_points')
    def rank_display(self, obj):
        try:
            rank = UserScore.objects.filter(total_points__gt=obj.total_points).count() + 1
        except Exception:
            rank = None

        if rank is None:
            return format_html('<span style="color: #6b7280;">-</span>')

        # couleurs: 1 = gold, 2 = silver, 3 = bronze, sinon gris foncé
        if rank == 1:
            color = '#EFBF04'  # gold
        elif rank == 2:
            color = '#A8A9AD'  # silver
        elif rank == 3:
            color = '#CD7F32'  # bronze
        else:
            color = '#374151'  # slate-700

        return format_html('<span style="color: {}; font-weight: bold;">#{}</span>', color, rank)


@admin.register(Endorsement)
class EndorsementAdmin(ModelAdmin):
    list_display = ('user', 'report', 'endorsed_at')
    list_filter = ('endorsed_at',)
    search_fields = ('user__username', 'report__title')
    date_hierarchy = 'endorsed_at'


@admin.register(ScoreRule)
class ScoreRuleAdmin(ModelAdmin):
    list_display = ('action_type', 'points', 'is_active')
    list_filter = ('is_active',)
    search_fields = ('action_type', 'description')
    list_editable = ('points', 'is_active')
