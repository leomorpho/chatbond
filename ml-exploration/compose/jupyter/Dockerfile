FROM python:3.8
ARG BUILD_ENVIRONMENT=local

ENV PYTHONUNBUFFERED 1

# Allows docker to cache installed dependencies between builds
COPY ./requirements.txt requirements.txt
RUN pip install -r requirements.txt

RUN pip install ipdb jupyter

# Adds our application code to the image
ARG APP_HOME=code
COPY . code
WORKDIR ${APP_HOME}

EXPOSE 8888

# Create a new IPython profile and configure it to automatically load the autoreload extension
RUN ipython profile create && echo "c.InteractiveShellApp.exec_lines = ['%load_ext autoreload', '%autoreload 2']" >> ~/.ipython/profile_default/ipython_config.py

# Start the Jupyter server
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
