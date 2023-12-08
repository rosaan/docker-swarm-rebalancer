# Use a stable base image
FROM debian:bullseye-slim

# Install Docker CLI
RUN apt-get update && apt-get install -y \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m dockeruser
USER dockeruser

# Copy the rebalancing script into the image
COPY --chown=dockeruser:dockeruser rebalancer.sh /home/dockeruser/rebalancer.sh
RUN chmod +x /home/dockeruser/rebalancer.sh

# Set environment variables
ENV CHECK_INTERVAL=60
ENV LOG_LEVEL=info

# Health check (customize as needed)
HEALTHCHECK --interval=60s --timeout=15s --retries=3 \
  CMD [ "/home/dockeruser/rebalancer.sh", "check_health" ] || exit 1

# Run the script
CMD ["/home/dockeruser/rebalancer.sh"]