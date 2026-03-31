#!/bin/bash

# Create a directory for certificates if it doesn't exist
mkdir -p certs

# Generate a self-signed certificate for localhost
# - nodes: don't encrypt the private key
# - days 365: valid for a year
# - rsa:2048: 2048-bit RSA key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/nginx.key -out certs/nginx.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

echo "Self-signed certificates generated in nginx/certs/"
