# Penny Pilot

A financial education and management app with AI assistant capabilities.

## Gemini AI Integration

This app uses Google's Gemini AI to power its AI assistants. Follow these steps to set up the Gemini integration:

### 1. Get a Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the API key to your clipboard

### 2. Configure the API Key

1. Locate the `.env` file in the project root
2. Replace `your_gemini_api_key_here` with your actual API key:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```
3. Save the file
4. Never share or commit your API key to version control

### 3. Running the App

1. Make sure you have Flutter and all dependencies installed
2. Run `flutter pub get` to install packages
3. Run the app with `flutter run`

### Troubleshooting

- If you see "Gemini API key not found" error, check that your .env file exists and contains the correct API key
- If the API calls fail, verify that your API key is valid and has not exceeded its quota
- For other issues, check the Flutter console for detailed error messages

## Features

- AI-powered financial assistants for different topics
- Secure chat history storage
- Multiple AI agents with specialized knowledge

## License

This project is proprietary and confidential.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
