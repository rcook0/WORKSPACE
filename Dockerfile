# WORKSPACE image inherits from dev-stack base
FROM dev-stack:latest

# Labels for clarity
LABEL maintainer="you@example.com"
LABEL description="WORKSPACE meta-repo image extending dev-stack"

# Optional: install additional global tools
# (example: curl, jq, gh CLI if not in base)
RUN apt-get update && apt-get install -y \
    curl jq git-lfs \
 && rm -rf /var/lib/apt/lists/*

# Workspace environment variables
ENV WORKSPACE_HOME=/workspace
WORKDIR $WORKSPACE_HOME

# Default entrypoint keeps container interactive
CMD [ "bash" ]
