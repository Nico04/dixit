import '_models.dart';

class Room {
  final String name;
  final List<Player> players;
  final Player currentPlayer;
  final Phase phase;
  final int turn;

  Room(this.name, this.players, this.currentPlayer, this.phase, this.turn);
}