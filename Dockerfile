# Instructions about Dockerfile
# Dockerfile for Angular for production. We use Nginx for production
# ng serve → Starts the Angular development server.
# --host 0.0.0.0 → Allows the server to be accessible from outside the container.

# Use DOCKER_BUILDKIT to improve docker images performace and reduce size of the image (new to market)
# DOCKER_BUILDKIT=1 docker build \
#   --build-arg ENVIRONMENT=production \
#   --platform=linux/amd64 \
#   -t angular-app .

# docker run -p 80:80 angular-app



# syntax=docker/dockerfile:1.4

##############################
# Builder Stage
##############################
FROM --platform=$BUILDPLATFORM node:18-alpine AS builder

ARG ENVIRONMENT=production
ENV ENVIRONMENT=$ENVIRONMENT

WORKDIR /app

# Copy dependency manifests first for better caching
COPY package*.json ./

# Install dependencies (only production for build)
RUN npm install 

# Copy rest of the project files
COPY . .

# Install Angular CLI for build
RUN npm install -g @angular/cli@13.3.9

# Build the Angular app with production configuration
RUN ng build --configuration=$ENVIRONMENT

##############################
# Development Environment Stage
##############################
FROM node:18-alpine AS dev-envs

WORKDIR /app

# Copy project for development
COPY . .

# Install all dependencies (dev + prod)
RUN npm ci

# Install Angular CLI globally
RUN npm install -g @angular/cli@13

# Install necessary dev tools
# RUN apk add --no-cache git docker-cli docker-cli-compose
RUN apk add --no-cache git 

# Create vscode user and add to docker group
RUN addgroup -S docker && \
    adduser -S vscode -G docker && \
    chown -R vscode /app

USER vscode

CMD ["ng", "serve", "--host", "0.0.0.0"]

##############################
# Production Stage
##############################
FROM nginx:alpine AS production

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built Angular app from builder
COPY --from=builder /app/dist/angular /usr/share/nginx/html/

# Expose NGINX port
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

