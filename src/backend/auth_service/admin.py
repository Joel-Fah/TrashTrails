from django.contrib import admin
from django.contrib.auth.admin import GroupAdmin as BaseGroupAdmin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User, Group
from unfold.admin import ModelAdmin
from unfold.forms import AdminPasswordChangeForm, UserChangeForm, UserCreationForm
from allauth.socialaccount.models import SocialAccount, SocialApp, SocialToken, EmailAddress
from rest_framework.authtoken.models import TokenProxy
from django.contrib.sites.models import Site


# Register your models here.
admin.site.unregister(User)
admin.site.unregister(Group)

@admin.register(User)
class UserAdmin(BaseUserAdmin, ModelAdmin):
    # Forms loaded from `unfold.forms`
    form = UserChangeForm
    add_form = UserCreationForm
    change_password_form = AdminPasswordChangeForm


@admin.register(Group)
class GroupAdmin(BaseGroupAdmin, ModelAdmin):
    pass


# Override allauth social account admin
admin.site.unregister(SocialAccount)
admin.site.unregister(SocialApp)
admin.site.unregister(SocialToken)
admin.site.unregister(EmailAddress)

@admin.register(SocialAccount)
class SocialAccountAdmin(ModelAdmin):
    pass

@admin.register(SocialApp)
class SocialAppAdmin(ModelAdmin):
    pass

@admin.register(SocialToken)
class SocialTokenAdmin(ModelAdmin):
    pass

@admin.register(EmailAddress)
class EmailAddressAdmin(ModelAdmin):
    pass

# Register rest_framework authtoken TokenProxy model
admin.site.unregister(TokenProxy)
@admin.register(TokenProxy)
class TokenAdmin(ModelAdmin):
    pass

# Override sites admin
admin.site.unregister(Site)
@admin.register(Site)
class SiteAdmin(ModelAdmin):
    pass