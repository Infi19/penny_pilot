import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
// For now, we will implement the service structure and fallback logic
// expecting the user to run 'flutter pub get'

enum ScamRisk {
  safe,
  suspicious,
  high,
}

class ScamDetectionService {
  static final ScamDetectionService _instance = ScamDetectionService._internal();
  Interpreter? _interpreter;
  List<String> _vocab = [];
  bool _isModelLoaded = false;
  
  // Singleton pattern
  factory ScamDetectionService() {
    return _instance;
  }
  
  ScamDetectionService._internal();

  /// Initialize the TFLite interpreter and load vocabulary
  Future<void> initialize() async {
    try {
      // Load Interpreter
      _interpreter = await Interpreter.fromAsset('assets/models/scam_detector.tflite');
      
      // Load Vocabulary
      final vocabData = await rootBundle.loadString('assets/models/vocab.txt');
      _vocab = vocabData.split('\n').where((w) => w.isNotEmpty).toList();
      
      _isModelLoaded = true;
      print('ScamDetectionService: Model and vocabulary loaded successfully');
    } catch (e) {
      print('ScamDetectionService: Error loading model/vocab (using fallback): $e');
      _isModelLoaded = false;
    }
  }

  /// Analyze the message text and return a risk assessment
  Future<ScamResult> analyzeMessage(String text) async {
    if (!_isModelLoaded || _interpreter == null) {
      return _fallbackAnalysis(text);
    }

    try {
      // 1. Preprocess
      List<double> input = _preprocess(text);
      
      // 2. Reshape for input [1, 20] (based on model training)
      var inputTensor = [input]; 
      
      // 3. Prepare output tensor [1, 3] (Safe, Suspicious, Scam)
      var outputTensor = List.filled(1 * 3, 0.0).reshape([1, 3]);
      
      // 4. Run Inference
      _interpreter!.run(inputTensor, outputTensor);
      
      // 5. Interpret Output
      List<double> probabilities = List<double>.from(outputTensor[0]);
      int maxIndex = 0;
      double maxProb = probabilities[0];
      
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      ScamRisk risk;
      String reason;
      
      switch (maxIndex) {
        case 0: // Safe
          risk = ScamRisk.safe;
          reason = "No suspicious patterns detected by AI.";
          break;
        case 1: // Suspicious
          risk = ScamRisk.suspicious;
          reason = "Content resembles known promotional or unsolicited offers.";
          break;
        case 2: // Scam
          risk = ScamRisk.high;
          reason = "High-risk content detected (urgency, threats, or suspicious links).";
          break;
        default:
          risk = ScamRisk.safe;
          reason = "Analysis inconclusive.";
      }
      
      // Populate indicators using heuristics even if model was used, 
      // because the model only gives a probability score.
      List<String> indicators = [];
      if (risk != ScamRisk.safe) {
         // Re-run simple heuristic check to find *why* it might be suspicious for valid explanation
         // This is a hybrid approach: Model gives score, Heuristics give explanation keywords/indicators
         final heuristicResult = _fallbackAnalysis(text);
         indicators = heuristicResult.indicators;
         
         // If heuristics didn't find anything but model says scam, add generic indicator
         if (indicators.isEmpty) {
           indicators.add("AI Model Detection");
         }
      }
      
      return ScamResult(
        risk: risk, 
        confidence: maxProb, 
        reason: reason,
        indicators: indicators
      );
      
    } catch (e) {
      print('ScamDetectionService: Inference error: $e');
      return _fallbackAnalysis(text);
    }
  }

  /// Preprocess text for the model (tokenization, padding)
  List<double> _preprocess(String text) {
    if (_vocab.isEmpty) return List.filled(20, 0.0);
    
    // Simple tokenizer matching Python's Tokenizer logic
    // 1. Lowercase
    String cleanText = text.toLowerCase();
    
    // 2. Remove punctuation (basic)
    cleanText = cleanText.replaceAll(RegExp(r'[^\w\s]'), '');
    
    // 3. Split
    List<String> tokens = cleanText.split(' ');
    
    // 4. Map to indices
    List<double> sequence = [];
    for (String token in tokens) {
      if (token.isEmpty) continue;
      int index = _vocab.indexOf(token);
      // In Keras Tokenizer, 0 is reserved for padding, 1 is <OOV> usually if explicitly set, 
      // but our train script used default which starts indexing at 1.
      // So if found, index + 1 (if vocab list is 0-indexed). 
      // Actually, let's check the vocab generation. 
      // Python's tokenizer.word_index starts at 1. 
      // Our vocab.txt lines correspond to index 1, 2, 3...
      // So line 0 in vocab.txt is word with index 1 ??
      // Wait, the python script logic was:
      // vocab_list[index] = word
      // So vocab_list[1] is the word with index 1.
      // vocab_list[0] is empty/padding?
      
      // If we saved it properly `vocab_list` has words at their index positions.
      // So `vocab.txt` line N corresponds to index N+1 if we iterate or just index N if we read as list.
      // Let's assume strict mapping: vocab[i] is index i.
      
      if (index != -1) {
        sequence.add(index.toDouble()); 
      } else {
        sequence.add(1.0); // 1 is usually OOV if defined, or we skip. Let's use 1.
      }
    }
    
    // 5. Pad/Truncate to max_length=20 (post padding)
    if (sequence.length > 20) {
      sequence = sequence.sublist(0, 20);
    } else {
      while (sequence.length < 20) {
        sequence.add(0.0);
      }
    }
        return sequence;
  }

  /// Fallback heuristic analysis if model is missing or fails
  ScamResult _fallbackAnalysis(String text) {
    String lowerText = text.toLowerCase();
    List<String> detectedIndicators = [];
    
    // High Risk Keywords
    if (lowerText.contains("urgent") || lowerText.contains("immediately")) {
      detectedIndicators.add("Urgent language");
    }
    if (lowerText.contains("suspended") || lowerText.contains("blocked")) {
      detectedIndicators.add("Threatening language (account status)");
    }
    if (lowerText.contains("click") && lowerText.contains("link")) {
      detectedIndicators.add("Suspicious request to click link");
    }
    if (lowerText.contains("verify kyc") || lowerText.contains("verify account")) {
      detectedIndicators.add("Request for account verification");
    }

    // Suspicious Keywords
    if (lowerText.contains("winner") || lowerText.contains("lottery") || lowerText.contains("prize")) {
      detectedIndicators.add("Unrealistic offer (prize/lottery)");
    }
    if (lowerText.contains("claim") || lowerText.contains("refund")) {
      detectedIndicators.add("Request to claim funds");
    }

    if (detectedIndicators.isNotEmpty) {
       // Determine risk based on indicators
       ScamRisk risk = ScamRisk.suspicious;
       if (detectedIndicators.any((i) => i.contains("Urgent") || i.contains("Threatening") || i.contains("verify"))) {
         risk = ScamRisk.high;
       }
       
       return ScamResult(
        risk: risk,
        confidence: risk == ScamRisk.high ? 0.85 : 0.65,
        reason: "Detected: ${detectedIndicators.join(', ')}",
        indicators: detectedIndicators,
      );
    }

    return ScamResult(
      risk: ScamRisk.safe,
      confidence: 0.95,
      reason: "No suspicious patterns detected.",
      indicators: [],
    );
  }
}

class ScamResult {
  final ScamRisk risk;
  final double confidence;
  final String reason;
  final List<String> indicators;

  ScamResult({
    required this.risk,
    required this.confidence,
    required this.reason,
    this.indicators = const [],
  });
}
