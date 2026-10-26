FROM ubuntu:24.04

LABEL org.opencontainers.image.source=https://github.com/kwop/docker-flutter \
      org.opencontainers.image.description="Flutter SDK on top of the Android SDK. Successor of cirruslabs/docker-images-flutter." \
      org.opencontainers.image.licenses=MIT

# --- Android SDK (from cirruslabs/docker-images-android) ---

ENV ANDROID_HOME=/opt/android-sdk-linux \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

ENV ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# https://developer.android.com/studio#command-line-tools-only
# Pinned to 22.0: from 23.0 on, sdkmanager wraps an x86-64-only `android`
# binary that fails on linux/arm64.
ENV ANDROID_SDK_TOOLS_VERSION=15859902
# https://developer.android.com/studio/releases/build-tools
ENV ANDROID_PLATFORM_VERSION=36 \
    ANDROID_BUILD_TOOLS_VERSION=36.0.0

RUN set -o xtrace \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bc build-essential ca-certificates curl file git jq lcov libglu1-mesa libsqlite3-dev \
        libstdc++6 locales openjdk-21-jdk-headless openssh-client ruby-bundler ruby-full \
        sqlite3 sudo unzip wget xxd xz-utils zip \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" -O /tmp/android-sdk-tools.zip \
    && mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && unzip -q /tmp/android-sdk-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm /tmp/android-sdk-tools.zip \
    && mkdir -p /root/.android \
    && touch /root/.android/repositories.cfg \
    && yes | sdkmanager --licenses \
    && sdkmanager platform-tools \
        "platforms;android-${ANDROID_PLATFORM_VERSION}" \
        "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

# --- Flutter SDK (from cirruslabs/docker-images-flutter) ---

# The flutter wrapper prints a superuser warning for a root shell. The wrapper
# stays quiet for Docker, for CI, and for a bot. Docker creates /.dockerenv, but
# containerd, Podman and a microVM sandbox do not. The image therefore creates
# the marker file and sets the bot flag.
ENV BOT=true
RUN touch /.dockerenv

ARG flutter_version

ENV FLUTTER_HOME=/sdks/flutter \
    FLUTTER_VERSION=${flutter_version}
ENV FLUTTER_ROOT=${FLUTTER_HOME} \
    PATH=${PATH}:${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin

# safe.directory lets the SDK work when the container runs under another UID.
RUN test -n "${FLUTTER_VERSION}" || { echo "missing --build-arg flutter_version" >&2; exit 1; } \
    && git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && git config --system --add safe.directory "${FLUTTER_HOME}"

RUN yes | flutter doctor --android-licenses \
    && flutter doctor \
    && flutter precache --android
