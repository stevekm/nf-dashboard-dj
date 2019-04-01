from django.db import models

# Create your models here.
class NxfRun(models.Model):
    """
    """
    runId = models.CharField(max_length=255, unique = True, blank = False)
    runName = models.CharField(max_length=255, blank = False)
    added = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    def __str__(self):
        return(self.runId)

class NxfLogMessage(models.Model):
    """
    """
    runId = models.ForeignKey(NxfRun, on_delete=models.CASCADE)
    runName = models.CharField(max_length=255, blank = False)
    event = models.CharField(max_length=255, blank = False)
    runStatus = models.CharField(max_length=255, blank = False)
    utcTime = models.DateTimeField()
    body_json = models.TextField()
    added = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    def __str__(self):
        return("{0} {1} {2}".format(
        self.runName,
        self.event,
        self.utcTime
        ))
