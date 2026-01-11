from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import Location


@admin.register(Location)
class LocationAdmin(ModelAdmin):
    list_display = ('id', 'latitude', 'longitude', 'street_name')
    list_filter = ('street_name',)
    search_fields = ('street_name', 'latitude', 'longitude')


