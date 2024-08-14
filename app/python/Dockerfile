FROM python:3.8-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt
RUN opentelemetry-bootstrap --action=install

EXPOSE 5002

COPY app.py .

# この指定方法だとうまくいかない
# CMD ["opentelemetry-instrument", "flask", "run", "--host", "0.0.0.0", "--port", "5002", "--debug"]

CMD ["opentelemetry-instrument", "python", "./app.py"]
