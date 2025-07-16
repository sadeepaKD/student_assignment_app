# Multi-stage build for Flutter web app
FROM cirrusci/flutter:stable as builder

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Enable flutter web
RUN flutter config --enable-web

# Get dependencies
RUN flutter pub get

# Copy source code (excluding bot files)
COPY . .

# Build Flutter web app for production
RUN flutter build web --release --web-renderer html

# Production stage with nginx
FROM nginx:alpine

# Copy built Flutter web app to nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]