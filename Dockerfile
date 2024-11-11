FROM ghcr.io/open-webui/open-webui:git-7228b39

WORKDIR /app

USER 0:0

# Create a new user with UID 10014 for Choreo compliance
RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

RUN pip install "litellm[proxy]==1.51.2" && chown -R 10014:10014 /app

USER 10014:10014

COPY ./azure-models.txt /assets/azure-models.txt
COPY ./start.sh /start.sh
CMD [ "bash", "/start.sh" ]
