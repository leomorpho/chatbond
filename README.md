# Chatbond
A proof-of-concept for a mobile app to improve intimate relationships through daily questions.
This app was created as part of a learning experience. I had very limited frontend experience and wanted to learn Flutter. By deploying this app to production for close friends and family, I also learned CI/CD and devops principles, as I initially deployed it with `docker swarm` but eventually settled `docker-compose` as a sufficient solution (I didn't need any crazy dynamic scaling).

https://github.com/leomorpho/chatbond/assets/7016204/f94e0bac-2e8b-412d-8bc9-60fc3de47344
 
The app contains 3 separate repos:

* **be-api**: the Django-REST API.
* **mobile-app**: the flutter app, which runs both on the web and mobile (android/iOS).
* **ml-exploration**: used to explore ML approaches for recommendation and other issues worked on as part of this project.
All repos contain a README, but for quick startup, one can start the whole app by starting the BE and FE separately:

### What I learned in this project:

* Flutter web and mobile app development and deployment.
* Django-DRF.
* FE architecture paradigms: two main ones were dart streams and the BLOC pattern to separate UI from business logic.
* More advanced containerization techniques for Dockerfiles.
* Docker swarm, even though I ended up not using it because it was overkill.
* CI/CD with github and Earthly.
* Nginx and reverse proxy setup.
* Some basic GCP and terraform principles, although I ended up not going that direction for deployment.
* Use ML recommendation engines in production and using S3 to backup ML models and necessary data.
* Use ML clustering algorithms to sort my `questions` dataset, as well as use LLMs to extract keywords and assign categories for each question.
* Backup and restore my production Postgres DB with S3.
* Poetry: better python virtual environment management.
* Dramatiq task manager (alternative to Celery that is less of a pain in the neck).
* Mailhog, RabbitMQ, Postgres.
* Centrifugo (web socket server which allows to separate realtime layer from application code, also very scalable).

## Demo
The demo at the top demos 2 clients talking to each other through the app. It walks through the basic features of the app:

* User flow to answer a question and see answers.
* User flow to chat live with contact.
* Live update of data (notifications, answers).

## Quickstart

### Backend:

```bash
cd be-api
make up

# The above starts with the logs attached to the output, so in a new terminal
# Connect to the Django API
make connect

# Run django command to seed users, fake messages and questions.
$ python manage.py seed_test # or seed_initial in prod
```

### Frontend:

```bash
make dev-6060
```

To make multiple FE clients (for example to test sockets for real-time messaging), the command `make dev-X` can use any available port for `X`.

Feel free to use these existing logins:

```bash
alice@test.com
testpassword

bob@test.com
testpassword

lynn@test.com
testpassword
```

You can also register a new user. You will need to activate that user before being able to login. That can be done by either getting the activation link from mailhog [here](http://localhost:8025/#) or by updating the field in DB (first approach is recommended).
