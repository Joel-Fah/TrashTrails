from django.contrib import admin
from django.contrib.auth.admin import GroupAdmin as BaseGroupAdmin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User, Group
from unfold.admin import ModelAdmin
from unfold.forms import AdminPasswordChangeForm, UserChangeForm, UserCreationForm
from rest_framework.authtoken.models import TokenProxy
from django.contrib.sites.models import Site
from django.utils.html import format_html

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
        if obj.is_superuser:
            return format_html('{} <span style="color: #dc2626; font-weight: bold;">&lt;superadmin&gt;</span>', obj.username)
        elif obj.is_staff:
            return format_html('{} <span style="color: #2563eb; font-weight: bold;">&lt;admin&gt;</span>', obj.username)
        return obj.username


@admin.register(Group)
class GroupAdmin(BaseGroupAdmin, ModelAdmin):
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
