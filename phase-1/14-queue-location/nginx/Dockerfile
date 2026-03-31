FROM nginx:alpine
RUN apk add --no-progress --no-cache iproute2 curl
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 8001 8002 8003
