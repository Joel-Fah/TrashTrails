import hashlib

from django.contrib import admin
from django.contrib.auth.admin import GroupAdmin as BaseGroupAdmin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User, Group
from unfold.admin import ModelAdmin
from unfold.forms import AdminPasswordChangeForm, UserChangeForm, UserCreationForm
from rest_framework.authtoken.models import TokenProxy
from django.contrib.sites.models import Site
from django.utils.html import format_html

from auth_service.models import UserProfile

# Register your models here.
admin.site.unregister(User)
admin.site.unregister(Group)


@admin.register(User)
class UserAdmin(BaseUserAdmin, ModelAdmin):
    # Forms loaded from `unfold.forms`
    form = UserChangeForm
    add_form = UserCreationForm
    change_password_form = AdminPasswordChangeForm
    list_display = ('username_with_role', 'email', 'first_name', 'last_name', 'is_staff')

    @admin.display(description='Username')
    def username_with_role(self, obj):
        profile = getattr(obj, 'userprofile', None)
        avatar_url = None
        if profile is not None:
            avatar_field = getattr(profile, 'avatar', None)
            if avatar_field:
                if hasattr(avatar_field, 'url'):
                    try:
                        avatar_url = avatar_field.url
                    except Exception:
                        avatar_url = None
                else:
                    if isinstance(avatar_field, str) and avatar_field.strip():
                        avatar_url = avatar_field.strip()

        if avatar_url:
            avatar_html = format_html(
                '<img src="{}" style="width:32px;height:32px;border-radius:50%;object-fit:cover;margin-right:8px;vertical-align:middle;">',
                avatar_url
            )
        else:
            if obj.first_name or obj.last_name:
                initials = (obj.first_name[:1] + obj.last_name[:1]).upper()
            else:
                initials = obj.username[:2].upper()
            color = '#' + hashlib.md5(obj.username.encode('utf-8')).hexdigest()[:6]
            avatar_html = format_html(
                '<span style="display:inline-flex;width:32px;height:32px;border-radius:50%;align-items:center;justify-content:center;margin-right:8px;vertical-align:middle;background-color:{};color:#fff;font-weight:600;">{}</span>',
                color, initials
            )

        if obj.is_superuser:
            role_html = format_html('<span style="color: #dc2626; font-weight: bold;">&lt;superadmin&gt;</span>')
        elif obj.is_staff:
            role_html = format_html('<span style="color: #2563eb; font-weight: bold;">&lt;admin&gt;</span>')
        else:
            role_html = ''

        return format_html(
            '<span style="display:inline-flex;align-items:center;white-space:nowrap;">{}<span style="vertical-align:middle;font-weight:500;margin-right:6px;">{}</span>{}</span>',
            avatar_html, obj.username, role_html
        )


@admin.register(Group)
class GroupAdmin(BaseGroupAdmin, ModelAdmin):
    pass


@admin.register(UserProfile)
class UserProfileAdmin(ModelAdmin):
    list_display = ('user', 'phone_number', 'address', 'avatar_display')

    @admin.display(description='Avatar')
    def avatar_display(self, obj):
        avatar_url = None
        avatar_field = getattr(obj, 'avatar', None)
        if avatar_field:
            if hasattr(avatar_field, 'url'):
                try:
                    avatar_url = avatar_field.url
                except Exception:
                    avatar_url = None
            else:
                if isinstance(avatar_field, str) and avatar_field.strip():
                    avatar_url = avatar_field.strip()

        if avatar_url:
            return format_html(
                '<img src="{}" style="width:36px;height:36px;border-radius:50%;object-fit:cover;">',
                avatar_url
            )

        user = getattr(obj, 'user', None)
        if user and (user.first_name or user.last_name):
            initials = (user.first_name[:1] + user.last_name[:1]).upper()
        elif user and getattr(user, 'username', None):
            initials = user.username[:2].upper()
        else:
            initials = str(getattr(obj, 'pk', ''))[:2].upper() or '-'

        seed = (user.username if user and getattr(user, 'username', None) else str(getattr(obj, 'pk', ''))) or str(obj)
        color = '#' + hashlib.md5(seed.encode('utf-8')).hexdigest()[:6]

        return format_html(
            '<span style="display:inline-flex;width:36px;height:36px;border-radius:50%;align-items:center;justify-content:center;background-color:{};color:#fff;font-weight:600;">{}</span>',
            color, initials
        )


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
