FROM ghcr.io/open-webui/open-webui:git-7228b39

ENV TRIVY_DISABLE_VEX_NOTICE=true

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

RUN pip install "litellm[proxy]==1.51.2"

# Copy files and set permissions while still root
COPY ./azure-models.txt /assets/azure-models.txt
COPY ./start.sh /start.sh
RUN chown -R choreo:choreo /app /assets/azure-models.txt /start.sh

# Switch to non-root user
USER 10014

CMD [ "bash", "/start.sh" ]
