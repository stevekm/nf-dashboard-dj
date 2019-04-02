SHELL:=/bin/bash
UNAME:=$(shell uname)
export LOG_DIR:=logs
export LOG_DIR_ABS:=$(shell python -c 'import os; print(os.path.realpath("$(LOG_DIR)"))')
# install app
install: conda-install init

# ~~~~~ Setup Conda ~~~~~ #
# this sets the system PATH to ensure we are using in included 'conda' installation for all software
PATH:=$(CURDIR)/conda/bin:$(PATH)
unexport PYTHONPATH
unexport PYTHONHOME

# install versions of conda for Mac or Linux
ifeq ($(UNAME), Darwin)
CONDASH:=Miniconda3-4.5.4-MacOSX-x86_64.sh
endif

ifeq ($(UNAME), Linux)
CONDASH:=Miniconda3-4.5.4-Linux-x86_64.sh
endif

CONDAURL:=https://repo.continuum.io/miniconda/$(CONDASH)

# install conda
conda:
	@echo ">>> Setting up conda..."
	@wget "$(CONDAURL)" && \
	bash "$(CONDASH)" -b -p conda && \
	rm -f "$(CONDASH)"

# install the conda and python packages required
# NOTE: **MUST** install ncurses from conda-forge for RabbitMQ to work!!
conda-install: conda
	conda install -y conda-forge::ncurses && \
	conda install -y -c anaconda -c bioconda \
	python=3.7 \
	django=2.1.5 \
	nextflow=19.01.0 \
	rabbitmq-server=3.7.13 && \
	pip install \
	celery==4.3.0 \
	django-celery-results==1.0.4 \
	django-celery-beat==1.4.0

# celery=4.2.1 \ # not compatible with py3.7...
test1:
	nextflow -version
	conda search celery

# ~~~~~ SETUP DJANGO APP ~~~~~ #
export DJANGO_DB:=django.sqlite3
export DASHBOARD_DB:=dashboard.sqlite3
# create the app for development; only need to run this when first creating repo
# django-start:
# 	django-admin startproject dashboard .

# all the steps needed to set up the django app
django: django-init

init:
	python manage.py makemigrations
	python manage.py migrate
	python manage.py migrate django_celery_results
	python manage.py migrate dashboard --database=dashboard_db
	python manage.py createsuperuser

# run the Django dev server
runserver:
	python manage.py runserver
runserver-all: celery-start rabbitmq-start
	finish () { "$(MAKE)" celery-stop rabbitmq-stop ; sleep 5 ; } ; \
	trap finish EXIT ; \
	python manage.py runserver

stopserver: celery-stop rabbitmq-stop

# re-initialize just the databases
reinit:
	python manage.py makemigrations
	python manage.py migrate
	python manage.py migrate django_celery_results
	python manage.py migrate dashboard --database=dashboard_db

# destroy app database
nuke:
	@echo ">>> Removing database items:"; \
	rm -rfv dashboard/migrations/__pycache__ && \
	rm -fv dashboard/migrations/0*.py
	rm -fv "$(DASHBOARD_DB)"
nuke-all:
	rm -fv "$(DJANGO_DB)"

shell:
	python manage.py shell

# ~~~~~~ Celery tasks & RabbitMQ setup ~~~~~ #
# !! need to start RabbitMQ before celery, and both before running app servers !!
# https://www.rabbitmq.com/configure.html
# https://www.rabbitmq.com/configure.html#customise-environment
# https://www.rabbitmq.com/relocate.html
export RABBITMQ_CONFIG_FILE:=conf/rabbitmq
# export RABBITMQ_NODENAME:=rabbit@$(shell hostname)
export RABBITMQ_NODENAME:=rabbit
export RABBITMQ_NODE_IP_ADDRESS:=127.0.0.1
export RABBITMQ_NODE_PORT:=5674
export RABBITMQ_LOG_BASE:=$(LOG_DIR_ABS)
export RABBITMQ_LOGS:=rabbitmq.log
export RABBITMQ_PID_FILE:=$(RABBITMQ_LOG_BASE)/rabbitmq.pid
CELERY_DEFAULT_PID_FILE:=$(LOG_DIR_ABS)/celery.default.pid
CELERY_DEFAULT_LOGFILE:=$(LOG_DIR_ABS)/celery.default.log
CELERY_NEXTFLOW_PID_FILE:=$(LOG_DIR_ABS)/celery.nextflow.pid
CELERY_NEXTFLOW_LOGFILE:=$(LOG_DIR_ABS)/celery.nextflow.log
export CELERY_BROKER_URL:=amqp://$(RABBITMQ_NODE_IP_ADDRESS):$(RABBITMQ_NODE_PORT)
# start 1 concurrent worker for Nextflow and 2 for all other tasks
celery-start:
	celery worker --app dashboard --loglevel info --pidfile "$(CELERY_DEFAULT_PID_FILE)" --logfile "$(CELERY_DEFAULT_LOGFILE)" --queues=default --concurrency=2 --hostname=default@%h --detach
	celery worker --app dashboard --loglevel info --pidfile "$(CELERY_NEXTFLOW_PID_FILE)" --logfile "$(CELERY_NEXTFLOW_LOGFILE)" --queues=run_nextflow --concurrency=1 --hostname=nextflow@%h --detach

# interactive for debugging
celery-start-inter:
	echo "$(CELERY_BROKER_URL)"
	celery worker \
	--app dashboard \
	--loglevel debug \
	--concurrency=1 \
	--broker "$(CELERY_BROKER_URL)"

test2:
	celery -h
celery-check:
	-ps auxww | grep 'celery' | grep -v 'grep' | grep -v 'make celery-check'
# ps auxww | grep 'celery worker'

celery-stop:
	ps auxww | grep 'celery' | grep -v 'grep' | grep -v 'make celery-stop' | awk '{print $$2}' | xargs kill -9 || \
	head -1 "$(CELERY_PID_FILE)" | xargs kill -9

# >>> from dashboard.tasks import add
# >>> res = add.delay(2,3)
# >>> res.status
# >>> res.backend
# >>> from dashboard.celery import debug_task
#

rabbitmq-start:
	rabbitmq-server -detached
rabbitmq-start-inter:
	rabbitmq-server
rabbitmq-stop:
	rabbitmqctl stop
rabbitmq-check:
	-rabbitmqctl status



# ~~~~~ RUN NEXTFLOW ~~~~~ #
# https://www.nextflow.io/docs/latest/tracing.html#weblog-service
NXF_DIR:=nxf
export NXF_DIR_ABS:=$(shell python -c 'import os; print(os.path.realpath("$(NXF_DIR)"))')
export NXF_SCRIPT:=$(NXF_DIR_ABS)/main.nf
export NXF_WORK:=$(NXF_DIR_ABS)/work
export NXF_TEMP:=$(NXF_DIR_ABS)/.nextflow
export NXF_LOG:=$(NXF_DIR_ABS)/.nextflow.log
export NXF_PID_FILE:=$(NXF_DIR_ABS)/.nextflow.pid
export NXF_WEBLOG:=http://127.0.0.1:8000/listen/
run-nextflow:
	# nextflow help
	nextflow -log "$(NXF_LOG)" run nxf/main.nf -with-weblog "$(NXF_WEBLOG)" # -bg
