from django.contrib import admin
from django.db import models
from django.utils.html import format_html
from unfold.admin import ModelAdmin, TabularInline
from .models import Report, ReportImage, TrashCategory, ReportSeverity
from unfold.contrib.forms.widgets import WysiwygWidget


class ReportImageInline(TabularInline):
    model = ReportImage
    extra = 1


@admin.register(Report)
class ReportAdmin(ModelAdmin):
    list_display = ('title', 'user', 'get_street_name', 'category', 'severity_display', 'status', 'created_at')
    list_filter = ('status', 'category', 'severity', 'created_at')
    search_fields = ('title', 'user__username', 'location__street_name')
    readonly_fields = ('created_at', 'slug')
    inlines = [ReportImageInline]

    formfield_overrides = {
        models.TextField: {'widget': WysiwygWidget},
    }

    @admin.display(description='Street Name')
    def get_street_name(self, obj):
        if obj.location and obj.location.street_name:
            return obj.location.street_name
        return '-'

    @admin.display(description='Severity')
    def severity_display(self, obj):
        try:
            sev = obj.severity
            # Récupère le niveau si c'est un objet ReportSeverity, sinon tente de convertir en int
            level = getattr(sev, 'level', None)
            if level is None:
                try:
                    level = int(sev)
                except Exception:
                    level = None
            # Libellé à afficher : privilégie `name` si présent, sinon str()
            label = getattr(sev, 'name', str(sev))
        except Exception:
            return '-'

        color_map = {
            1: '#16a34a',  # low / green
            2: '#f59e0b',  # medium / amber
            3: '#ff4500',  # high / orange red
            4: '#dc2626',  # critical / purple
        }
        color = color_map.get(level, '#6b7280')  # default gray

        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            label
        )

    def save_related(self, request, form, formsets, change):
        """
        Called after the main object and its inlines have been saved.
        We call the score service here to ensure images added via inlines
        are included in the initial scoring when creating from the admin.
        """
        super().save_related(request, form, formsets, change)

        # Attempt to award/adjust points now that related objects (images) are saved.
        try:
            # Import lazily to avoid import-time DB access issues
            from leaderboard_service.services import score_service
        except Exception:
            # If leaderboard service isn't available for any reason, don't break admin save
            return

        try:
            obj = form.instance
            score_service.award_report_points(obj)
        except Exception:
            # Avoid raising from admin UI; log would be better but keep silent here
            return


@admin.register(ReportImage)
class ReportImageAdmin(ModelAdmin):
    list_display = ('report', 'image', 'uploaded_at')
    list_filter = ('uploaded_at',)
    readonly_fields = ('uploaded_at',)


@admin.register(TrashCategory)
class TrashCategoryAdmin(ModelAdmin):
    list_display = ('code', 'name', 'description')
    search_fields = ('code', 'name')


@admin.register(ReportSeverity)
class ReportSeverityAdmin(ModelAdmin):
    list_display = ('level', 'name', 'description')
    list_filter = ('level',)
    ordering = ('level',)
