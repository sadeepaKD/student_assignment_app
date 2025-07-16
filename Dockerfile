# Use a minimal base image
FROM debian:bullseye-slim as builder

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and install Flutter
RUN curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz | tar -xJ -C /opt/
ENV PATH="/opt/flutter/bin:${PATH}"

# Verify Flutter installation
RUN flutter --version
RUN flutter config --enable-web
RUN flutter doctor

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build web app
RUN flutter build web --release

# Production stage with nginx
FROM nginx:alpine

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
