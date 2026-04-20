FROM cirrusci/flutter:latest
RUN git config --global --add safe.directory /sdks/flutter
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build apk --release
