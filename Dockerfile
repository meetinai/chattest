FROM ghcr.io/open-webui/open-webui:git-7228b39

# Update linux-libc-dev package to fix [CVE-2024-47685](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2024-47685) vulnerability
USER root
RUN apt-get update && \
    apt-get upgrade -y linux-libc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a non-privileged user for Choreo compliance
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10014 \
    "choreo"

RUN pip install "litellm[proxy]==1.51.2"

# Copy files and set permissions while still root
COPY ./azure-models.txt /assets/azure-models.txt
COPY ./start.sh /start.sh
RUN chown -R choreo:choreo /app /assets/azure-models.txt /start.sh

# Switch to non-root user
USER 10014

CMD [ "bash", "/start.sh" ]
