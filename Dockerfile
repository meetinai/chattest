FROM ghcr.io/open-webui/open-webui:git-7228b39

WORKDIR /app

USER 0:0

RUN pip install "litellm[proxy]==1.51.2" && chown -R 10001:0 /app
USER 10001:0

COPY ./azure-models.txt /assets/azure-models.txt
COPY ./start.sh /start.sh
CMD [ "bash", "/start.sh" ]
