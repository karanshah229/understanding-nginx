FROM node:alpine

# Pre-install autocannon for zero-delay scaling
RUN npm install -g autocannon

# Set entrypoint to autocannon to behave as a dedicated load generator cli
ENTRYPOINT ["autocannon"]
