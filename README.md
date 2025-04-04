# Penny Pilot

<p align="center">
  <img src="assets/images/icon.png" width="120" alt="Penny Pilot Logo">
</p>

A comprehensive mobile application for financial education, management, and AI-powered assistance. Penny Pilot helps users make informed financial decisions through personalized advice, fraud detection, financial myth busting, and roadmap guidance.

## 📱 Features

### AI Assistants
- **Smart Finance Advisor:** Provides personalized financial advice based on user profiles, goals, and risk tolerance
- **Fraud Detective:** Helps identify and learn about financial fraud schemes
- **Myth Buster:** Debunks financial myths and misconceptions
- **Roadmap Guide:** Offers guidance on financial journeys

### User Profile & Goals
- Create and manage personal financial profiles
- Set and track financial goals
- Receive personalized investment recommendations

### Financial Education
- Learn about investment concepts and strategies
- Understand market terminology
- Access expert financial insights

## 🔧 Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase
  - Authentication
  - Firestore (database)
  - Storage
  - App Check (security)
- **AI Integration:** Google Gemini AI

## 📋 Requirements

- Flutter SDK: ^3.7.2
- Dart SDK: ^3.7.2
- Android: minSdkVersion 21
- iOS: iOS 12+

## 🚀 Getting Started

### Prerequisites
- Flutter installed and configured ([Flutter Installation Guide](https://flutter.dev/docs/get-started/install))
- An IDE (VS Code, Android Studio, or IntelliJ)
- Git
- A Firebase account

### Setting Up Firebase
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Configure Firebase for your Flutter app:
   - Android: Add your app to Firebase, download `google-services.json` and place it in `android/app/`
   - iOS: Add your app to Firebase, download `GoogleService-Info.plist` and place it in `ios/Runner/`

### Setting Up Gemini AI
1. Get a Gemini API Key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```

### Installation
1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd penny_pilot
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── main.dart              # Entry point
├── firebase_options.dart  # Firebase configuration
├── models/                # Data models
├── screens/               # UI screens
├── services/              # Business logic and API services
├── utils/                 # Utility functions and constants
└── widgets/               # Reusable UI components
```

## 🔒 Security

This app uses Firebase App Check to prevent unauthorized access to backend resources. In production, you should configure proper App Check providers:

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
);
```

## 🛠️ Development Guidelines

- Follow [Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Write tests for new features
- Use feature branches and pull requests for collaborative development

## 📈 Future Roadmap

- Portfolio management tools
- Integration with real financial institutions
- Budgeting and expense tracking
- Community features for financial discussion

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is proprietary and confidential.

## 👥 Team

- [Your Name/Team Members]
- Contact: [Your Email]

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Google Generative AI](https://developers.generativeai.google/)
