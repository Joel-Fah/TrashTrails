from allauth.socialaccount.signals import social_account_added
from django.dispatch import receiver

@receiver(social_account_added)
def populate_user_from_google(request, sociallogin, **kwargs):
    user = sociallogin.user
    extra_data = sociallogin.account.extra_data

    if not user.first_name:
        user.first_name = extra_data.get('given_name', '')

    if not user.last_name:
        user.last_name = extra_data.get('family_name', '')

    user.save()
