// User skill level for quiz difficulty
enum UserLevel {
  beginner,
  intermediate,
  advanced
}

// Helper to convert string to UserLevel enum
UserLevel userLevelFromString(String level) {
  switch (level.toLowerCase()) {
    case 'intermediate':
      return UserLevel.intermediate;
    case 'advanced':
      return UserLevel.advanced;
    case 'beginner':
    default:
      return UserLevel.beginner;
  }
}

// Helper to convert UserLevel enum to string
String userLevelToString(UserLevel? level) {
  if (level == null) return 'beginner';
  
  switch (level) {
    case UserLevel.intermediate:
      return 'intermediate';
    case UserLevel.advanced:
      return 'advanced';
    case UserLevel.beginner:
    default:
      return 'beginner';
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final UserLevel difficulty;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.difficulty = UserLevel.beginner,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
      explanation: json['explanation'],
      difficulty: json['difficulty'] != null 
          ? userLevelFromString(json['difficulty']) 
          : UserLevel.beginner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'difficulty': userLevelToString(difficulty),
    };
  }
}

class DailyQuiz {
  final String id;
  final String date;
  final List<QuizQuestion> questions;
  final bool isCompleted;
  final int? userScore;
  final int totalPoints;
  final UserLevel? difficulty;
  
  DailyQuiz({
    required this.id,
    required this.date,
    required this.questions,
    this.isCompleted = false,
    this.userScore,
    this.totalPoints = 50, // 10 points per question for 5 questions
    this.difficulty = UserLevel.beginner,
  });
  
  // Create a copy of this DailyQuiz with modified fields
  DailyQuiz copyWith({
    String? id,
    String? date,
    List<QuizQuestion>? questions,
    bool? isCompleted,
    int? userScore,
    int? totalPoints,
    UserLevel? difficulty,
  }) {
    return DailyQuiz(
      id: id ?? this.id,
      date: date ?? this.date,
      questions: questions ?? this.questions,
      isCompleted: isCompleted ?? this.isCompleted,
      userScore: userScore ?? this.userScore,
      totalPoints: totalPoints ?? this.totalPoints,
      difficulty: difficulty ?? this.difficulty,
    );
  }
  
  factory DailyQuiz.fromJson(Map<String, dynamic> json) {
    return DailyQuiz(
      id: json['id'],
      date: json['date'],
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
      userScore: json['userScore'],
      totalPoints: json['totalPoints'] ?? 50,
      difficulty: json['difficulty'] != null 
          ? userLevelFromString(json['difficulty'])
          : UserLevel.beginner,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'questions': questions.map((q) => q.toJson()).toList(),
      'isCompleted': isCompleted,
      'userScore': userScore,
      'totalPoints': totalPoints,
      'difficulty': userLevelToString(difficulty),
    };
  }
}

class QuizResult {
  final String quizId;
  final String date;
  final int score;
  final int totalQuestions;
  final List<int> userAnswers;
  final int correctAnswers;
  final int points;
  final int totalPoints;
  final UserLevel difficulty;

  QuizResult({
    required this.quizId,
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.userAnswers,
    required this.correctAnswers,
    this.points = 0,
    this.totalPoints = 50,
    this.difficulty = UserLevel.beginner,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] ?? '',
      date: json['date'],
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      userAnswers: json['userAnswers'] != null ? List<int>.from(json['userAnswers']) : [],
      correctAnswers: json['correctAnswers'] ?? 0,
      points: json['points'] ?? 0,
      totalPoints: json['totalPoints'] ?? 50,
      difficulty: json['difficulty'] != null 
          ? userLevelFromString(json['difficulty'])
          : UserLevel.beginner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'date': date,
      'score': score,
      'totalQuestions': totalQuestions,
      'userAnswers': userAnswers,
      'correctAnswers': correctAnswers,
      'points': points,
      'totalPoints': totalPoints,
      'difficulty': userLevelToString(difficulty),
    };
  }
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int totalPoints;
  final int quizzesTaken;
  final UserLevel userLevel;
  
  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.totalPoints,
    required this.quizzesTaken,
    this.userLevel = UserLevel.beginner,
  });
  
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      totalPoints: json['totalPoints'] ?? 0,
      quizzesTaken: json['quizzesTaken'] ?? 0,
      userLevel: json['userLevel'] != null 
          ? userLevelFromString(json['userLevel'])
          : UserLevel.beginner,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalPoints': totalPoints,
      'quizzesTaken': quizzesTaken,
      'userLevel': userLevelToString(userLevel),
    };
  }
} 