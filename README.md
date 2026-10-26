# Docker image for [Flutter](https://flutter.dev/)

[![Build and push](https://github.com/kwop/docker-flutter/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/kwop/docker-flutter/actions/workflows/build-and-push.yml)
[![Check Flutter version](https://github.com/kwop/docker-flutter/actions/workflows/check-flutter-version.yml/badge.svg)](https://github.com/kwop/docker-flutter/actions/workflows/check-flutter-version.yml)

Flutter SDK and Android SDK in one image, for CI and local builds. Successor of
[`cirruslabs/docker-images-flutter`](https://github.com/cirruslabs/docker-images-flutter),
which stopped updating in May 2026.

Docker Hub: [`kwop/flutter`](https://hub.docker.com/r/kwop/flutter)

## Usage

```bash
docker run --rm -it -v "${PWD}:/build" --workdir /build kwop/flutter:stable flutter test
```

To move from the Cirrus image, replace `ghcr.io/cirruslabs/flutter` with `kwop/flutter`.
Paths and environment variables are unchanged (`FLUTTER_HOME=/sdks/flutter`,
`ANDROID_HOME=/opt/android-sdk-linux`).

## Tags

| Tag                       | Content                                     |
| ------------------------- | ------------------------------------------- |
| `stable`, `latest`        | latest Flutter stable release               |
| `<version>` (`3.47.8`, …) | that Flutter release                        |

Only the stable channel is published. Images are built for `linux/amd64` and `linux/arm64`.

> [!NOTE]
> Google ships `adb` and the AAPT2 binary that Gradle downloads for x86-64 Linux only.
> The arm64 image runs `flutter test`, `flutter analyze` and web builds, but Android
> builds (`flutter build apk`/`appbundle`) need the amd64 image. On Apple Silicon, use
> `--platform linux/amd64`.

A new Flutter stable release is published within the hour. The current version is
also rebuilt every Monday to pick up Ubuntu security updates, so a version tag can
point to a newer digest over time. Pin by digest (`kwop/flutter@sha256:…`) for
fully reproducible builds.

Each image carries an SBOM and a provenance attestation:

```bash
docker buildx imagetools inspect kwop/flutter:stable --format '{{ json .SBOM }}'
```

## What's in the image

- Ubuntu 24.04, OpenJDK 21 (headless)
- Android SDK: command-line tools, platform-tools, platform 36, build-tools 36.0.0
- Flutter SDK in `/sdks/flutter`, with `flutter precache --android` already run
- Build tooling: git, curl, wget, zip/unzip, jq, build-essential, ruby + bundler (fastlane), lcov, sqlite3

### Differences from the Cirrus image

- No Android emulator, and none of its X11/audio libraries. It could not run without KVM anyway.
- No `lftp`, `software-properties-common` or `android-wait-for-emulator`.
- No global git identity (`Cirrus CI <support@cirruslabs.org>`). Set your own if your CI commits.
- OS packages are upgraded at every build instead of being frozen in a base image.

## How it works

| Workflow | Trigger | Does |
| --- | --- | --- |
| [`check-flutter-version.yml`](.github/workflows/check-flutter-version.yml) | every hour | Writes the current stable release to [`FLUTTER_VERSION`](FLUTTER_VERSION). If it changed, commits it and runs the build. |
| [`build-and-push.yml`](.github/workflows/build-and-push.yml) | push to `FLUTTER_VERSION`/`Dockerfile`, Monday 05:00 UTC, manual | Builds amd64 and arm64 on native runners, then pushes the multi-arch manifest to Docker Hub. |

To pin a version, edit `FLUTTER_VERSION` and push to `main`. The next hourly check
moves it back to the latest stable release.

Setup: the repository secret `DOCKERHUB_TOKEN` holds a Docker Hub personal access
token with *Read & Write* scope for `kwop`.

Build locally:

```bash
docker build --build-arg flutter_version="$(cat FLUTTER_VERSION)" -t kwop/flutter:dev .
```

## License

[MIT](LICENSE). Based on the work of Cirrus Labs
([docker-images-flutter](https://github.com/cirruslabs/docker-images-flutter),
[docker-images-android](https://github.com/cirruslabs/docker-images-android)) and
[Adrian Jagielak](https://github.com/adrianjagielak/docker-images-flutter).
