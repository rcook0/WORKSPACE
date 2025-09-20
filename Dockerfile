# WORKSPACE image inherits from dev-stack base
FROM dev-stack:latest

# Labels for clarity
LABEL maintainer="rcook0"
LABEL description="WORKSPACE meta-repo image extending dev-stack with auto repo loader"

# Optional: install additional global tools
# (example: curl, jq, gh CLI if not in base)
#RUN apt-get update && apt-get install -y \
#    curl jq git-lfs \
# && rm -rf /var/lib/apt/lists/*

# Workspace environment variables
ENV WORKSPACE_HOME=/workspace
WORKDIR $WORKSPACE_HOME

# Add repo sync + backup helper
COPY clone.sh /usr/local/bin/clone.sh
RUN chmod +x /usr/local/bin/clone.sh

# Default entrypoint keeps container interactive
CMD [ "bash" ]
