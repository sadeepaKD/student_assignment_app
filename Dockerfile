# Use a known working Flutter image
FROM ghcr.io/cirruslabs/flutter:3.16.0 as builder

WORKDIR /app

# Enable web support
RUN flutter config --enable-web
RUN flutter doctor

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build Flutter web app
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
