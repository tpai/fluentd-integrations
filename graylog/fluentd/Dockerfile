FROM fluent/fluentd:v1.19-2
USER root
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd && rm -rf /var/lib/apt/lists/*
USER fluent
