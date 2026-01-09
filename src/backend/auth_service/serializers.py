from rest_framework import serializers
from django.contrib.auth.models import User
from allauth.socialaccount.models import SocialAccount
from .models import UserProfile


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['phone_number', 'address']


class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(source='userprofile')
    avatar = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'first_name',
            'last_name',
            'avatar',
            'profile',
        ]

    def get_avatar(self, obj):
        try:
            social = SocialAccount.objects.get(user=obj, provider='google')
            return social.extra_data.get('picture')
        except SocialAccount.DoesNotExist:
            return None

class UserProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['phone_number', 'address']
