# Android SDK and tablet emulator for the Expo / React Native apps
# (~/codes/recito, ~/codes/booth/kiosk-mobile).
#
# Versions follow the Expo SDK 57 / React Native 0.86 defaults from
# react-native/gradle/libs.versions.toml: compileSdk 36, build-tools 36.0.0,
# NDK 27.1.12297006. CMake 3.22.1 is the AGP default used by expo-modules-core.
# `expo run:android` builds with Gradle, which needs a JDK 17 toolchain
# (react-native-gradle-plugin pins jvmToolchain(17)).
#
# Usage: `android-tablet` starts (and on first run creates) a Pixel Tablet AVD,
# then `pnpm android` / `expo run:android` in the project installs the dev client.
{ pkgs, ... }:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "36" ];
    buildToolsVersions = [ "36.0.0" ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];
    includeNDK = true;
    ndkVersions = [ "27.1.12297006" ];
    cmakeVersions = [ "3.22.1" ];
  };
  androidSdk = androidComposition.androidsdk;
  sdkRoot = "${androidSdk}/libexec/android-sdk";

  avdName = "tablet";
  systemImage = "system-images;android-36;google_apis;x86_64";

  android-tablet = pkgs.writeShellScriptBin "android-tablet" ''
    set -euo pipefail
    export ANDROID_HOME="${sdkRoot}"
    export ANDROID_SDK_ROOT="${sdkRoot}"
    # avdmanager honors XDG_CONFIG_HOME but the emulator does not; pin one place.
    export ANDROID_AVD_HOME="$HOME/.android/avd"

    if ! ${androidSdk}/bin/avdmanager list avd -c 2>/dev/null | grep -qx "${avdName}"; then
      echo "Creating AVD '${avdName}' (Pixel Tablet, Android 36)..."
      echo no | ${androidSdk}/bin/avdmanager create avd \
        --name "${avdName}" \
        --package "${systemImage}" \
        --device "pixel_tablet"
    fi

    exec ${androidSdk}/bin/emulator -avd "${avdName}" -gpu host "$@"
  '';
in
{
  home.packages = [
    androidSdk # adb, emulator, avdmanager, build-tools, NDK
    android-tablet
  ];

  home.sessionVariables = {
    ANDROID_HOME = sdkRoot;
    ANDROID_SDK_ROOT = sdkRoot;
    ANDROID_NDK_ROOT = "${sdkRoot}/ndk/27.1.12297006";
    ANDROID_AVD_HOME = "$HOME/.android/avd";
    # Gradle launcher JDK; PATH keeps the default `jdk` from development.nix.
    JAVA_HOME = "${pkgs.jdk17}";
    # Gradle downloads aapt2 from Maven as a dynamically linked binary that
    # cannot run on NixOS; point it at the patched copy shipped with the SDK.
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdkRoot}/build-tools/36.0.0/aapt2";
  };
}
