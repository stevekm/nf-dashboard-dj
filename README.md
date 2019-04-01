# nf-dashboard-dj

Nextflow dashboard and API to demonstrate running Nextflow pipeline from Django web app and catching the workflow log messages with an API to store in a database. Uses Celery and RabbitMQ for concurrent processing of Nextflow pipeline and capture of http weblog messages in Django database.

# Installation

Clone this repo:
```
git clone https://github.com/stevekm/nf-dashboard-dj.git
cd nf-dashboard-dj
```

Install dependencies with conda in the current directory

```
make install
```

- Supply a username and password for the admin account

# Usage

Start RabbitMQ and Celery servers

```
make rabbitmq-start celery-start
```

Start the development Django server

```
make runserver
```

Navigate to `http://127.0.0.1:8000/` in your web browser and click the "Start" button to run a Nextflow pipeline

![Screen Shot 2019-04-01 at 4 18 48 PM](https://user-images.githubusercontent.com/10505524/55356933-dca45f00-5499-11e9-81c0-5500ef68f606.png)

Check out the Nextflow `weblog` messages in the Django admin panel at `http://127.0.0.1:8000/admin`

![Screen Shot 2019-04-01 at 4 13 31 PM](https://user-images.githubusercontent.com/10505524/55356618-280a3d80-5499-11e9-9208-02b477b0a9e1.png)

![Screen Shot 2019-04-01 at 4 13 56 PM](https://user-images.githubusercontent.com/10505524/55356642-39ebe080-5499-11e9-8c27-6e4e3d8f6000.png)


When finished, shut down Celery and RabbitMQ:

```
make celery-stop rabbitmq-stop
```
