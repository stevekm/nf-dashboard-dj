from django.shortcuts import render
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import NxfRun, NxfLogMessage
from .tasks import add, start_pipeline, store_Nxf_weblog_message
# from .settings import NXF_WEBLOG, NXF_LOG, NXF_SCRIPT
# from .forms import NextflowStartForm
import logging
import subprocess as sp
import datetime

logger = logging.getLogger()
logger.info("loading views")

# Create your views here.
def index(request):
    """
    Return the main page
    """
    logger.info("processing index request")
    template = "dashboard/index.html"
    context = {}
    return render(request, template, context)

@csrf_exempt
def start(request):
    """
    Start a Nextflow process via POST request
    """
    if request.method == 'POST':
        logger.info("Got start POST request")
        res = start_pipeline.delay()
        # TODO: what should be returned here?
        return HttpResponse("")

@csrf_exempt
def listen(request):
    """
    Listen for HTTP messages from Nextflow pipeline
    """
    if request.method == 'POST':
        logger.info("Got listen POST request")
        message_json = request.body
        res = store_Nxf_weblog_message.delay(message_json)
        return HttpResponse("")

@csrf_exempt
def test(request):
    """
    test using Celery task to run in the background; eventually need to use this for the Nextflow pipeline running
    """
    if request.method == 'POST':
        logger.info("Running async demo add task with celery")
        res = add.delay(4, 4)
        return HttpResponse("")
