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
        'user',
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
