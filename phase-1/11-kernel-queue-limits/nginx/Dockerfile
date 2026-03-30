FROM nginx:latest
RUN apt-get update && apt-get install -y iproute2 net-tools && rm -rf /var/lib/apt/lists/*
COPY nginx.conf /etc/nginx/nginx.conf
