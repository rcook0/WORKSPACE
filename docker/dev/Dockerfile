# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04 AS dev

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=dev
ARG UID=1000
ARG GID=1000

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    VENV_PATH=/opt/venv \
    PATH=/opt/venv/bin:$PATH \
    TZ=UTC

# Core toolchain + headers needed for TA-Lib, pygraphviz, etc.
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git git-lfs unzip zip pkg-config \
    build-essential cmake ninja-build clang lldb gdb ccache \
    autoconf automake libtool \
    python3 python3-dev python3-venv python3-pip \
    gfortran libatlas-base-dev libopenblas-dev liblapack-dev \
    openjdk-17-jdk maven gradle \
    nodejs npm \
    sqlite3 postgresql-client \
    graphviz libgraphviz-dev \
    verilator gtkwave yosys iverilog \
    tmux htop ncdu iftop \
    && rm -rf /var/lib/apt/lists/*

# JS tooling + Mermaid CLI
RUN npm install -g yarn @mermaid-js/mermaid-cli --legacy-peer-deps

# TA-Lib C library (0.6.4)
RUN curl -fsSL https://github.com/TA-Lib/ta-lib/releases/download/v0.6.4/ta-lib-0.6.4-src.tar.gz \
    -o /tmp/ta-lib.tar.gz \
 && tar -xzf /tmp/ta-lib.tar.gz -C /tmp \
 && cd /tmp/ta-lib-0.6.4 \
 && ./configure --prefix=/usr \
 && make -j"$(nproc)" \
 && make install \
 && rm -rf /tmp/ta-lib*

# Non-root user
RUN groupadd -g "$GID" "$USER" \
 && useradd -m -u "$UID" -g "$GID" -s /bin/bash "$USER"

# Python venv + packages
RUN python3 -m venv "$VENV_PATH" \
 && "$VENV_PATH/bin/pip" install --upgrade pip \
 && "$VENV_PATH/bin/pip" install \
    numpy pandas matplotlib scipy scikit-learn statsmodels sympy \
    TA-Lib pandas-ta-classic \
    ccxt zipline-reloaded \
    psycopg2-binary sqlalchemy plotly seaborn pygraphviz \
    jupyterlab ipywidgets ipykernel ipython jupyter_contrib_nbextensions

# Register default kernel so Jupyter/VS Code see it by name
RUN python -m ipykernel install --prefix=/usr/local --name=py311 --display-name="Python (venv)"

USER $USER
WORKDIR /workspace

# Devcontainer friendliness
RUN git config --global --add safe.directory /workspace || true

CMD ["bash"]
