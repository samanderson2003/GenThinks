# GenThinks – AI-Powered Visual Chat App

GenThinks is an innovative AI-powered image chat app with a sleek dark-themed UI and persistent chat powered by Flutter, Firebase, Cloudinary, and OpenAI GPT-4o.

## 🌟 Overview

GenThinks is a cutting-edge Flutter application that enables users to upload images and receive intelligent, AI-generated descriptions and context using OpenAI's GPT-4o model. Featuring a beautiful dark theme with copper and gold accents, GenThinks delivers a smooth, immersive chat experience with persistent history stored in Firebase Firestore.

## 🚀 Features

- Upload images and get AI-powered descriptions and insights.
- Persistent chat history with Firebase Firestore.
- Efficient image storage and delivery via Cloudinary.
- Anonymous user authentication using Firebase Auth.
- Minimalist, glowing UI with smooth animations.
- Intuitive bottom sheet navigation for chat history and new chats.
- Swipe gestures for quick access to previous conversations.

## 🛠️ Tech Stack

- Flutter & Dart for cross-platform UI development.
- Firebase (Firestore & Authentication) for backend services.
- Cloudinary for scalable image hosting.
- OpenAI GPT-4o API for AI chat responses.
- GitHub for version control.

## 🎥 Demo Video

Watch the app in action:

## Watch the app in action

[![GenThinks Demo Video](https://img.youtube.com/vi/VIDEO_ID/0.jpg)](https://drive.google.com/file/d/1kvuV7AvRQ6SYeCPIO9oIYGpWWC9I5jfd/view?usp=drivesdk)

## 📲 Download APK

You can download and install the APK from the link below:

[Download GenThinks APK](https://github.com/samanderson2003/GenThinks/blob/main/downloadAPK/GenThinks.apk)

## 🏁 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/YourUsername/GenThinks.git
cd GenThinks
```

### 2. Firebase Setup

- Create a Firebase project at [Firebase Console](https://console.firebase.google.com).
- Enable Firestore Database and Anonymous Authentication.
- Register your Flutter app and download `google-services.json`.
- Place `google-services.json` in `/android/app/`.

### 3. Configure Cloudinary

- Sign up at [Cloudinary](https://cloudinary.com).
- Obtain your `CLOUD_NAME`, `API_KEY`, and `UPLOAD_PRESET`.
- Add these credentials to your Flutter project config.

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Add API Keys

Add your keys in `config/constants.dart` or `.env`:

```dart
const String openAIKey = "YOUR_GPT4O_API_KEY";
const String cloudinaryUploadUrl = "https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/image/upload";
const String cloudinaryPreset = "YOUR_UPLOAD_PRESET";
```

### 6. Run the App

```bash
flutter run
```

## 🗂️ Firestore Data Structure

```
users/
  userID/
    chats/
      chatID/
        messages: [
          {
            text: "Describe this image...",
            timestamp: Timestamp,
            imageUrl: "https://..."
          },
          ...
        ]
```

## 🎨 Design & Architecture

- Cloudinary chosen for free-tier friendly, scalable image hosting.
- Persistent chat stored in Firestore for seamless session continuity.
- Unified bottom sheet UI for a clean, distraction-free interface.
- Responsive animations and glowing copper/gold accents on a dark theme.

## ⚙️ Key Components

| Widget/Service       | Responsibility                          |
|----------------------|------------------------------------------|
| `ChatScreen`         | Main chat interface and input area       |
| `BottomSheetDrawer`  | Chat history and new chat navigation     |
| `ImagePickerWidget`  | Image selection and Cloudinary upload    |
| `FirebaseService`    | Firestore data management                |
| `OpenAIService`      | GPT-4o API communication                 |

## 📢 Deployment Tips

- Build release APK or iOS app with `flutter build apk` or `flutter build ios`.
- Never commit API keys; use environment variables or secure vaults.
- Verify all Firebase and Cloudinary configurations before production launch.

## 🤝 Contribution

Contributions are welcome! Please fork the repo and create a pull request for any improvements or bug fixes.
