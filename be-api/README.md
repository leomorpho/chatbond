# chatbond-api

[![Build Status](https://travis-ci.org/leomorpho/chatbond-api.svg?branch=master)](https://travis-ci.org/leomorpho/chatbond-api)
[![Built with](https://img.shields.io/badge/Built_with-Cookiecutter_Django_Rest-F7B633.svg)](https://github.com/agconti/cookiecutter-django-rest)

Rekindle Relationships and Spark Meaningful Conversations.. Check out the project's [documentation](http://leomorpho.github.io/chatbond-api/).

# Prerequisites

- [Docker](https://docs.docker.com/docker-for-mac/install/)

# Local Development

Start the dev server for local development:

```bash
docker-compose up
```

Run a command inside the docker container:

```bash
docker-compose run --rm web [command]
```

## Run unit tests

There are a few different ways to run unit tests.

### Locally, on your machine

```Bash
export DJANGO_CONFIGURATION=Testing
export DJANGO_SETTINGS_MODULE=chatbond.config
export DJANGO_SECRET_KEY=Z38yZgHxnANqs9cdihJKvzwCB

# Instal venv locally
poetry install

# Run tests
python manage.py test --parallel
```

### Locally, in our Earthly CI

```Bash
earthly +unit-tests
```

Note that this CI also runs on pushes/merges to `main` branch.

### In docker-compose

```Bash
make up

make connect

# -> Then in container, do `python manage.py test --parallel`
```

## OpenAPI

Go to `http://localhost:8000/api/docs/#/` to see openAPI doc.

## Django Admin

```
python manage.py createsuperuser
```

I usually use `leonard.audibert@gmail.com` and `testpassword` for dev.

Access adming view at `http://localhost:8000/admin/login/`.

## Testing emails

Use `shell_plus` instead of `python manage.py shell` as it pre-imports a bunch of important models.

In Django shell:

```Python
from django.core.mail import send_mail

send_mail(
    'Hello',
    'Body goes here',
    'from@example.com',
    ['to@example.com'],
    fail_silently=False,
)
```

Then in the Mailhog container's UI (`http://localhost:8025/#`), you should see that new email.

# Nginx

See the `nginx.conf` file.

```
# Enable uncomplicated firewall
sudo ufw enable
#
# Install nginx
sudo apt install nginx
#
# Adjust firewall
# List the application configurations that ufw knows how to work with:
sudo ufw app list
#
# sudo ufw allow 'Nginx HTTPS'
sudo ufw allow ssh
#
# Add Cloudflare IPs to ufw whitelist: https://www.cloudflare.com/ips/
sudo ufw allow from 103.21.244.0/22 to any port 443 proto tcp
sudo ufw allow from 103.22.200.0/22 to any port 443 proto tcp
sudo ufw allow from 103.31.4.0/22 to any port 443 proto tcp
sudo ufw allow from 104.16.0.0/13 to any port 443 proto tcp
sudo ufw allow from 104.24.0.0/14 to any port 443 proto tcp
sudo ufw allow from 108.162.192.0/18 to any port 443 proto tcp
sudo ufw allow from 131.0.72.0/22 to any port 443 proto tcp
sudo ufw allow from 141.101.64.0/18 to any port 443 proto tcp
sudo ufw allow from 162.158.0.0/15 to any port 443 proto tcp
sudo ufw allow from 172.64.0.0/13 to any port 443 proto tcp
sudo ufw allow from 173.245.48.0/20 to any port 443 proto tcp
sudo ufw allow from 188.114.96.0/20 to any port 443 proto tcp
sudo ufw allow from 190.93.240.0/20 to any port 443 proto tcp
sudo ufw allow from 197.234.240.0/22 to any port 443 proto tcp
sudo ufw allow from 198.41.128.0/17 to any port 443 proto tcp
#
# Reload with new rules:
sudo ufw reload
#
# Check service status, should be running
systemctl status nginx
#
# Add Cloudflare SSL certificates and set permissions
sudo chown root:root /etc/nginx/ssl/chatbond-app.key /etc/nginx/ssl/chatbond-app.crt
sudo chmod 600 /etc/nginx/ssl/chatbond-app.key /etc/nginx/ssl/chatbond-app.crt
#
# Copy this config, usually like the following:
cp nginx.conf /etc/nginx/sites-enabled/chatbond
#
# Optionally encrypt the private key, which will require a password to reboot nginx
openssl rsa -aes256 -in /etc/nginx/ssl/chatbond-app.key -out /etc/nginx/ssl/encrypted-chatbond-app.key
#
# Then verify config is good:
nginx -t
#
# If it says all is good, reload the config:
nginx -s reload
# or restart nginx
sudo systemctl restart nginx


# To check nginx error logs:
tail -f /var/log/nginx/error.log
```

Make sure to go into the django container and run `python manage.py collectstatic` to collect all the static assets.

## Local tests within server

- `curl https://localhost:80` -> should fail
- `curl https://localhost:443` -> should succeed

## Important links

- Mailhog: http://localhost:8025/#
- Django admin dashboard: http://localhost:8000/admin/login/ (need to do `python manage.py createsuperuser` before being able login, I usually use `leonard.audibert@gmail.com` and `testpassword` for dev.)
- Django API: http://localhost:8000/api/docs/#/
- Centrifugo dashboard: http://localhost:8080/

# Docker Swarm

## Create a Swarm

1. `docker swarm init --advertise-addr <MANAGER-IP>`
2. `docker info`
3. `docker node ls` to view info about running nodes (only the manager node for now).
4. Add as maany nodes as you want with `docker swarm join --token <TOKEN> <MANAGER-IP>`. To get a token, in manager node do `docker swarm join-token worker`.
5. Inspect a single node: `docker node inspect <NODE-ID> --pretty`

## Setup registry

1.

## Deploy a stack

1. To deploy: `docker stack deploy -c docker-compose-common.yml chatbond_swarm`
2. To scale
   1. you can simply update `replicas` in docker-compose and re-deploy: `docker stack deploy -c docker-compose-common.yml chatbond_swarm`
   2. or use `docker service scale`: `docker service scale chatbond_swarm_chatbond_api=5`
3. To monitor:
   1. `docker service ls`
   2. `docker service ps chatbond_swarm_chatbond_api`
