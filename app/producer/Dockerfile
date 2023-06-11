FROM envoyproxy/envoy:v1.25.1 AS proxy


FROM python:3.10-slim

WORKDIR /app

COPY --from=proxy /usr/local/bin/envoy ./envoy
COPY service.py service.py
COPY requirements.txt requirements.txt
COPY envoy.yaml /etc/envoy/envoy.yaml

RUN pip install -r requirements.txt
RUN apt-get update &&\
    apt-get install -y dumb-init &&\
    apt autoclean &&\
    apt autoremove

EXPOSE 80 5080
ENTRYPOINT ["dumb-init", "--"]
CMD ["sh", "-c", "/app/envoy -c /etc/envoy/envoy.yaml & python service.py & wait"]