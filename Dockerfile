FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FASTMCP_HOST=0.0.0.0 \
    PORT=8080

WORKDIR /app
COPY . .

RUN pip install --upgrade pip uv
RUN uv pip install --system -e .
RUN uv pip install --system --upgrade "google-ads>=28.0.0"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
