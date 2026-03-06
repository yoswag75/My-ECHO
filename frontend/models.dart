class Analysis {
  final List<String> emotions;
  final List<String> themes;
  final String reflection;

  Analysis({required this.emotions, required this.themes, required this.reflection});

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      emotions: List<String>.from(json['emotions'] ?? []),
      themes: List<String>.from(json['themes'] ?? []),
      reflection: json['reflection'] ?? '',
    );
  }
}

class JournalEntry {
  final int id;
  final String content;
  final String createdAt;
  final Analysis? analysis;

  JournalEntry({required this.id, required this.content, required this.createdAt, this.analysis});

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      content: json['content'],
      createdAt: json['created_at'],
      analysis: json['analysis'] != null ? Analysis.fromJson(json['analysis']) : null,
    );
  }
}

class Person {
  final int id;
  final String name;

  Person({required this.id, required this.name});

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      name: json['name'],
    );
  }
}

class SentimentPoint {
  final String date;
  final int score;

  SentimentPoint({required this.date, required this.score});

  factory SentimentPoint.fromJson(Map<String, dynamic> json) {
    return SentimentPoint(
      date: json['date'],
      score: json['score'],
    );
  }
}

class PersonAnalytics {
  final String name;
  final int entryCount;
  final String netEffect;
  final List<String> commonEmotions;
  final String tone;
  final int consistency;
  final List<SentimentPoint> history;

  PersonAnalytics({
    required this.name,
    required this.entryCount,
    required this.netEffect,
    required this.commonEmotions,
    required this.tone,
    required this.consistency,
    required this.history,
  });

  factory PersonAnalytics.fromJson(Map<String, dynamic> json) {
    return PersonAnalytics(
      name: json['name'] ?? 'Unknown',
      entryCount: json['entry_count'],
      netEffect: json['net_emotional_effect'],
      commonEmotions: List<String>.from(json['common_emotions'] ?? []),
      tone: json['relationship_tone'],
      consistency: json['consistency_score'],
      history: (json['history'] as List?)?.map((e) => SentimentPoint.fromJson(e)).toList() ?? [],
    );
  }
}

class WeeklyGoal {
  final String weekStart;
  final String title;
  final String insight;
  final String advice;
  final bool hasData;

  WeeklyGoal({
    required this.weekStart,
    required this.title,
    required this.insight,
    required this.advice,
    required this.hasData,
  });

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    return WeeklyGoal(
      weekStart: json['week_start'],
      title: json['title'],
      insight: json['insight'] ?? '',
      advice: json['advice'] ?? '',
      hasData: json['has_data'] ?? false,
    );
  }
}