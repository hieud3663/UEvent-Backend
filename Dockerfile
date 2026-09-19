FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libpq-dev netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY . /app

# OpenShift commonly runs containers with an arbitrary UID.
# Make application-owned paths writable by the root group, which OpenShift
# assigns to the runtime user.
RUN sed -i 's/\r$//' /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh \
    && mkdir -p /app/logs \
    && chgrp -R 0 /app \
    && chmod -R g=u /app

EXPOSE 8000

CMD ["/bin/sh", "/app/entrypoint.sh"]
