import json
import os

from django.shortcuts import render
from django.templatetags.static import static
from django.views.generic import TemplateView
from django.http import JsonResponse

from leaderboard_service.models import UserScore
from report_service.models import Report


# Create your views here.
class HomeView(TemplateView):
    template_name = "core/home.html"


class AboutView(TemplateView):
    template_name = "core/about.html"


class ExploreView(TemplateView):
    template_name = "core/explore.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['mapbox_access_token'] = os.getenv('MAPBOX_ACCESS_TOKEN')

        # Optimized query with select_related and prefetch_related
        reports = Report.objects.select_related(
            'severity', 'category', 'location', 'user'
        ).prefetch_related('images').filter(
            location__isnull=False,
            location__latitude__isnull=False,
            location__longitude__isnull=False
        ).order_by('-created_at')[:500]  # Limit to most recent 500

        # Check if we have any reports
        context['has_reports'] = reports.exists()

        if not reports.exists():
            # No reports - will show empty state
            return context

        # Mapping severity levels to marker images (absolute URLs)
        marker_images = {
            '1': self.request.build_absolute_uri(static('common/images/markers/trash4.png')),  # Low
            '2': self.request.build_absolute_uri(static('common/images/markers/trash1.png')),  # Medium
            '3': self.request.build_absolute_uri(static('common/images/markers/trash2.png')),  # High
            '4': self.request.build_absolute_uri(static('common/images/markers/trash3.png')),  # Critical
        }
        context['marker_images_json'] = json.dumps(marker_images)

        # Build GeoJSON FeatureCollection
        features = []
        for report in reports:
            try:
                lng = float(report.location.longitude)
                lat = float(report.location.latitude)
            except (TypeError, ValueError, AttributeError):
                continue

            # Get severity info
            severity_level = getattr(report.severity, 'level', 1)
            severity_name = getattr(report.severity, 'name', 'Low')

            # Collect images
            images = []
            for img in report.images.all():
                if img.image:
                    images.append(self.request.build_absolute_uri(img.image.url))

            # Build properties
            properties = {
                'id': report.id,
                'title': report.title or f'Report #{report.id}',
                'observation': report.observation or '',
                'severity_level': severity_level,
                'severity_name': severity_name,
                'category': getattr(report.category, 'name', ''),
                'status': report.get_status_display(),
                'location_name': getattr(report.location, 'street_name', '') or 'Location',
                'username': report.user.get_full_name() or report.user.username,
                'avatar_url': self.request.build_absolute_uri(
                    report.user.userprofile.avatar) if report.user.userprofile.avatar else '',
                'created_at': report.created_at.strftime('%B %d, %Y'),
                'images': images,
                'marker_url': marker_images.get(str(severity_level), marker_images['1'])
            }

            feature = {
                'type': 'Feature',
                'geometry': {
                    'type': 'Point',
                    'coordinates': [lng, lat]
                },
                'properties': properties
            }
            features.append(feature)

        geojson = {
            'type': 'FeatureCollection',
            'features': features
        }

        context['reports_geojson'] = json.dumps(geojson)
        return context


class LeaderboardView(TemplateView):
    template_name = "core/leaderboard.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        # Get period from query params (default: all)
        period = self.request.GET.get('period', 'all')
        if period not in ['weekly', 'monthly', 'yearly', 'all']:
            period = 'all'

        context['current_period'] = period

        # Determine which field to order by
        order_field = {
            'weekly': '-weekly_points',
            'monthly': '-monthly_points',
            'yearly': '-yearly_points',
            'all': '-total_points'
        }.get(period, '-total_points')

        point_field = {
            'weekly': 'weekly_points',
            'monthly': 'monthly_points',
            'yearly': 'yearly_points',
            'all': 'total_points'
        }.get(period, 'total_points')

        # Optimized query: select_related for user and profile, limit to top 100
        scores = UserScore.objects.select_related(
            'user',
            'user__userprofile'
        ).order_by(order_field)[:100]

        # Filter out users with 0 points
        filtered_scores = [
            score for score in scores
            if getattr(score, point_field, 0) > 0
        ]

        # Check if we have any users
        context['has_users'] = len(filtered_scores) > 0

        if not filtered_scores:
            return context

        # Build leaderboard data
        leaderboard = []
        for rank, score in enumerate(filtered_scores, 1):
            # Get user profile info
            try:
                avatar = score.user.userprofile.avatar if score.user.userprofile.avatar else None
            except Exception:
                avatar = None

            leaderboard.append({
                'rank': rank,
                'user': score.user,
                'username': score.user.username,
                'full_name': score.user.get_full_name() or score.user.username,
                'avatar': avatar,
                'points': getattr(score, point_field, 0),
                'total_reports': score.total_reports,
                'verified_reports': score.verified_reports,
            })

        # Split into top 3 (podium) and rest
        context['top_three'] = leaderboard[:3] if len(leaderboard) >= 3 else leaderboard
        context['rest'] = leaderboard[3:] if len(leaderboard) > 3 else []

        # Add period display names
        context['period_display'] = {
            'weekly': 'This Week',
            'monthly': 'This Month',
            'yearly': 'This Year',
            'all': 'All Time'
        }.get(period, 'All Time')

        return context


def health_check(request):
    return JsonResponse({"status": "ok"})


# Handlers for custom error pages
def handler404(request, exception):
    return render(request, 'core/errors/404.html', status=404)


def handler500(request):
    return render(request, 'core/errors/500.html', status=500)
