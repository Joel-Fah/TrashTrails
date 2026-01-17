from django.contrib import admin
from django.db import models, transaction
from django.db.models import Sum, Value
from django.db.models.functions import Coalesce
from django.utils.html import format_html
from unfold.admin import ModelAdmin, TabularInline

from leaderboard_service.models import ScoreTransaction
from .models import Report, ReportImage, TrashCategory, ReportSeverity
from unfold.contrib.forms.widgets import WysiwygWidget


class ReportImageInline(TabularInline):
    model = ReportImage
    extra = 1


@admin.register(Report)
class ReportAdmin(ModelAdmin):
    list_display = ('title', 'user', 'get_street_name', 'category', 'severity_display', 'status_display', 'created_at',
                    'points_display', 'row_actions')
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

    @admin.display(description='Status')
    def status_display(self, obj):
        status_colors = {
            Report.ReportStatus.PENDING: '#fbbf24',  # amber
            Report.ReportStatus.VERIFIED: '#16a34a',  # green
            Report.ReportStatus.REJECTED: '#dc2626',  # red
            Report.ReportStatus.CLEANED: '#3b82f6',  # blue
        }
        color = status_colors.get(obj.status, '#6b7280')  # default gray

        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display()
        )

    @admin.display(description='Points')
    def points_display(self, obj):
        """
        Retourne le total net des points liés au rapport (somme des ScoreTransaction.points).
        Utilise une agrégation par requête pour éviter les erreurs None.
        """
        agg = ScoreTransaction.objects.filter(report=obj).aggregate(total=Coalesce(Sum('points'), Value(0)))
        try:
            return int(agg.get('total') or 0)
        except Exception:
            return 0

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
        Après sauvegarde des inlines, lancer le scoring uniquement lors de la création depuis l'admin
        (évite double scoring si l'API/ frontend a déjà calculé les points).
        """
        super().save_related(request, form, formsets, change)

        # n'appeler le service de score que si on crée depuis l'admin (change == False)
        if change:
            return

        try:
            from leaderboard_service.services import score_service
        except Exception:
            return

        obj = form.instance

        def _run_scoring():
            try:
                score_service.award_report_points(obj.pk)
            except Exception:
                return

        transaction.on_commit(_run_scoring)

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('<int:report_id>/verify/', self.admin_site.admin_view(self.verify_view), name='report_verify'),
            path('<int:report_id>/reject/', self.admin_site.admin_view(self.reject_view), name='report_reject'),
        ]
        return custom_urls + urls

    def verify_view(self, request, report_id, *args, **kwargs):
        from django.shortcuts import get_object_or_404, redirect
        from django.urls import reverse
        from django.contrib import messages

        obj = get_object_or_404(Report, pk=report_id)

        if not self.has_change_permission(request, obj):
            messages.error(request, 'Permission denied.')
            return redirect(reverse('admin:report_service_report_changelist'))

        if obj.status != Report.ReportStatus.PENDING:
            messages.warning(request, 'Action disponible uniquement pour les rapports en attente.')
            return redirect(request.META.get('HTTP_REFERER', reverse('admin:report_service_report_changelist')))

        obj.status = Report.ReportStatus.VERIFIED
        obj.save(update_fields=['status'])
        messages.success(request, 'report verified.')
        return redirect(request.META.get('HTTP_REFERER', reverse('admin:report_service_report_changelist')))

    def reject_view(self, request, report_id, *args, **kwargs):
        from django.shortcuts import get_object_or_404, redirect
        from django.urls import reverse
        from django.contrib import messages

        obj = get_object_or_404(Report, pk=report_id)

        if not self.has_change_permission(request, obj):
            messages.error(request, 'Permission denied.')
            return redirect(reverse('admin:report_service_report_changelist'))

        if obj.status != Report.ReportStatus.PENDING:
            messages.warning(request, 'Action available only for pending reports.')
            return redirect(request.META.get('HTTP_REFERER', reverse('admin:report_service_report_changelist')))

        obj.status = Report.ReportStatus.REJECTED
        obj.save(update_fields=['status'])
        messages.success(request, 'Report rejected.')
        return redirect(request.META.get('HTTP_REFERER', reverse('admin:report_service_report_changelist')))

    @admin.display(description='Actions')
    def row_actions(self, obj):
        from django.urls import reverse
        from django.utils.html import format_html

        if obj.status != Report.ReportStatus.PENDING:
            return '-'

        base = reverse('admin:report_service_report_changelist')
        verify_url = f"{base}{obj.pk}/verify/"
        reject_url = f"{base}{obj.pk}/reject/"

        return format_html(
            '<a class="button" href="{}" style="margin-right:6px;background:#10b981;border-radius:10px;padding:6px 10px;color:white;text-decoration:none;">Accept</a>'
            '<a class="button" href="{}" style="background:#ef4444;border-radius:10px;padding:6px 10px;color:white;text-decoration:none;">Reject</a>',
            verify_url, reject_url
        )


@admin.register(ReportImage)
class ReportImageAdmin(ModelAdmin):
    list_display = ('report', 'get_report_user', 'uploaded_at')
    list_filter = ('uploaded_at', 'report__user')
    readonly_fields = ('uploaded_at',)

    @admin.display(description='Uploaded by')
    def get_report_user(self, obj):
        return obj.report.user.username


@admin.register(TrashCategory)
class TrashCategoryAdmin(ModelAdmin):
    list_display = ('code', 'name', 'description')
    search_fields = ('code', 'name')


@admin.register(ReportSeverity)
class ReportSeverityAdmin(ModelAdmin):
    list_display = ('level', 'name', 'description')
    list_filter = ('level',)
    ordering = ('level',)
