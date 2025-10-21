# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive
ENV VENV_PATH=/opt/venv \
    PATH=/opt/venv/bin:$PATH \
    TZ=UTC

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      python3 python3-venv python3-pip \
      libatlas-base-dev libopenblas-dev liblapack-dev \
      sqlite3 postgresql-client \
      graphviz \
    && rm -rf /var/lib/apt/lists/*

# Copy venv from dev stage for a lean runtime
COPY --from=dev /opt/venv /opt/venv

WORKDIR /workspaces/WORKSPACE
CMD ["python3"]
