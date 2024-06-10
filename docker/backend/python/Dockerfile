FROM python:3-slim

WORKDIR /app
COPY ./app/requirements.txt /
RUN pip install -r /requirements.txt \
  && opentelemetry-bootstrap --action=install

EXPOSE 5002

CMD ["opentelemetry-instrument", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5002", "--reload", "--log-config", "./logger_config.yaml"]
