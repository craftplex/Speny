<p align="center">
  <img src="assets/speny-banner.gif" alt="Speny — spend with clarity" width="100%">
</p>

<h1 align="center">Speny</h1>

<p align="center">
  A calmer way to track everyday spending, plan a budget, and understand your money.
</p>

<p align="center">
  <a href="https://github.com/craftplex/Speny/releases/latest/download/Speny-Android.apk">
    <img src="https://img.shields.io/badge/Download-Android%20APK-087F5B?style=for-the-badge&logo=android&logoColor=white" alt="Download the latest Android APK">
  </a>
</p>

<p align="center">
  <a href="https://github.com/craftplex/Speny/actions/workflows/build_release.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/craftplex/Speny/build_release.yml?branch=main&label=Android%20build&logo=githubactions&logoColor=white" alt="Android build status">
  </a>
  <a href="https://github.com/craftplex/Speny/releases">
    <img src="https://img.shields.io/github/downloads/craftplex/Speny/total?label=downloads&logo=android" alt="GitHub release downloads">
  </a>
</p>

## Money, made clearer

Speny is a simple Android expense tracker built with Flutter. Log a purchase in seconds, see how it fits your monthly plan, and use straightforward reports to spot spending patterns.

## At a glance

| Track | Plan | Understand |
| --- | --- | --- |
| Add expenses with categories, dates, and merchants | Set a monthly spending limit | Review category totals and spending trends |
| Mark spending as a need or a want | Keep recurring bills in view | Compare needs and wants, and find your largest expenses |
| Create your own categories | Preview how a purchase affects your budget | Export reports as PDF or CSV |

### A more thoughtful experience

- **A focused dashboard** for this month’s spending, budget progress, and recent activity.
- **Useful insights** that summarize spending patterns without getting in the way.
- **A purchase simulator** to estimate how a planned expense could affect your remaining budget.
- **Local-first data**: expense records are stored on your device.
- **A clean, emerald-accented interface** designed to keep everyday money tasks easy to scan.

## Download

Download the latest Android APK from [GitHub Releases](https://github.com/craftplex/Speny/releases/latest). Your Android device may ask you to allow installation from the browser or file manager used for the download.

## Run locally

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install), then clone and run the app:

```bash
git clone https://github.com/craftplex/Speny.git
cd Speny
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

## Automated builds

GitHub Actions runs tests and builds an APK for pull requests. Successful pushes to `main` or `master`, and version tags such as `v1.0.0`, publish `Speny-Android.apk` to GitHub Releases. Release APKs are signed with the repository’s configured Android signing key.

## Built with

[Flutter](https://flutter.dev/) · [Dart](https://dart.dev/) · SQLite

## License

See [LICENSE](LICENSE).
