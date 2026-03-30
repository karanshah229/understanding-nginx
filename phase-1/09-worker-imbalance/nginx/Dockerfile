FROM nginx:latest

# Install procps (gives us 'top') for monitoring worker-level metrics
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
