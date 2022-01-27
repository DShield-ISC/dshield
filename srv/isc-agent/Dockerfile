FROM python:3.7.12-slim-bullseye

WORKDIR /opt/sans-isc-agent

COPY . /opt/sans-isc-agent

RUN apt-get update \
    && pip install --upgrade pip \
    && pip install pipenv \
    && pipenv sync --dev --system

CMD ["sh", "-c", "python main.py"]
