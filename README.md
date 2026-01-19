# Object Detection and Recognition for Visually Impaired

This project implements a **real-time object detection and recognition system** designed to assist visually impaired users in navigating their environment safely and efficiently.

The system detects objects in real-time using **YOLOv8n** and provides immediate **text-to-speech (TTS) output**, allowing users to know what objects are around them without needing to see them.

---

## Features

* **Real-time Object Detection** using YOLOv8n
* **Text-to-Speech Feedback** for detected objects
* **Mobile-Friendly Deployment** via Flutter app
* **Offline Capability** once models are downloaded
* **Custom Dataset Support** for specific objects

---

## Architecture

1. **Object Detection Model**

   * YOLOv8n trained on a merged dataset from COCO, Pascal VOC, and Roboflow

2. **Backend Processing**

   * Flutter app uses `tflite_flutter` to run TFLite models
   * Converts detection results into TTS output

3. **User Interface**

   * Simple, clean interface suitable for visually impaired users
   * Real-time audio feedback instead of relying on visuals

---

## Tech Stack

* Python (YOLOv8 training)
* TFLite (model conversion)
* Flutter (mobile app deployment)
* `tflite_flutter` for inference
* Offline TTS engine for audio output

---

## Getting Started

### 1. Clone the repository

```
git clone 
```

### 2. Install Dependencies

**Flutter App**

```
flutter pub get
```

### 3. Run the App

**Flutter App**:

```
flutter run
```

---

## Project Structure

```
/echoeyes
  /assets         → images, icons, labels, TFLite models
  /lib            → Flutter source code
    /screens
      detection_screen.dart     → YOLOv8 camera detection screen
      settings_screen.dart      → settings screen
      splash_screen.dart        → Launch screen
      
  README.md       → Project documentation, dataset, etc.
```

---

## How It Works

1. Capture input from camera feed.
2. Run YOLOv8n detection.
3. Get object labels and confidence scores.
4. Convert labels to speech using native TTS.
5. Provide real-time audio feedback to the visually impaired user.

---

## References

* YOLOv8 Documentation: [https://docs.ultralytics.com/](https://docs.ultralytics.com/)
* Flutter: [https://flutter.dev/](https://flutter.dev/)
* TFLite Flutter Plugin: [https://pub.dev/packages/tflite_flutter](https://pub.dev/packages/tflite_flutter)

---

## Important!
This project is my FYP. You may view it, but you may NOT modify or redistribute without permission.
