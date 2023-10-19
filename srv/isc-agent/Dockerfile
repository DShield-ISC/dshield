FROM python:3.9

ENV PYTHONUNBUFFERED 1

WORKDIR /opt/sans-isc-agent

COPY . .

SHELL [ "/bin/bash", "-c"]

RUN apt-get update \
    && pip install --upgrade pip \
    && pip install -U poetry  \
    && poetry install --no-root \
    && echo "Done"

EXPOSE 8000
EXPOSE 8080
EXPOSE 8443
EXPOSE 3000

CMD ["poetry", "run", "python", "isc-agent.py"]
