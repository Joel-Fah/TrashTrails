from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from .services import score_service
from .serializers import (
    LeaderboardEntrySerializer,
    UserStatsSerializer,
    ScoreTransactionSerializer,
)
from .models import ScoreTransaction


class LeaderboardView(APIView):
    """
    Get the leaderboard for different time periods.
    """
    permission_classes = [AllowAny]

    @swagger_auto_schema(
        operation_description="Get leaderboard for a specific period",
        manual_parameters=[
            openapi.Parameter(
                'period',
                openapi.IN_QUERY,
                description="Time period for leaderboard: weekly, monthly, yearly, or all (default: all)",
                type=openapi.TYPE_STRING,
                enum=['weekly', 'monthly', 'yearly', 'all'],
                default='all'
            ),
            openapi.Parameter(
                'limit',
                openapi.IN_QUERY,
                description="Number of entries to return (default: 10, max: 100)",
                type=openapi.TYPE_INTEGER,
                default=10
            ),
        ],
        responses={200: LeaderboardEntrySerializer(many=True)}
    )
    def get(self, request):
        period = request.query_params.get('period', 'all')
        limit = min(int(request.query_params.get('limit', 10)), 100)

        if period not in ['weekly', 'monthly', 'yearly', 'all']:
            period = 'all'

        leaderboard = score_service.get_leaderboard(period=period, limit=limit)

        return Response({
            'period': period,
            'count': len(leaderboard),
            'leaderboard': leaderboard
        })


class UserStatsView(APIView):
    """
    Get the authenticated user's point statistics.
    """
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_description="Get current user's point statistics",
        responses={200: UserStatsSerializer()}
    )
    def get(self, request):
        stats = score_service.get_user_stats(request.user)
        return Response(stats)


class UserTransactionsView(APIView):
    """
    Get the authenticated user's point transactions history.
    """
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_description="Get current user's point transaction history",
        manual_parameters=[
            openapi.Parameter(
                'limit',
                openapi.IN_QUERY,
                description="Number of transactions to return (default: 20)",
                type=openapi.TYPE_INTEGER,
                default=20
            ),
        ],
        responses={200: ScoreTransactionSerializer(many=True)}
    )
    def get(self, request):
        limit = min(int(request.query_params.get('limit', 20)), 100)

        transactions = ScoreTransaction.objects.filter(
            user=request.user
        ).select_related('report')[:limit]

        serializer = ScoreTransactionSerializer(transactions, many=True)

        return Response({
            'count': len(serializer.data),
            'transactions': serializer.data
        })


class UserRankView(APIView):
    """
    Get the authenticated user's rank on the leaderboard.
    """
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_description="Get current user's rank on different leaderboards",
        responses={
            200: openapi.Response(
                description="User ranks",
                examples={
                    "application/json": {
                        "overall_rank": 5,
                        "weekly_rank": 3,
                        "monthly_rank": 7,
                        "yearly_rank": 4
                    }
                }
            )
        }
    )
    def get(self, request):
        ranks = get_user_ranks(request.user)
        return Response(ranks)
