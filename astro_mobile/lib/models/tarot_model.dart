class TarotCard {
  final String id;
  final String name;
  final String position;
  final bool isReversed;
  final String meaning;
  final String element;
  final String color;

  TarotCard({
    required this.id,
    required this.name,
    required this.position,
    required this.isReversed,
    required this.meaning,
    required this.element,
    required this.color,
  });

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      isReversed: json['is_reversed'] ?? false,
      meaning: json['meaning'] ?? '',
      element: json['element'] ?? '',
      color: json['color'] ?? '#FFFFFF',
    );
  }
}

class WishOutcome {
  final String title;
  final String text;
  final int score;

  WishOutcome({required this.title, required this.text, required this.score});

  factory WishOutcome.fromJson(Map<String, dynamic> json) {
    return WishOutcome(
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      score: json['score'] ?? 0,
    );
  }
}

class TarotResponse {
  final List<TarotCard> cards;
  final String synthesis;
  final WishOutcome wish;

  TarotResponse({required this.cards, required this.synthesis, required this.wish});

  factory TarotResponse.fromJson(Map<String, dynamic> json) {
    var list = json['cards'] as List;
    List<TarotCard> cardsList = list.map((i) => TarotCard.fromJson(i)).toList();

    return TarotResponse(
      cards: cardsList,
      synthesis: json['synthesis'] ?? '',
      wish: WishOutcome.fromJson(json['wish'] ?? {}),
    );
  }
}
