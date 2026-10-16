# Contributing to Stand Up

Thanks for helping improve Stand Up. The project is a SwiftPM macOS app and targets macOS 14 or later.

## Local development

```sh
swift test
./script/build_and_run.sh --dev
```

The development mode uses a 45-second work interval, a 15-second standing interval, and a five-second idle threshold. It stores test data under a separate UserDefaults prefix.

## Changes

Keep timer behavior in `Core/` and platform integration in `Sources/StandUp/Services/`. Add a focused regression test for changes to timer transitions, sleep/wake handling, or habit calculations. Keep product data local and avoid adding network services or analytics without a design discussion.

## Pull requests

Describe the user-facing behavior, the macOS version tested, and the commands you ran. Do not include personal activity data, build products, signing certificates, or provisioning profiles.
