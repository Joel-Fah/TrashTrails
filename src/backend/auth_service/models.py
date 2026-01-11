from django.db import models
from django.contrib.auth.models import User


# Create your models here.

# Override User __str__ to show admin/superadmin label
def user_str_with_role(self):
    if self.is_superuser:
        return f"{self.username} <superadmin>"
    elif self.is_staff:
        return f"{self.username} <admin>"
    return f"{self.get_full_name()} ({self.username})"


User.__str__ = user_str_with_role


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone_number = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    avatar = models.URLField(max_length=500, blank=True, null=True)

    def __str__(self):
        return self.user.email
