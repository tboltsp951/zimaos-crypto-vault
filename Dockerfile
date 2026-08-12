FROM node:20-alpine

WORKDIR /srv
COPY app ./app

EXPOSE 8080
VOLUME /data

USER root

ENV DATA_DIR=/data
ENV PORT=8080

CMD ["node", "app/server.js"]
