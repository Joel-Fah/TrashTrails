from django.urls import path
from .views import HomeView, AboutView

# Create your urls here.

app_name = "core"

urlpatterns = [
    path('', HomeView.as_view(), name='home'),
    path('about/', AboutView.as_view(), name='about'),
]