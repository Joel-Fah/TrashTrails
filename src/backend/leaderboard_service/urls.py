from django.urls import path

from .views import (
    LeaderboardView,
    UserStatsView,
    UserTransactionsView,
    UserRankView,
)

app_name = 'leaderboard'

urlpatterns = [
    path('', LeaderboardView.as_view(), name='users-leaderboard'),
    path('me/stats/', UserStatsView.as_view(), name='user-stats'),
    path('me/transactions/', UserTransactionsView.as_view(), name='user-transactions'),
    path('me/rank/', UserRankView.as_view(), name='user-rank'),
]