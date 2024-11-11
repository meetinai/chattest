# Use the existing base image
FROM ghcr.io/open-webui/open-webui:git-7228b39

# Set the working directory
WORKDIR /app

# Create a new user and group with specific UID and GID
RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

# Switch to the root user to perform privileged operations
USER 0:0

# Install the required Python package and set ownership
RUN pip install "litellm[proxy]==1.51.2" && \
    chown -R 10014:10014 /app

# Switch to the newly created user
USER 10014:10014

# Copy the necessary files
COPY ./azure-models.txt /assets/azure-models.txt
COPY ./start.sh /start.sh

# Set the command to run the application
CMD [ "bash", "/start.sh" ]
