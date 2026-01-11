from django.urls import path
from .views import HomeView, AboutView, WhyNotView

# Create your urls here.

app_name = "core"

urlpatterns = [
    path('', HomeView.as_view(), name='home'),
    path('about/', AboutView.as_view(), name='about'),
    path('why-not/', WhyNotView.as_view(), name='why_not'),
]