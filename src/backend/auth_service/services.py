from django.contrib.auth.models import User
from .models import UserProfile

class AuthService:

    @staticmethod
    def get_or_create_user(email, extra_data=None):
        user, created = User.objects.get_or_create(
            email=email,
            defaults={'username': email}
        )

        profile, _ = UserProfile.objects.get_or_create(user=user)

        if extra_data:
            profile.phone_number = extra_data.get('phone_number', profile.phone_number)
            profile.address = extra_data.get('address', profile.address)
            profile.save()

        return user
