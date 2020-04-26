import '_models.dart';

class Phase {
  final int number;
  final String sentence;
  final Map<String, Player> cards;
  final Map<String, List<Player>> votes;

  Phase(this.number, this.sentence, this.cards, this.votes);
}