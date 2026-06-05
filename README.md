# Sampark — Flutter Chat App

A real-time chat application built with Flutter and Firebase, supporting email-based messaging, file sharing, and push notifications.

## Features

- **Email Authentication** — Sign up / login with email & password via Firebase Auth
- **Add Contacts** — Add users by their registered email address
- **Real-time Messaging** — Live chat powered by Cloud Firestore streams
- **Message Edit & Delete** — Edit or delete your sent messages; deleted files are removed from Storage
- **File Sharing** — Send images (camera/gallery) and documents (PDF, DOC, TXT)
- **Push Notifications** — FCM notifications for new messages (foreground, background, and terminated states)
- **Profile Photo** — Upload a profile picture during sign-up via Firebase Storage
- **Online Status** — Shows online/offline status based on `lastActive` timestamp
- **Dark Theme** — App-wide dark UI with a consistent design system

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging + flutter_local_notifications |
| File Downloads | Dio + path_provider |

## Getting Started

### Prerequisites
- Flutter SDK `^3.8.1`
- Firebase project with Auth, Firestore, Storage, and FCM enabled
- Android / iOS device or emulator

### Setup

```bash
git clone <repo-url>
cd chat_app
flutter pub get
```

Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective platform folders.

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart               # App entry, Firebase init, FCM setup
├── firebase_options.dart   # Auto-generated Firebase config
├── models/
│   └── chat_model.dart     # ChatModel, MessageModel, ContactModel
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart    # Chats / Contacts / Calls tabs
│   ├── chat_screens.dart   # Real-time chat, file sending
│   ├── new_contact_screen.dart
│   ├── profile_screens.dart
│   └── your_profile_screen.dart
├── services/
│   ├── auth_service.dart
│   └── notification_service.dart
├── utils/
│   └── app_theme.dart
└── widgets/
    ├── message_bubble.dart
    ├── chat_list_item.dart
    └── animated_button.dart
```
