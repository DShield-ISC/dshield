FROM ubuntu:18.04
WORKDIR /usr/src/dshield
COPY . .
CMD ["bin/install.sh"]
EXPOSE 2223
EXPOSE 2222
EXPOSE 8000

