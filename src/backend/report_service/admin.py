from django.contrib import admin
from django.db import models
from unfold.admin import ModelAdmin, TabularInline
from .models import Report, ReportImage, TrashCategory, ReportSeverity
from unfold.contrib.forms.widgets import WysiwygWidget


class ReportImageInline(TabularInline):
    model = ReportImage
    extra = 1


@admin.register(Report)
class ReportAdmin(ModelAdmin):
    list_display = ('title', 'user', 'get_street_name', 'category', 'severity', 'status', 'created_at')
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

