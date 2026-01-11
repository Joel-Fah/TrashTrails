from rest_framework.routers import DefaultRouter
from .views import ReportViewSet, TrashCategoryViewSet, ReportSeverityViewSet

app_name = "reports"

router = DefaultRouter()
# Register specific routes first, then the catch-all
router.register(r"trash-categories", TrashCategoryViewSet, basename="trash-category")
router.register(r"report-severities", ReportSeverityViewSet, basename="report-severity")
router.register(r"", ReportViewSet, basename="report")

urlpatterns = router.urls
