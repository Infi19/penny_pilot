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
- **Advanced AI Integration:** Google Gemini AI with enhanced caching, session management, and dynamic response generation

### Financial Education Hub
- **Daily Investment Quizzes:** Adaptive quizzes with difficulty levels (beginner, intermediate, advanced)
- **Quiz Regeneration:** System automatically generates fresh questions for each difficulty level
- **Leaderboard:** Track your progress against other users with a competitive leaderboard
- **Educational Modules:** Learn about investment concepts and strategies (coming soon)

### User Profile & Goals
- **Risk Assessment:** Determine your investment risk profile
- **Financial Health Score:** Comprehensive assessment of your financial well-being
- **Goal Setting & Tracking:** Create and monitor financial targets with progress visualization
- **Personalized Recommendations:** Receive tailored investment advice based on your profile

### UI/UX Features
- **Clean, Modern Interface:** Dark mode design optimized for financial data presentation
- **Real-time Updates:** Synchronized data across devices using Firebase
- **Responsive Design:** Works on various screen sizes and orientations
- **Intuitive Navigation:** Bottom navigation bar for easy access to key features

## 🔧 Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase
  - Authentication
  - Firestore (database)
  - Storage
  - App Check (security)
- **AI Integration:** Google Gemini AI
  - Advanced prompt engineering
  - Session management with unique identifiers
  - Response caching for improved performance
  - Custom response parsing for structured quiz data

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
3. Enable Authentication, Firestore, and Storage services
4. Set up appropriate security rules for Firestore and Storage

### Setting Up Gemini AI
1. Get a Gemini API Key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```
3. Configure API settings for optimal performance:
   - Temperature: 0.7 (for creative quiz generation)
   - MaxOutputTokens: 2000 (for comprehensive responses)
   - TopK and TopP parameters for diverse content generation

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
│   ├── chat_message.dart  # AI assistant chat model
│   ├── quiz_model.dart    # Quiz data structures
│   └── ...                # Other data models
├── screens/               # UI screens
│   ├── home_screen.dart   # Main dashboard
│   ├── learn_screen.dart  # Education hub
│   ├── quiz_screen.dart   # Quiz interface
│   └── ...                # Other screens
├── services/              # Business logic and API services
│   ├── gemini_service.dart    # AI model integration
│   ├── quiz_service.dart      # Quiz generation and management
│   ├── auth_service.dart      # User authentication
│   └── ...                    # Other services
├── utils/                 # Utility functions and constants
│   ├── app_colors.dart    # Color scheme
│   └── ...                # Other utilities
└── widgets/               # Reusable UI components
```

## 🧠 AI Quiz System

The app features an advanced quiz system powered by Google's Gemini AI:

### Key Features
- **Adaptive Difficulty:** Three levels (beginner, intermediate, advanced)
- **Dynamic Generation:** Quizzes are generated based on user's knowledge level
- **Anti-Caching Mechanisms:** Unique session IDs and timestamps ensure fresh content
- **Fallback System:** Pre-defined questions available if AI generation fails
- **Multiple Submission Prevention:** Users can only take one quiz per day (unless in debug mode)

### Implementation Details
- **Enhanced Prompting:** Structured prompts guide the AI to generate finance-focused questions
- **JSON Parsing:** Robust parsing of AI-generated content into structured quiz format
- **Error Handling:** Comprehensive error detection and graceful fallbacks
- **Debugging Tools:** Hidden debugging features for development and testing
- **Performance Optimization:** Caching strategies to minimize API calls

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
- Debug mode provides special tools for testing (quiz regeneration, multiple submissions)

## 📈 Future Roadmap

- **Enhanced Financial Education:** Structured learning modules with progress tracking
- **Portfolio Guidance:** Real-time tracking and visualization of investments
- **Fraud Alert System:** Real-time notifications about financial scams and fraudulent schemes
- **Voice-Enabled AI Chat:** Interact with financial assistants using natural voice conversations
- **Budgeting and Expense Tracking:** Comprehensive financial management tools
- **Community Features:** Forums and discussion groups for peer learning

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 👥 Team

- **Segfault duo**
  - Aditya Kanchan - [GitHub](https://github.com/adityakanchan)
  - Pranav Suryavanshi - [GitHub](https://github.com/Infi19)

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev/) - [Documentation](https://docs.flutter.dev/)
- [Firebase](https://firebase.google.com/) - [Documentation](https://firebase.google.com/docs)
- [Google Generative AI](https://developers.generativeai.google/) - [Documentation](https://ai.google.dev/docs)
