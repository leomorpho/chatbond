FROM python:3.8 AS python-base

#------------------------
FROM python-base AS builder

ARG BUILD_ENVIRONMENT=production

ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    PATH="$PATH:/runtime/bin" \
    PYTHONPATH="$PYTHONPATH:/runtime/lib/python3.8/site-packages" \
    POETRY_VERSION=1.4.2

RUN pip install --no-cache-dir --force-reinstall "poetry==$POETRY_VERSION"

WORKDIR /code

# Generate requirements and install *all* dependencies.
COPY pyproject.toml poetry.lock /code/

RUN poetry export --without-hashes --output=requirements.txt && \
    poetry export --without-hashes --dev --output=requirements-dev.txt

RUN --mount=type=cache,target=/root/.cache \
    python3 -m pip install --prefix=/runtime --no-deps --no-cache-dir --force-reinstall -r requirements.txt

RUN --mount=type=cache,target=/root/.cache \
    python3 -m pip install --prefix=/runtime --no-deps --no-cache-dir --force-reinstall -r requirements-dev.txt

#------------------------
FROM python-base AS runtime

# Copy runtime dependencies
COPY --from=builder /runtime /usr/local

# Copy project files
RUN mkdir -p /code/chatbond
COPY chatbond code/chatbond/
COPY .envs /code
COPY wait_for_dependencies.py /code
COPY manage.py /code

WORKDIR /code

# Create logs directory
RUN mkdir -p /code/logs

# Create a new IPython profile and configure it to automatically load the autoreload extension
RUN ipython profile create && echo "c.InteractiveShellApp.exec_lines = ['%load_ext autoreload', '%autoreload 2']" >> ~/.ipython/profile_default/ipython_config.py

# Set an environment variable with the default location of the Django manage.py file
ENV DJANGO_MANAGE_PATH="/code/manage.py"

# Add an alias for the shell_plus command
RUN echo 'alias shell_plus="python $DJANGO_MANAGE_PATH shell_plus --ipython"' >> ~/.bashrc

RUN apt-get update -y
RUN apt-get install -y iputils-ping