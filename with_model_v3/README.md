# PhishSafe SDK Demo (Windows + Android Studio Setup)

This repository demonstrates how to run the PhishSafe SDK demo app on **Windows OS** using **Flutter** and **Android Studio**.

---

## How to Run

### 1. Clone the Repository

Use Git to clone the project:

```bash
git clone https://github.com/manya7s/SudoCode-PhishSafe.git
```


---
### 2. Link the SDK to the Demo App

In your demo app's `pubspec.yaml` file, add a path reference to the local SDK folder:

```yaml
dependencies:
  phishsafe_sdk:
    path: ../<path-to-your-PhishSafe-SDK-folder>
```

### 3. Install Dependencies for the PhishSafe SDK

Navigate to the SDK folder and run in terminal:

```bash
flutter pub get
```

Navigate to the Demo app folder and run in terminal:

```bash
flutter pub get
```

This will fetch all required packages for the PhishSafe SDK and Demo application.


Make sure the relative path is correct based on your folder structure.

---

### 4. Fix TFLite Tensor Error (Important)

Manually modify a file in the pub cache to fix a TensorFlow Lite compatibility issue.

**Navigate to:**

```
C:\Users\<your-username>\AppData\Local\Pub\Cache\hosted\pub.dev\tflite_flutter-0.10.4\lib\src\tensor.dart
```

**Steps:**

1. Open the file in any text or code editor.
2. Press `Ctrl + F` and search for:

   ```
   UnmodifiableUint8ListView
   ```

3. Replace it with:

   ```dart
   Uint8List.fromList
   ```

4. Save the file.

This fixes runtime issues when loading models using TFLite.

---

## Admin Dashboard

You can view the PhishSafe Admin Dashboard at:

**URL:** [https://phishsafe-web.onrender.com/](https://phishsafe-web.onrender.com/)

---

## Requirements

- Flutter SDK installed
- Dart SDK installed
- Android Studio with Flutter and Dart plugins
- Working Android emulator or connected device

You can verify your setup by running:

```bash
flutter doctor
```

---

## Model Notebook
**URL:** [https://colab.research.google.com/drive/1icvGL5U2TMI2aVHATqYh4ktDKzEcSwsW?usp=sharing](https://colab.research.google.com/drive/1icvGL5U2TMI2aVHATqYh4ktDKzEcSwsW?usp=sharing)

---

## Demonstration Video
**URL:** [https://youtu.be/HtK8RH53tBY](https://youtu.be/HtK8RH53tBY)

---

## Support

If you face issues:

- Double-check the SDK path in `pubspec.yaml`
- Make sure you've run `flutter pub get` inside the SDK
- Verify that you’ve fixed the `tensor.dart` issue correctly

---

## License

This project is intended for demo and academic use. License terms may apply depending on your use case.
