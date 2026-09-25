![](https://haxe.org/img/branding/haxe-logo-outline-orange.png)

Before doing anything else, make sure to install [Haxe](https://haxe.org/download/) and [HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/).

> [!NOTE]
> Linux and macOS builds should work, but have not been tested! <br>
> So if something goes wrong, report it in the [issues](https://github.com/JoaTH-Team/JTA/issues) tab!

## Windows
1. Download [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe).
2. Wait for the Visual Studio Installer to install.
3. On the Visual Studio installation screen, go to "Individual Components" and select the following:
    * MSVC v143 VS 2022 C++ x64/x86 build tools
    * Windows 10 or Windows 11 SDK
4. Once the details are correct, press "Install".
    * ⚠ This will require 4-5GB of available space on your computer.
5. Download and install [Git](https://git-scm.com/downloads/win).
    * Leave all installation options as default.
6. Open a `Command Prompt/Powershell` window in the `JTA` folder, and run the following command to install the dependencies:
    ```bat
    haxe -cp ./actions/libs-installer -D analyzer-optimize -main Main --interp
    ```
7. Run `haxelib run lime test windows` to build and launch the game.
    * You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test windows` directly.

## Linux
1. Install `g++`.
2. Download and install [Git](https://git-scm.com/downloads/linux).
3. Open a `Terminal` window in the `JTA` folder, and run the following command to install the dependencies:
    ```bash
    haxe -cp ./actions/libs-installer -D analyzer-optimize -main Main --interp
    ```
4. Run `haxelib run lime test linux` to build and launch the game.
    * You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test linux` directly.

## macOS
1. Install [`Xcode`](https://developer.apple.com/documentation/xcode) to allow C++ app building.
2. Download and install [Git](https://git-scm.com/downloads/mac).
3. Open a `Terminal` window in the `JTA` folder, and run the following command to install the dependencies:
    ```bash
    haxe -cp ./actions/libs-installer -D analyzer-optimize -main Main --interp
    ```
4. Run `haxelib run lime test mac` to build and launch the game.
    * You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test mac` directly.