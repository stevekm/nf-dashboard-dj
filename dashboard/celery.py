from __future__ import absolute_import, unicode_literals
import os
import sys
import django
import logging
from celery import Celery

# import django app
parentdir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
sys.path.insert(0, parentdir)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "dashboard.settings")
django.setup()
sys.path.pop(0)

logger = logging.getLogger()
logger.debug("Loading celery module...")

RABBITMQ_NODENAME = os.environ.get('RABBITMQ_NODENAME', 'localhost')
RABBITMQ_NODE_IP_ADDRESS = os.environ.get('RABBITMQ_NODE_IP_ADDRESS', '127.0.0.1')
RABBITMQ_NODE_PORT = os.environ.get('RABBITMQ_NODE_PORT', 'localhost')
CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL')
# broker_url = "amqp://{0}:{1}".format(RABBITMQ_NODE_IP_ADDRESS, RABBITMQ_NODE_PORT)
# logger.debug(broker_url)

app = Celery('dashboard',
    broker_url = CELERY_BROKER_URL,
    broker='amqp://',
    backend='django-db')

# http://docs.celeryproject.org/en/latest/userguide/configuration.html
app.conf.update(
    result_backend='django-db',
    task_track_started=True
)

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))
