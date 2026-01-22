from django.urls import path
from .views import HomeView, AboutView, ExploreView, LeaderboardView

# Create your urls here.

app_name = "core"

urlpatterns = [
    path('', HomeView.as_view(), name='home'),
    path('about/', AboutView.as_view(), name='about'),
    path('explore/', ExploreView.as_view(), name='explore'),
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),
]