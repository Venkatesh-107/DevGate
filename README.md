# 🚀 DevGate (GeteDiv)

A modern, highly-performant cross-platform application built with Flutter & Dart, integrated with a C++ backend for native and intensive tasks.

## ✨ Features
- **Cross-Platform**: Works seamlessly on Desktop (Windows, Linux, macOS) and Mobile (Android, iOS).
- **Git Integration**: Built-in GitHub Personal Access Token (PAT) support for robust repository management.
- **High Performance**: Leverages C++ and native bindings for core operations.

---

## 💻 Desktop Installation (Windows / Linux / macOS)

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Venkatesh-107/DevGate.git
   cd DevGate
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on Desktop**
   Ensure you have the required desktop development tools installed (e.g., Visual Studio for Windows, Xcode for macOS, CMake/Ninja for Linux).
   ```bash
   flutter run -d windows  # Use linux or macos based on your OS
   ```

4. **Build Release Version**
   ```bash
   flutter build windows   # Use linux or macos based on your OS
   ```

---

## 🔑 How to Add Your GitHub PAT (Personal Access Token)

To enable GitHub integrations within the app, you need to provide a GitHub PAT:

1. Open GitHub and go to **Settings** -> **Developer settings** -> **Personal access tokens** -> **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Give it a descriptive name (e.g., `DevGate App`) and ensure you select the `repo` scope to allow full control of private repositories.
4. Generate the token and **copy it immediately** (it will not be shown again).
5. Open DevGate, navigate to the **Settings** or the **Git Interface**, and paste your PAT in the token field to authenticate.

---

## 📱 Mobile Installation (Android)

You can install DevGate directly on your Android device without needing to build from source:

1. **Download the APK**
   Navigate to the [Releases](https://github.com/Venkatesh-107/DevGate/releases) section of this repository.
   Download the latest `app-release.apk` file to your Android device.

2. **Enable Unknown Sources**
   If this is your first time installing an APK manually, go to your phone's **Settings** -> **Security** (or **Apps**) and enable **Install unknown apps** for your web browser or file manager.

3. **Install the App**
   Open the downloaded `app-release.apk` file and tap **Install**.
   Once installed, you can launch DevGate directly from your app drawer!

---

## 🛠️ Tech Stack
- **UI & Logic**: Flutter & Dart (62.9%)
- **Performance Modules**: C++ (19.8%), C (1.1%)
- **Platform Specifics**: Swift (iOS), Kotlin (Android)
- **Build Configuration**: CMake

## 🤝 Contributing
Contributions are always welcome! Feel free to open a pull request or submit issues.
