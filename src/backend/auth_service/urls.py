from django.urls import path
from rest_framework_simplejwt.views import (
    TokenRefreshView,
)
from .views import GoogleAuthView, LogoutView, UserPublicView

app_name = 'auth'

urlpatterns = [
    path("google/", GoogleAuthView.as_view(), name="google-auth"),
    path("refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("users/<int:pk>/", UserPublicView.as_view(), name="user-public"),
]
