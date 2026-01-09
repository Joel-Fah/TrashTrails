from django.urls import path
from .views import GoogleLoginView, UserProfileUpdateView, LogoutView

app_name = 'auth'

urlpatterns = [
    path('login/', GoogleLoginView.as_view(), name='login'),
    path('profile/', UserProfileUpdateView.as_view(), name='profile-update'),
path('logout/', LogoutView.as_view(), name='logout'),
]
