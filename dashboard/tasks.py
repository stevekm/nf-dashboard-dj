# Create your Celery tasks here
from __future__ import absolute_import, unicode_literals
from celery import shared_task
from celery.utils.log import get_task_logger
import subprocess as sp
from .settings import NXF_WEBLOG, NXF_LOG, NXF_SCRIPT
from .models import NxfRun, NxfLogMessage
import logging
import datetime
import json

# TODO: figure out the best method for logging here...
celery_logger = get_task_logger(__name__)
dashboard_logger = logging.getLogger(__name__)

# TODO: look into greater concurency, task queues and routing; http://docs.celeryproject.org/en/latest/userguide/routing.html#id2
# https://stackoverflow.com/questions/34830964/how-to-limit-the-maximum-number-of-running-celery-tasks-by-name
# need to limit Nextflow running to only one instance at a time otherwise Nextflow locks pipeline
# however API listen tasks can run separately,
# otherwise multiple Nextflow pipelines started at once block all database updating



@shared_task
def add(x, y):
    celery_logger.debug("running the add task...")
    return x + y

@shared_task
def start_pipeline():
    """
    Start a Nextflow pipeline with http weblog enabled
    """
    dashboard_logger.info("Starting Nextflow pipeline")
    command = ['nextflow', '-log', NXF_LOG, 'run', NXF_SCRIPT, '-with-weblog', NXF_WEBLOG ]
    process = sp.Popen(command,
        stdout = sp.PIPE,
        stderr = sp.PIPE,
        shell = False,
        universal_newlines = True)
    proc_stdout, proc_stderr = process.communicate()
    if process.returncode == 0:
        dashboard_logger.debug("Nextflow pipeline finished successfully")
    else:
        dashboard_logger.error("Nextflow pipeline finished with error code: {0}".format(
        str(process.returncode)
        ))
    dashboard_logger.debug(proc_stdout)
    dashboard_logger.debug(proc_stderr)


@shared_task
def store_Nxf_weblog_message(message_json):
    """
    Stores the JSON formatted Nextflow weblog message in a Django database model

    Example JSON:

    {'runId': 'ab3882b5-bc08-45a1-aff0-45c0173e5b17', 'event': 'started', 'runName': 'distraught_shaw', 'runStatus': 'started', 'utcTime': '2019-03-25T16:47:59Z'}
    {'runId': 'ab3882b5-bc08-45a1-aff0-45c0173e5b17', 'event': 'completed', 'runName': 'distraught_shaw', 'runStatus': 'completed', 'utcTime': '2019-03-25T16:47:59Z'}
    {
    "trace": {
        "task_id": 2,
        "status": "COMPLETED",
        "hash": "86/f0397b",
        "name": "print_sampleID (2)",
        "exit": 0,
        "submit": 1554140521913,
        "start": 1554140521988,
        "process": "print_sampleID",
        "tag": null,
        "module": [],
        "container": null,
        "attempt": 1,
        "script": "\n    echo \"Sample2\" > \"Sample2.txt\"\n    ",
        "scratch": null,
        "workdir": "/Users/kellys04/projects/nf-dashboard-dj/nxf/work/86/f0397b5e6c0fa5bca67f17c0c61e4b",
        "queue": null,
        "cpus": 1,
        "memory": null,
        "disk": null,
        "time": null,
        "env": null,
        "error_action": null,
        "complete": 1554140522015,
        "duration": 102,
        "realtime": 27,
        "native_id": 80410
    },
    "runId": "b3fdc02f-bbf8-41d2-aab4-61ca93513244",
    "event": "process_completed",
    "runName": "curious_wright",
    "runStatus": "process_completed",
    "utcTime": "2019-04-01T17:42:02Z"
    }
    """
    dashboard_logger.info("Parsing Nextflow weblog message to store in database")
    message_data = json.loads(message_json)
    # print(json.dumps(message_data, indent = 4))

    # all log messages should have these keys
    runId = message_data['runId']
    runName = message_data['runName']
    event = message_data['event']
    runStatus = message_data['runStatus']

    # https://stackoverflow.com/questions/127803/how-do-i-parse-an-iso-8601-formatted-date
    # requires Python 3.7
    utcTime = datetime.datetime.fromisoformat(
        message_data['utcTime'].replace("Z", "+00:00")
        )
    # datetime.datetime.strptime(message_data['utcTime'], '%Y-%m-%dT%H:%M:%S%Z')

    # check for process trace data
    trace = message_data.get('trace', None)
    # TODO: handle the trace separately ??

    dashboard_logger.debug("Nexflow weblog JSON successfully parsed, saving to database")
    runId_instance, runId_created = NxfRun.objects.get_or_create(
        runId = runId,
        runName = runName
        )
    logMessage_instance, logMessage_created = NxfLogMessage.objects.get_or_create(
        runId = runId_instance,
        event = event,
        runName = runName,
        runStatus = runStatus,
        utcTime = utcTime,
        body_json = message_json)
    return(logMessage_created)
