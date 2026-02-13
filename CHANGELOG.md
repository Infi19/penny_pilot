# Changelog

## [2.0.0] - 2026-02-13

### Added
- **Unified AI Assistant:** Merged separate AI agents into a single, context-aware "Penny Pilot Assistant" capable of coaching, fraud detection, myth busting, and roadmap planning.
- **SMS Banking Integration:** Automatically parses banking SMS to track expenses and income (Android only).
- **On-Device Scam Detection:** Integrated TensorFlow Lite model to analyze SMS messages for fraud indicators locally, ensuring privacy.
- **TFLite Integration:** Added `tflite_flutter` for offline machine learning capabilities.

### Changed
- **Architecture:** Transitioned to a unified AI service architecture for better context management.
- **UI/UX:** Enhanced chat interface to support the unified assistant.
- **Documentation:** Updated README to reflect new features and removal of deprecated agent screens.

### Removed
- **Separate Agent Screens:** Removed individual screens for Fraud Detective, Myth Buster, etc., in favor of the unified chat interface.
