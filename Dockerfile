FROM python:3.7.12-slim-bullseye

WORKDIR /srv

COPY . /srv/dshield

RUN apt-get update \
    && apt-get -y install npm nodejs \
    && pip install --upgrade pip \
    && pip install pipenv \
    && pipenv sync --dev --system

CMD ["sh", "-c", "python main.py"]
