from django.urls import path
from .views import MapDataView

app_name = 'map'

urlpatterns = [
    path('data/', MapDataView.as_view(), name='map-data'),
]
