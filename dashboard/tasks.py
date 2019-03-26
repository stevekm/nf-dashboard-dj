# Create your Celery tasks here
from __future__ import absolute_import, unicode_literals
from celery import shared_task
import time
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)

@shared_task
def add(x, y):
    logger.debug("running the add task...")
    # time.sleep(10)
    return x + y
