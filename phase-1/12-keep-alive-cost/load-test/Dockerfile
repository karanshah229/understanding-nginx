FROM node:24-alpine

RUN npm install -g autocannon

# Use a wait-for-it or simple sleep to ensure NGINX is ready
CMD ["sh", "-c", "sleep 5 && autocannon -c 12500 -r 10 -d 3600 --forever http://nginx:8080/"]
