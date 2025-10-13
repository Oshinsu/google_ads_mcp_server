FROM python:3.12-slim

WORKDIR /app
COPY . .
RUN pip install --upgrade pip && pip install uv fastapi google-ads

EXPOSE 8080
CMD ["uv", "run", "-m", "ads_mcp.server"]
