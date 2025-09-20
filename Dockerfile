# WORKSPACE image inherits from dev-stack base
FROM dev-stack:latest

# Labels for clarity
LABEL maintainer="rcook0"
LABEL description="WORKSPACE meta-repo image extending dev-stack with auto repo loader"

ENV WORKSPACE_HOME=/workspace
WORKDIR $WORKSPACE_HOME

# Optional: install additional global tools
# (example: curl, jq, gh CLI if not in base)
RUN apt-get update && apt-get install -y curl jq git-lfs cron && rm -rf /var/lib/apt/lists/*

# Add repo sync + backup helper
COPY clone.sh /usr/local/bin/clone.sh
RUN chmod +x /usr/local/bin/clone.sh

# Add crontab file
COPY crontab.txt /etc/cron.d/workspace-cron
RUN chmod 0644 /etc/cron.d/workspace-cron \
    && crontab /etc/cron.d/workspace-cron

# Ensure cron logs go to stdout
RUN touch /var/log/cron.log

CMD service cron start && bash
