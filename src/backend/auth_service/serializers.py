from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['phone_number', 'address']


class UserPublicSerializer(serializers.ModelSerializer):
    """Public user info - no sensitive data"""
    avatar = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'avatar', 'date_joined', 'last_login', 'is_active']
        ref_name = 'AuthUserPublic'

    def get_avatar(self, obj):
        try:
            return obj.userprofile.avatar if hasattr(obj, 'userprofile') else None
        except UserProfile.DoesNotExist:
            return None


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
            'date_joined',
            'last_login',
            'is_active',
        ]

    def get_avatar(self, obj):
        try:
            return obj.userprofile.avatar if hasattr(obj, 'userprofile') else None
        except UserProfile.DoesNotExist:
            return None


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['phone_number', 'address']
