![](https://haxe.org/img/branding/haxe-logo-outline-orange.png)

Before doing anything else, install [`Haxe 4.3.7`](https://haxe.org/download/version/4.3.7/) and [`git-scm`](https://git-scm.com/downloads).

> [!NOTE]
> Linux and macOS builds should work, but haven't been played much! <br>
> So if something goes wrong, report it in the [issues](https://github.com/JoaTH-Team/JTA/issues) tab!

> [!IMPORTANT]
> Run every command below from inside the `JTA` folder. The libraries are installed into that folder, so commands run anywhere else won't find them.

## Setup (all platforms)
Do these once, after setting up your platform below (C++ tools, Android SDK, etc.).

1. Install the libraries:
    ```bash
    haxe -cp ./actions/libs-installer -D analyzer-optimize -main Main --interp
    ```
2. Install the game's version of `hxcpp` and build its tools:
    ```bash
    haxelib git hxcpp https://github.com/Joalor64/hxcpp.git --quiet
    haxelib run lime rebuild hxcpp
    ```
    * This one takes a while.
3. **Desktop only** (Windows, Linux, macOS): rebuild the video extension for your platform. Use `windows`, `linux` or `mac`:
    ```bash
    haxelib run lime rebuild extension-webm windows
    ```

You can run `haxelib run lime setup` to make the `lime` command global, so you can type `lime test windows` instead of `haxelib run lime test windows`.

## Windows
1. Download [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe).
2. Wait for the Visual Studio Installer to install.
3. On the Visual Studio installation screen, go to "Individual Components" and select the following:
    * MSVC v143 VS 2022 C++ x64/x86 build tools
    * Windows 10 or Windows 11 SDK
4. Once the details are correct, press "Install".
    * ⚠ This will require 4-5GB of available space on your computer.
5. Once the installation is done, close the Visual Studio Installer.
6. Open a `Command Prompt/Powershell` window in the `JTA` folder, and do the [Setup](#setup-all-platforms) steps.
7. Run `haxelib run lime test windows` to build and launch the game.

## Linux
1. Install the C++ compiler and multilib packages:
    ```bash
    sudo apt-get update && sudo apt-get install -y gcc-multilib g++-multilib
    ```
    * This is for Debian/Ubuntu-based distros. On other distros, install `gcc`, `g++` and their multilib packages with your package manager.
2. Open a `Terminal` window in the `JTA` folder, and do the [Setup](#setup-all-platforms) steps (use `linux` in step 3).
3. Run `haxelib run lime test linux` to build and launch the game.

## macOS
1. Install [`Xcode`](https://developer.apple.com/documentation/xcode) to allow C++ app building.
2. Open a `Terminal` window in the `JTA` folder, and do the [Setup](#setup-all-platforms) steps (use `mac` in step 3).
3. **Apple Silicon Macs (M1 and newer) only:** the video extension is built under the wrong name for ARM, so copy it to the name the game looks for:
    ```bash
    WEBM=$(haxelib libpath extension-webm)
    mkdir -p "$WEBM/ndll/MacArm64"
    if [ -f "$WEBM/ndll/MacArm64/extension-webm-64.ndll" ]; then
      cp "$WEBM/ndll/MacArm64/extension-webm-64.ndll" "$WEBM/ndll/MacArm64/extension-webm.ndll"
    elif [ -f "$WEBM/ndll/Mac64/extension-webm.ndll" ]; then
      cp "$WEBM/ndll/Mac64/extension-webm.ndll" "$WEBM/ndll/MacArm64/extension-webm.ndll"
    fi
    ```
4. Run `haxelib run lime test mac` to build and launch the game.

## HTML5
1. Do the [Setup](#setup-all-platforms) steps 1 and 2 (step 3 isn't needed).
2. Run `haxelib run lime test html5` to build the game and open it in your browser.

## Android
1. Install [`Android Studio`](https://developer.android.com/studio), or just the Android command-line tools.
2. In Android Studio's SDK Manager, install:
    * Android SDK Platform-Tools and Build-Tools
    * **NDK version r21e** (`21.4.7075529`). That's the version the automatic builds use, so it's the safest one.
3. Install [`JDK 17`](https://www.azul.com/downloads/?version=java-17-lts&package=jdk) (any JDK 17 works).
4. Do the [Setup](#setup-all-platforms) steps 1 and 2 (step 3 isn't needed).
5. Tell Lime where everything is (replace the paths with your own):
    ```bash
    haxelib run lime config ANDROID_SDK /path/to/Android/Sdk
    haxelib run lime config ANDROID_NDK_ROOT /path/to/Android/Sdk/ndk/21.4.7075529
    haxelib run lime config JAVA_HOME /path/to/jdk-17
    haxelib run lime config ANDROID_SETUP true
    ```
    * You can also run `haxelib run lime setup android` and answer its questions instead.
6. Connect your phone with USB debugging on, and run `haxelib run lime test android` to build, install and launch the game.
    * To only build the APK, use `haxelib run lime build android`. It ends up in `export/release/android/bin/app/build/outputs/apk/`.

## Debug builds
Add `-debug` to any build command (e.g. `haxelib run lime test windows -debug`) for a build with the debugger and extra error info. Debug builds go in `export/debug/` instead of `export/release/`.