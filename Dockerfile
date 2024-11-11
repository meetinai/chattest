FROM ghcr.io/open-webui/open-webui:git-7228b39

WORKDIR /app

USER 0:0

# Create a non-privileged user for Choreo compliance
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10014 \
    "choreo"

RUN pip install "litellm[proxy]==1.51.2" && \
    chown -R choreo:choreo /app

# Switch to non-root user
USER 10014

COPY ./azure-models.txt /assets/azure-models.txt
COPY ./start.sh /start.sh

# Set proper permissions for copied files
RUN chown choreo:choreo /assets/azure-models.txt /start.sh

CMD [ "bash", "/start.sh" ]
