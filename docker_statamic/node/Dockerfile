# docker/node/Dockerfile

# Node version that satisfies laravel-vite-plugin
FROM node:25.6.0-alpine

# Pin npm (permanent across rebuilds)
RUN npm i -g npm@11.6.2

# Silence npm’s update notifier
ENV npm_config_update_notifier=false

WORKDIR /var/www/html
