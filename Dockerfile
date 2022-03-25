ARG HYRAX_IMAGE_VERSION=3.1.0
FROM ghcr.io/samvera/hyku/hyku-base:$HYRAX_IMAGE_VERSION as hyku-base

USER root

ARG EXTRA_APK_PACKAGES="openjdk11-jre ffmpeg pkg-config yarn rbspy"
RUN apk --no-cache upgrade && \
  apk --no-cache add \
    curl \
    curl-dev \
    libcurl \
    libxml2-dev \
    mariadb-dev \
    mediainfo \
    openssh \
    perl \
    cmake \
    cargo \
    $EXTRA_APK_PACKAGES && \
    cargo install rbspy

USER app

RUN mkdir -p /app/fits && \
    cd /app/fits && \
    wget https://github.com/harvard-lts/fits/releases/download/1.5.0/fits-1.5.0.zip -O fits.zip && \
    unzip fits.zip && \
    rm fits.zip && \
    chmod a+x /app/fits/fits.sh
ENV PATH="${PATH}:/app/fits"

COPY --chown=1001:101 $APP_PATH/Gemfile* /app/samvera/hyrax-webapp/
RUN bundle install --jobs "$(nproc)"

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp

ARG SETTINGS__BULKRAX__ENABLED="false"
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb bundle exec rake assets:precompile

FROM hyku-base as hyku-worker
ENV MALLOC_ARENA_MAX=2
CMD bundle exec sidekiq