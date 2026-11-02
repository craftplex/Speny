# Speny

Speny is a Flutter expense tracker for Android.

## Android APK download

The latest APK is published automatically after a successful push to `main` or `master`, or after pushing a version tag such as `v1.0.0`:

[Download the latest Speny Android APK](https://github.com/craftplex/Speny/releases/latest/download/Speny-Android.apk)

Each GitHub Release contains only `Speny-Android.apk`. Pull requests and other configured branches run the tests and build an APK artifact, but do not publish a Release. A Release build requires all four Android signing secrets below; if any are missing, the workflow stops rather than publishing an APK signed with a temporary key.

## GitHub Actions signing secrets setup

You create the Android signing key yourself; GitHub does not provide it, and you do not need to buy a signing key. Generate it once, keep a secure backup, and keep using the same key for every update. If you lose or replace it, Android will not install the new APK as an update over the old one.

### 1. Create a keystore on Windows

Install a JDK (Java Development Kit) if you do not already have one; for example, download an OpenJDK build from [Eclipse Adoptium](https://adoptium.net/temurin/releases/). Open PowerShell in a folder outside the repository where you want to keep the key, then run:

```powershell
keytool -genkeypair -v -keystore speny-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias speny-upload
```

`keytool` will ask you to create a keystore password and enter certificate details. Remember the password you choose. If it asks for a separate key password, you can enter the same password. For the certificate identity prompts, enter your own details; they are not the GitHub secrets.

Keep `speny-upload-key.jks`, the keystore password, and the key password in a secure place with a backup. **Do not commit or upload the `.jks` file to this repository.** The alias from the command above is `speny-upload`.

### 2. Convert the keystore to Base64

In the same PowerShell window and folder, run:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\speny-upload-key.jks")) | Set-Clipboard
```

This copies the one-line Base64 text for the file to your clipboard. Do not paste the Base64 into a source file or a public issue.

### 3. Add four repository secrets

On GitHub, open the **craftplex/Speny** repository, then go to **Settings → Secrets and variables → Actions → New repository secret**. Add each secret separately using the exact name below. When adding `ANDROID_KEYSTORE_BASE64`, paste the clipboard text from step 2 into its value field; paste each other value into the matching secret:

| Secret name | Value to enter |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | The Base64 text currently in your clipboard from step 2 |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore password you created in step 1 |
| `ANDROID_KEY_ALIAS` | `speny-upload` |
| `ANDROID_KEY_PASSWORD` | The key password from step 1 (same as the keystore password if you chose that) |

If you copied anything else after step 2, rerun that command before adding `ANDROID_KEYSTORE_BASE64`. Secret names are case-sensitive. Do not add quotes around the values.

### 4. Check the first release

Push a commit to `main` (or `master`) after all four secrets have been saved. In the repository's **Actions** tab, open the **Build and release Android APK** run and wait for it to succeed. The **Releases** page will then contain the `Speny-Android.apk` download. For a version-numbered release, push a tag such as `v1.0.0` instead.

The same keystore must be used for every GitHub APK that users install as an update. If you also distribute through Google Play, enable **Play App Signing** in Play Console and follow Google's upload-key setup. Play-distributed APKs and GitHub APKs may be signed with different keys, so users may need to uninstall one distribution before installing the other; back up this keystore and do not casually replace it. A GitHub-downloaded APK may require Android's permission to install apps from that browser or file manager.
