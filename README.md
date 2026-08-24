# ACC Android Builder

Local Android APK build fallback for ACC projects. GitHub stores the source; the Android phone performs the build locally in Termux, so this path does not depend on GitHub-hosted Actions minutes.

## First setup on the builder phone

Install Termux, then in Termux run:

```bash
pkg update -y && pkg install -y git
git clone https://github.com/balinightlife666-web/ACC-Android-Builder.git ~/acc-builder
chmod +x ~/acc-builder/*.sh
~/acc-builder/setup-termux.sh
source ~/acc-builder/env.sh
~/acc-builder/doctor.sh
```

For this private repository, Git authentication must be configured on the phone before cloning/pulling.

## Add a project

```bash
~/acc-builder/builder.sh add content-hub https://github.com/OWNER/REPO.git main
```

## Build

```bash
~/acc-builder/builder.sh build content-hub
```

The builder automatically pulls the latest source, runs Node/Capacitor steps when detected, runs Gradle `assembleDebug`, and copies generated APK files to:

```text
~/acc-builder/output/
```

Logs are stored in:

```text
~/acc-builder/logs/
```

## Important

Android projects are not identical. Termux runs on the phone's ARM architecture, while some Android Gradle plugins/dependencies ship host tools that expect desktop Linux. `doctor.sh` checks the core toolchain, but each target project still needs one real test build before it can be marked compatible with this phone.

No GitHub Actions workflow is included intentionally. This repository is the local-build fallback.
