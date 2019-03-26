SHELL:=/bin/bash
UNAME:=$(shell uname)
export LOG_DIR:=logs

# install app
install: conda-install

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
	django=2.1.5 \
	nextflow=19.01.0 \
	celery=4.2.1 \
	rabbitmq-server=3.7.13 && \
	pip install \
	django-celery-results==1.0.4 \
	django-celery-beat==1.4.0

test1:
	nextflow -version

# ~~~~~ SETUP DJANGO APP ~~~~~ #
export DJANGO_DB:=db.sqlite3
# create the app for development; only need to run this when first creating repo
django-start:
	django-admin startproject dashboard .

# all the steps needed to set up the django app
django: django-init

init:
	python manage.py makemigrations
	python manage.py migrate
	python manage.py createsuperuser

# run the Django dev server
runserver:
	python manage.py runserver

# re-initialize just the databases
reinit:
	python manage.py makemigrations
	python manage.py migrate

# destroy app database
nuke:
	@echo ">>> Removing database items:"; \
	rm -rfv dashboard/migrations/__pycache__ && \
	rm -fv dashboard/migrations/0*.py
	rm -fv "$(DJANGO_DB)"



# ~~~~~ RUN NEXTFLOW ~~~~~ #
# https://www.nextflow.io/docs/latest/tracing.html#weblog-service
NXF_DIR:=nxf
export NXF_WORK:=$(NXF_DIR)/work
export NXF_TEMP:=$(NXF_DIR)/.nextflow
export NXF_LOG:=$(NXF_DIR)/.nextflow.log
export NXF_PID_FILE:=$(NXF_DIR)/.nextflow.pid
export NXF_WEBLOG:=http://127.0.0.1:8000/listen/
run-nextflow:
	# nextflow help
	nextflow -log "$(NXF_LOG)" run nxf/main.nf -with-weblog "$(NXF_WEBLOG)" # -bg
