# dockerfile for web.py honeypot
FROM python:2-onbuild
# no dependencies at this time
# Install app dependencies
MAINTAINER Weeks, Michael "mweeks9989@gmail.com"
COPY . /app
WORKDIR /app/bin
COPY signatures.xml /app/signatures.xml
EXPOSE 8080
ENTRYPOINT ["python"]
CMD ["./web.py"]
