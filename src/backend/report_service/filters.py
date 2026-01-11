import django_filters
from .models import Report

class ReportFilter(django_filters.FilterSet):
    status = django_filters.CharFilter(field_name="status")
    user = django_filters.CharFilter(method="filter_user")

    class Meta:
        model = Report
        fields = ["status"]

    def filter_user(self, queryset, name, value):
        request = self.request
        if value == "me":
            return queryset.filter(user=request.user)
        return queryset.filter(user__id=value)
