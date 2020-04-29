import 'dart:async';
import 'dart:math';

import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:dixit/services/web_services.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

const _pageContentPadding = EdgeInsets.all(15);

class GamePage extends StatelessWidget {
  final String playerName;
  final String roomName;
  final Map<int, CardData> cards;

  const GamePage({Key key, this.playerName, this.roomName, this.cards}) : super(key: key);

  static Future<bool> askExit(BuildContext context) async => await askUserConfirmation(
    context: context,
    title: 'Quitter la partie',
    message: 'Êtes-vous sûr de vouloir quitter la partie en cours ?'
  );

  @override
  Widget build(BuildContext context) {
    return Provider<GamePageBloc>(
      create: (context) => GamePageBloc(
        playerName: playerName,
        roomName: roomName,
        cards: cards,
      ),
      dispose: (_, bloc) => bloc.dispose(),
      child: Consumer<GamePageBloc>(
        builder: (context, bloc, _) {
          return WillPopScope(
            onWillPop: () async => await askExit(context),
            child: StreamBuilder<Room>(
              stream: bloc.roomStream,
              builder: (context, snapshot) {
                var room = snapshot.data;

                // Prepare
                Color instructionsColor;
                String instructionsText;
                var getInstructionsColor = (bool todo) => todo == true ? Colors.greenAccent : Colors.grey;

                // Build content
                Widget child = () {
                  // If data is not available
                  if (room == null) {
                    instructionsColor = getInstructionsColor(false);
                    instructionsText = 'Synchronisation en cours';

                    return Center(
                      child: CircularProgressIndicator()
                    );
                  }

                  var player = room.players[bloc.playerName];
                  var isHost = player.name == room.players.keys.first;

                  // WaitingLobby
                  if (room.turn == 0) {
                    instructionsColor = getInstructionsColor(isHost);
                    instructionsText = 'En attente des joueurs';

                    return WaitingLobby(
                      room.players.keys.toList(growable: false),
                      showStartButton: isHost,
                      onStartGame: () => bloc.startGame(room),
                    );
                  }

                  var isStoryteller = player.name == room.phase.storytellerName;
                  var phaseNumber = room.phase.number;

                  bool mustChooseSentence = false;
                  CardPickerSelectCallback onHandCardSelectedCallback;
                  CardPickerSelectCallback onBoardCardSelectedCallback;

                  if (phaseNumber == Phase.Phase1_storytellerSentence) {
                    instructionsColor = getInstructionsColor(isStoryteller);
                    instructionsText = isStoryteller ? 'Choisir une carte et une phrase' : 'Attendre';
                    mustChooseSentence = isStoryteller;
                    if (isStoryteller)
                      onHandCardSelectedCallback = (card, sentence) => bloc.setSentence(room, card, sentence);
                  }

                  else if (phaseNumber == Phase.Phase2_cardSelect) {
                    var playerHasSelected = room.phase.playedCards.keys.contains(player.name);
                    var hasActionToDo = !isStoryteller && !playerHasSelected;
                    instructionsColor = getInstructionsColor(hasActionToDo);
                    instructionsText = hasActionToDo ? 'Choisir une carte :\n${room.phase.sentence}' : 'Attendre';
                    if (hasActionToDo)
                      onHandCardSelectedCallback = (card, _) => bloc.selectCard(room, card);
                  }

                  else if (phaseNumber == Phase.Phase3_vote) {
                    var playerHasVoted = room.phase.votes.values.any((players) => players.contains(player.name));
                    instructionsColor = !playerHasVoted ? Colors.greenAccent : Colors.grey;
                    instructionsText = !playerHasVoted ? 'Voter pour une carte :\n${room.phase.sentence}' : 'Attendre';
                    if (!playerHasVoted)
                      onBoardCardSelectedCallback = (card, _) => bloc.voteCard(room, card);
                  }

                  /*else if (phaseNumber == Phase.Phase4_scores) {
                  color = !playerHasVoted ? Colors.greenAccent : Colors.grey;
                  text = !playerHasVoted ? 'Voter pour une carte :\n${room.phase.sentence}' : 'Attendre';
                  if (!playerHasVoted)
                    onSelectCallback = (card, _) => bloc.voteCard(room, card);
                  }*/

                  // Game board
                  return GameBoard(
                    playerCards: bloc.getCardDataFromIds(player.cards),
                    boardCards: bloc.getCardDataFromIds(room.phase.playedCards.values),
                    playedCardId: room.phase.playedCards[player.name],
                    onHandCardSelected: onHandCardSelectedCallback,
                    onBoardCardSelected: onBoardCardSelectedCallback,
                    mustChooseSentence: mustChooseSentence,
                    scores: room.players.map((playerName, player) => MapEntry(playerName, player.score)),
                  );

                  /**
                  // Card Picker
                  return CardPicker(
                    cards: bloc.getCardDataFromIds(
                      room.phase.number == Phase.Phase3_vote
                        ? room.phase.playedCards.values.toList(growable: false)
                        : player.cards
                    ),
                    excludedCardId: room.phase.number == Phase.Phase3_vote ? room.phase.playedCards[player.name] : null,
                    mustSelectSentence: mustSelectSentence,
                    onSelected: onSelectCallback,
                  );*/
                } ();

                // Build page
                return Material(
                  child: Column(
                    children: <Widget>[

                      // Indications header
                      InstructionsHeader(
                        roomName: roomName,
                        playerName: playerName,
                        color: instructionsColor,
                        instructions: instructionsText,
                        turn: room?.turn,
                        phaseNumber: room?.phase?.number,
                      ),

                      Expanded(
                        child: child,
                      )
                    ],
                  ),
                );
              }
            ),
          );
        }
      ),
    );
  }
}

class InstructionsHeader extends StatelessWidget {
  final Color color;
  final String roomName;
  final String playerName;
  final String instructions;
  final int turn;
  final int phaseNumber;

  const InstructionsHeader({Key key, this.color, this.roomName, this.playerName, this.instructions, this.turn, this.phaseNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: SafeArea(
        child: Row(
          children: <Widget>[

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[

                    // Informations
                    Row(
                      children: <Widget>[

                        // Player and room's names
                        Text('$playerName @ $roomName'),

                        // Game info
                        Spacer(),
                        if (turn != null && turn > 0)
                          Text('Tour $turn, Phase $phaseNumber'),

                      ],
                    ),

                    // Instructions
                    AppResources.SpacerTiny,
                    Text(instructions),

                  ],
                ),
              ),
            ),

            // Actions
            PopupMenuButton<int>(
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<int>(
                  value: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.exit_to_app),
                      AppResources.SpacerTiny,
                      Text('Quitter la partie'),
                    ],
                  ),
                ),
              ],
              onSelected: (index) async {
                if (await GamePage.askExit(context))
                  Navigator.of(context).pop();
              },
            ),

          ],
        ),
      ),
    );
  }
}

class WaitingLobby extends StatelessWidget {
  final List<String> playersName;
  final bool showStartButton;
  final VoidCallback onStartGame;

  const WaitingLobby(this.playersName, {this.showStartButton, this.onStartGame});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Counter
          Text(plural(playersName.length, 'joueur')),

          // Players
          AppResources.SpacerMedium,
          ...playersName.map((p) => Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                p
              ),
            ),
          )).toList(growable: false),

          // Start button
          if (showStartButton)
            ...[
              AppResources.SpacerMedium,
              RaisedButton(
                child: Text('Commencer'),
                onPressed: onStartGame,   // TODO min 4 players
              )
            ],

        ],
      ),
    );
  }
}

class GameBoard extends StatefulWidget {
  final List<CardData> playerCards;
  final List<CardData> boardCards;
  final CardPickerSelectCallback onHandCardSelected;
  final CardPickerSelectCallback onBoardCardSelected;
  final bool mustChooseSentence;
  final int playedCardId;
  final Map<String, int> scores;    // <playerName, score>

  const GameBoard({Key key, this.playerCards, this.boardCards, this.onHandCardSelected, this.onBoardCardSelected, this.mustChooseSentence, this.playedCardId, this.scores}) : super(key: key);

  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<GamePageBloc>(
      builder: (context, bloc, _) {
        return Scaffold(
          body: IndexedStack(
            children: <Widget>[

              // Player Hand
              CardPicker(
                cards: widget.playerCards,
                mustSelectSentence: widget.mustChooseSentence,
                onSelected: widget.onHandCardSelected,
              ),

              // Table
              CardPicker(
                cards: widget.boardCards,
                playerCardId: widget.playedCardId,
                onSelected: widget.onBoardCardSelected,
              ),

              // Scores
              Scores(widget.scores),

            ],
            index: _currentTabIndex,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.pan_tool),
                title: Text('Main'),
                //backgroundColor: AppResources.ColorLightGrey,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.table_chart),
                title: Text('Table'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart),
                title: Text('Score'),
              ),
            ],
            currentIndex: _currentTabIndex,
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            showUnselectedLabels: false,
          ),
        );
      }
    );
  }
}

typedef CardPickerSelectCallback = void Function(int card, String sentence);

class CardPicker extends StatefulWidget {
  final List<CardData> cards;
  final int playerCardId;
  final bool mustSelectSentence;
  final CardPickerSelectCallback onSelected;

  const CardPicker({Key key, this.cards, this.onSelected, this.mustSelectSentence, this.playerCardId}) : super(key: key);

  @override
  _CardPickerState createState() => _CardPickerState();
}

class _CardPickerState extends State<CardPicker> {
  int _currentCardIndex = 0;
  String _sentence;

  @override
  Widget build(BuildContext context) {
    return Consumer<GamePageBloc>(
      builder: (context, bloc, _) {
        return Column(
          children: <Widget>[

            // Image gallery
            Expanded(
              child: () {

                // If there is no cards
                if (widget.cards?.isNotEmpty != true)
                  return Center(
                    child: Icon(Icons.remove_circle_outline),
                  );

                // If there is at least one card
                return Stack(
                  children: <Widget>[

                    // Image
                    PhotoViewGallery(
                      scrollPhysics: const BouncingScrollPhysics(),
                      pageOptions: widget.cards.map((card) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider: NetworkImage(WebServices.getCardUrl(card.filename)),
                          initialScale: PhotoViewComputedScale.contained * 0.8,
                          minScale: PhotoViewComputedScale.contained * 0.5,
                          maxScale: PhotoViewComputedScale.contained * 1.5,
                          //heroAttributes: HeroAttributes(tag: galleryItems[index].id),
                        );
                      }).toList(growable: false),
                      loadingBuilder: (context, event) {
                        /*return BlurHash(
                          hash: widget.cards[_currentCardIndex].blurHash,
                        );
  */
                        return Center(
                          child: Container(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              value: event == null
                                ? 0
                                : event.cumulativeBytesLoaded / event.expectedTotalBytes,
                            ),
                          ),
                        );
                      },
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      onPageChanged: (index) {
                        setState(() {
                          _currentCardIndex = index;
                        });
                      },
                    ),

                    // Indicator
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Text('Carte ${_currentCardIndex + 1} / ${widget.cards.length}'),
                    ),

                  ],
                );
              }(),
            ),

            // Select Button
            if (widget.onSelected != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Form(
                  child: Builder(
                    builder: (context) {
                      return Column(
                        children: <Widget>[

                          // Sentence text field
                          if (widget.mustSelectSentence == true)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Phrase',
                              ),
                              textInputAction: TextInputAction.done,
                              validator: AppResources.validatorNotEmpty,
                              onFieldSubmitted: (value) => validate(context),
                              onSaved: (value) => _sentence = value,
                            ),

                          // Validate button
                          AppResources.SpacerSmall,
                          RaisedButton(
                            child: Text('Valider'),
                            onPressed: widget.cards[_currentCardIndex].id != widget.playerCardId
                              ? () => validate(context)
                              : null,
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ),

          ],
        );
      }
    );
  }

  void validate(BuildContext context) {
    // Clear focus
    clearFocus(context);   // Keyboard is closed automatically when called from "done" keyboard key, but not in other cases.

    // Validate form
    var form = Form.of(context);
    if (form.validate())
      form.save();
    else
      return;

    // Callback
    widget.onSelected(widget.cards[_currentCardIndex].id, _sentence);
  }
}

class Scores extends StatelessWidget {
  final Map<String, int> scores;    // <playerName, score>

  const Scores(this.scores);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicHeight(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: scores.entries.map((scoreEntry) => _buildScoreLine(
                playerName: scoreEntry.key,
                score: scoreEntry.value,
              )).toList(growable: false),
            ),
          )
        ),
      ),
    );
  }

  Widget _buildScoreLine({String playerName, int score}) {
    return Text('$playerName      $score points');
  }
}


class GamePageBloc with Disposable {
  final String playerName;
  final String roomName;
  final Map<int, CardData> cards;

  final Stream<Room> roomStream;
  StreamSubscription<Room> _roomStreamSubscription;

  GamePageBloc({this.playerName, this.roomName, this.cards}) :
    roomStream = DatabaseService.getRoomStream(roomName) {
    _roomStreamSubscription = roomStream.listen(onRoomUpdate);
  }

  void onRoomUpdate(Room room) {
    print('onRoomUpdate');

    var isStoryteller = playerName == room.phase?.storytellerName;

    // If everyone has chosen a card, go to phase 3
    if (isStoryteller && room.phase.number == Phase.Phase2_cardSelect && room.phase.playedCards.length == room.players.length)
      _toVotePhase(room);

    // If everyone has voted a card, go to phase 4
    if (isStoryteller && room.phase.number == Phase.Phase3_vote && room.phase.votes.values.fold(0, (sum, players) => sum + players.length) == room.players.length)
      _toScoresPhase(room);
  }

  List<CardData> getCardDataFromIds(Iterable<int> cardsIds) => cardsIds.map((id) => cards[id]).toList(growable: false);

  final _random = Random();
  int _drawCard(Room room) => room.cardDeck.removeAt(_random.nextInt(room.cardDeck.length));    //TODO save modif to DB
  
  Future<void> startGame(Room room) async {
    // Draw card for each player
    for (var player in room.players.values)
      player.cards = List.generate(6, (_) => _drawCard(room));

    // First turn
    room.turn = 1;

    // First phase
    room.phase = Phase(
      room.players.keys.first
    );

    // Save data
    await DatabaseService.saveRoom(room);
  }

  Future<void> setSentence(Room room, int card, String sentence) async {
    // Apply new phase data
    room.phase
      ..sentence = sentence
      ..playedCards[room.phase.storytellerName] = card
      ..number = Phase.Phase2_cardSelect;

    // Remove played card and update DB
    await _removePlayedCardAndSaveData(room, card);
  }

  Future<void> selectCard(Room room, int card) async {
    // Apply new phase data
    room.phase.playedCards[playerName] = card;

    // Remove played card and update DB
    await _removePlayedCardAndSaveData(room, card);
  }

  Future<void> _removePlayedCardAndSaveData(Room room, int card) async {
    // Remove played card from player's hand
    var player = room.players[playerName];
    player.cards.remove(card);

    // Update DB
    await DatabaseService.savePhase(room.name, room.phase);
    await DatabaseService.savePlayer(room.name, player);
  }

  Future<void> _toVotePhase(Room room) async {
    // Directly update DB
    await DatabaseService.savePhaseNumber(room.name, Phase.Phase3_vote);
  }

  Future<void> voteCard(Room room, int card) async {
    // Vote directly using DB
    await DatabaseService.addVote(room.name, playerName, card);
  }

  Future<void> _toScoresPhase(Room room) async {
    // ---- Count score ----
    var storytellerName = room.phase.storytellerName;
    var votes = room.phase.votes;

    // If none or all player(s) voted for the storyteller's card, give 2 points for each players except main player
    var storytellerCardVotes = votes[storytellerName]?.length ?? 0;
    if (storytellerCardVotes == 0 || storytellerCardVotes == room.players.length - 1) {
      for (var player in room.players.values) {
        if (player.name != storytellerName)
          player.score += 2;
      }
    }

    // If not
    else {
      // For each card vote
      for (var voteEntry in votes.entries) {
        var cardOwner = room.players[room.phase.playedCards.entries.firstWhere((entry) => entry.value == voteEntry.key).key];

        // If it's the storyteller's card
        if (cardOwner.name == storytellerName) {
          // Give 3 points for each player who has voted for the storyteller's card
          voteEntry.value.forEach((playerName) => room.players[playerName].score += 3);

          // Give 3 point for the storyteller
          cardOwner.score += 3;
        }

        // If not
        else {
          // Give 1 points per voter to the owner
          voteEntry.value.forEach((playerName) => cardOwner.score += 1);
        }

      }
    }

    // ---- Apply new phase data -----
    // Phase number
    room.phase.number = Phase.Phase4_scores;

    // Move phase
    room.previousPhase = room.phase;
    room.phase = null;

    // End game
    if (room.players.values.any((player) => player.score >= 30)) {
      room.endDate = DateTime.now();
    }

    // Start new turn
    else {
      // New phase
      var playersNames = room.players.keys.toList(growable: false);
      var storytellerIndex = playersNames.indexOf(room.previousPhase.storytellerName);
      var nextStoryteller = playersNames[(storytellerIndex + 1) % playersNames.length];
      room.phase = Phase(nextStoryteller);

      // Draw cards
      room.players.forEach((_, p) => p.cards.add(_drawCard(room)));

      // Next turn
      room.turn ++;
    }

    // ---- Update DB -----
    await DatabaseService.saveRoom(room);
  }

  @override
  void dispose() {
    _roomStreamSubscription.cancel();
    super.dispose();
  }
}