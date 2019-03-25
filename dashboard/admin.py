from django.contrib import admin

# Register your models here.
from .models import NxfRun
from .models import NxfLogMessage

admin.site.register(NxfRun)
admin.site.register(NxfLogMessage)
