# Use a more recent Flutter image with Dart 3.x
FROM cirrusci/flutter:3.16.0 as builder

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Enable flutter web and upgrade Flutter
RUN flutter config --enable-web
RUN flutter upgrade
RUN flutter --version

# Get dependencies
RUN flutter pub get

# Copy source code
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
