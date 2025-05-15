# Build stage
FROM python:3.12-slim-bullseye AS builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install --no-cache-dir poetry==1.8.3

# Copy files
COPY ./pyproject.toml ./poetry.lock* ./README.md /app/
COPY ./graphiti_core /app/graphiti_core
COPY ./server/pyproject.toml ./server/poetry.lock* /app/server/

RUN poetry config virtualenvs.create false

# Install package
RUN poetry build && pip install dist/*.whl

# Install server dependencies
WORKDIR /app/server
RUN poetry install --no-interaction --no-ansi --only main --no-root

# Final stage
FROM python:3.12-slim-bullseye

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgcc1 \
    && rm -rf /var/lib/apt/lists/*

# Copy from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy server files
WORKDIR /app
COPY ./server /app

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

# Run application
CMD ["uvicorn", "graph_service.main:app", "--host", "0.0.0.0", "--port", "$PORT"]
