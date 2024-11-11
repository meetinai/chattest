# Use the base image
FROM ghcr.io/open-webui/open-webui:git-7228b39 AS builder

# Set the working directory
WORKDIR /app

# Switch to root user for installation
USER 0:0

# HACK for huggingface.co iframe
RUN sed -i "s|samesite=WEBUI_SESSION_COOKIE_SAME_SITE|samesite='none'|g" backend/open_webui/apps/webui/routers/auths.py

# Install dependencies
RUN pip install "litellm[proxy]==1.51.2" && \
    chown -R 10000:0 /app  # Change ownership to a user with UID 10000

# Create a non-privileged user
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10014 \
    "choreo"

# Switch to non-root user
USER 10014:0  # Adjusted user UID

# Copy necessary files into the container
COPY ./azure-models.txt /assets/azure-models.txt
COPY ./start.sh /start.sh

# Set the command to run the application
CMD [ "bash", "/start.sh" ]
