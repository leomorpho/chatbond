FROM python:3.8-slim-bullseye AS python-base

#------------------------
FROM python-base AS builder

ARG BUILD_ENVIRONMENT=production

ENV ANNOY_COMPILER_ARGS -D_CRT_SECURE_NO_WARNINGS,-DANNOYLIB_MULTITHREADED_BUILD,-mtune=native

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

# Install git temporarily for the builder stage
RUN apt-get update && \
    apt-get install -y git build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --force-reinstall "poetry==$POETRY_VERSION"

ENV ANNOY_COMPILER_ARGS -D_CRT_SECURE_NO_WARNINGS,-DANNOYLIB_MULTITHREADED_BUILD,-mtune=native
RUN python -m pip install git+https://github.com/spotify/annoy.git 

# TODO: Create a non-root user and switch to it
# RUN adduser --disabled-password --gecos '' --uid 1000 myuser
# USER myuser

WORKDIR /code

# Generate requirements and install *all* dependencies.
COPY pyproject.toml poetry.lock /code/

RUN poetry export --without-hashes --output=requirements.txt

RUN --mount=type=cache,target=/root/.cache \
    python3 -m pip install --prefix=/runtime --no-deps --no-cache-dir --force-reinstall -r requirements.txt

# Remove git as it's no longer needed and clean up cache and temp files
RUN apt-get remove -y git build-essential && \
    apt-get autoremove -y && \
    apt-get clean

#------------------------
FROM python-base AS runtime

# Copy runtime dependencies
COPY --from=builder /runtime /usr/local

# Copy project files
RUN mkdir -p /code/chatbond
COPY chatbond /code/chatbond/
COPY wait_for_dependencies.py /code
COPY manage.py /code

WORKDIR /code

# Create logs directory
RUN mkdir -p /code/logs
# RUN chmod 755 /code/logs
