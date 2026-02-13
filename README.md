# Penny Pilot

<p align="center">
  <img src="assets/images/icon.png" width="120" alt="Penny Pilot Logo">
</p>

A comprehensive mobile application for financial education, management, and AI-powered assistance. Penny Pilot helps users make informed financial decisions through personalized advice, automated expense tracking, fraud detection, and financial roadmap planning.

## 📱 Features

### 🤖 Unified AI Assistant (Penny Pilot Assistant)
An all-in-one AI companion powered by **Google Gemini 2.5 Flash** that handles multiple financial roles:
- **Personal Financial Coach:** Analyzes your spending patterns and provides actionable insights.
- **Fraud Detective:** Identifies potential financial scams and explains risk indicators effectively.
- **Financial Myth Buster:** Debunks common financial misconceptions with factual data.
- **Roadmap Guide:** Creates structured plans for your financial goals (e.g., buying a house, retirement).
- **Context-Aware:** Uses your real-time financial data (spending, budgets, goals) to give personalized advice.

### 📩 SMS Banking & Scam Detection
- **Automated Expense Tracking:** Securely parses banking SMS to track expenses and income automatically.
- **On-Device Scam Detection:** Uses a local **TensorFlow Lite (TFLite)** model to analyze incoming messages for potential fraud *without sending data to the cloud*.
- **Privacy-First:** All sensitive SMS data processing happens locally on your device.
- **Scam Explanations:** If a message is flagged, the AI explains *why* it's suspicious using the detection signals.

### 📊 Financial Management & Analytics
- **Comprehensive Dashboard:** View your net worth, recent transactions, and financial health score at a glance.
- **Expense Analytics:** Visual breakdown of spending by category, trends over time, and high-spend days.
- **Budgeting:** Set monthly limits for different categories and track adherence.
- **Goal Tracking:** meaningful visualization of progress towards your financial targets.

### 🎓 Financial Education Hub
- **Daily Investment Quizzes:** AI-generated adaptive quizzes (Beginner, Intermediate, Advanced) to test your knowledge.
- **Dynamic Content:** Questions are generated fresh daily based on your skill level.
- **Leaderboard:** Compete with other users and track your learning streak.

### UI/UX Features
- **Clean, Modern Interface:** Dark mode design optimized for readability and data visualization.
- **Real-time Updates:** Synchronized data across devices using Firebase Cloud Firestore.
- **Responsive Design:** Smooth performance on various Android devices.
- **Secure Authentication:** Google Sign-In support.

## 🔧 Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Storage, App Check)
- **AI Integration:** 
  - **Google Gemini API** (gemini-2.5-flash) via `google_generative_ai` package
  - Context-aware prompting and response caching
- **Machine Learning (On-Device):**
  - **TensorFlow Lite** (`tflite_flutter`) for offline scam detection
- **State Management:** Provider
- **Local Storage:** Shared Preferences
- **Security:** Firebase App Check (Play Integrity)

## 📋 Requirements

- Flutter SDK: ^3.7.2
- Dart SDK: ^3.7.2
- Android: minSdkVersion 21
- iOS: iOS 12+ (Note: SMS features are Android-specific currently)

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
3. Enable Authentication (Google Sign-In), Firestore, and Storage services
4. Set up appropriate security rules

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
├── models/                # Data models (Transaction, Budget, Goal, etc.)
├── screens/               # UI screens
│   ├── home_screen.dart           # Dashboard
│   ├── ai_assistant_screen.dart   # Unified AI Chat Interface
│   ├── banking_messages_screen.dart # SMS & Scam Detection
│   ├── analytics_screen.dart      # Spending Analytics
│   └── ...
├── services/              # Business logic and API services
│   ├── gemini_service.dart    # AI integration logic
│   ├── scam_detection_service.dart # TFLite model handling
│   ├── sms_service.dart       # SMS reading and parsing
│   └── ...
├── utils/                 # Utilities (Constants, formatters)
└── widgets/               # Reusable UI components
```

## 🧠 AI & ML Systems

### Unified Assistant
The app uses a single chat interface (`AIAssistantScreen`) that dynamically switches system prompts based on user intent, providing a seamless experience whether you're asking about budget advice or checking a suspicious message.

### Scam Detection Model
A custom TFLite model is embedded in the app to classify SMS messages as Safe, Suspicious, or High Risk. This runs entirely offline for privacy and speed.

## 🔒 Security

This app uses Firebase App Check to prevent unauthorized access to backend resources. In production, ensure you have configured:
- SHA-256 fingerprints in Firebase Console
- Google Play Integrity API for Android

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.