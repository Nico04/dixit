import 'dart:async';
import 'dart:math';

import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:dixit/services/web_services.dart';
import 'package:dixit/widgets/_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:screen/screen.dart';

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
        context: context,
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

                // Build content
                Widget child = () {
                  // If data is not available
                  if (room == null) {
                    instructionsColor = _buildInstructionsColor(false);
                    instructionsText = 'Synchronisation en cours';

                    return Center(
                      child: CircularProgressIndicator()
                    );
                  }

                  // Vars
                  var player = room.players[bloc.playerName];
                  var isHost = player.position == 1;

                  // WaitingLobby
                  if (room.turn == 0) {
                    instructionsColor = _buildInstructionsColor(isHost);
                    instructionsText = 'En attente des joueurs';

                    return WaitingLobby(
                      room.players.keys.toList(growable: false),
                      showStartButton: isHost,
                      onStartGame: () => bloc.startGame(room),
                    );
                  }

                  // Vars
                  var isStoryteller = player.name == room.phase?.storytellerName;
                  var phaseNumber = room.phase?.number;

                  bool mustChooseSentence = false;
                  CardPickerSelectCallback onHandCardSelectedCallback;
                  CardPickerSelectCallback onBoardCardSelectedCallback;

                  // Phase 1
                  if (phaseNumber == Phase.Phase1_storytellerSentence) {
                    instructionsColor = _buildInstructionsColor(isStoryteller);
                    instructionsText = isStoryteller
                      ? 'Vous êtes le prochain conteur\nChoisir une carte et une phrase'
                      : _buildWaitText([room.phase.storytellerName]);
                    mustChooseSentence = isStoryteller;
                    if (isStoryteller)
                      onHandCardSelectedCallback = (card, sentence) => bloc.setSentence(room, card, sentence);
                  }

                  // Phase 2
                  else if (phaseNumber == Phase.Phase2_cardSelect) {
                    var waitedPlayersNames = room.players.keys.where((playerName) => !room.phase.playedCards.keys.contains(playerName));
                    var hasPlayerSelected = !waitedPlayersNames.contains(player.name);
                    var hasActionToDo = !isStoryteller && !hasPlayerSelected;
                    instructionsColor = _buildInstructionsColor(hasActionToDo);
                    instructionsText = hasActionToDo
                      ? 'Choisir une carte'
                      : _buildWaitText(waitedPlayersNames);
                    if (hasActionToDo)
                      onHandCardSelectedCallback = (card, _) => bloc.selectCard(room, card);
                  }

                  // Phase 3
                  else if (phaseNumber == Phase.Phase3_vote) {
                    var waitedPlayersNames = room.players.keys.where((playerName) => !room.phase.votes.values.any((players) => players.contains(playerName)));
                    var hasPlayerVoted = !waitedPlayersNames.contains(player.name);
                    instructionsColor = _buildInstructionsColor(!hasPlayerVoted);
                    instructionsText = !hasPlayerVoted
                      ? 'Voter pour une carte'
                      : _buildWaitText(waitedPlayersNames);
                    if (!hasPlayerVoted)
                      onBoardCardSelectedCallback = (card, _) => bloc.voteCard(room, card);
                  }

                  // End of game
                  else if (phaseNumber == null) {
                    instructionsColor = _buildInstructionsColor(false);
                    instructionsText = "Partie terminée !";
                  }

                  // Build Game board
                  return GameBoard(
                    playerCards: bloc.getCardDataFromIDs(player.cards),
                    boardCards: () {
                      Iterable<int> boardCardToDisplay;
                      if (phaseNumber <= Phase.Phase1_storytellerSentence)
                        boardCardToDisplay = room.previousPhase?.playedCards?.values;

                      if (phaseNumber >= Phase.Phase3_vote)
                        boardCardToDisplay = room.phase.playedCards.values;

                      return bloc.getCardDataFromIDs(boardCardToDisplay);
                    } (),
                    playedCardID: room.phase?.playedCards?.getElement(player.name),
                    onHandCardSelected: onHandCardSelectedCallback,
                    onBoardCardSelected: onBoardCardSelectedCallback,
                    mustChooseSentence: mustChooseSentence,
                    scores: room.players.map((playerName, player) => MapEntry(playerName, player.score)),
                    boardCardsTextTop: phaseNumber == Phase.Phase1_storytellerSentence
                      ? room.previousPhase?.playedCards?.map((playerName, cardID) => MapEntry(cardID, playerName))
                      : null,
                    boardCardsTextBottom: phaseNumber == Phase.Phase1_storytellerSentence
                      ? room.previousPhase?.votes?.map((cardID, players) => MapEntry(cardID, players.join('\n')))
                      : null,
                  );

                } ();

                // When between phase 4 and 1
                var displayPreviousPhase = room?.phase?.number == Phase.Phase1_storytellerSentence && room?.previousPhase != null;

                // Build page
                return Column(
                  children: <Widget>[

                    // Indications header
                    GameHeader(
                      roomName: roomName,
                      playerName: playerName,
                      storytellerText: () {
                        var storytellerName = displayPreviousPhase ? room.previousPhase.storytellerName : room?.phase?.storytellerName;
                        return storytellerName == playerName
                          ? "Vous êtes le conteur"
                          : "Le conteur est $storytellerName";
                      } (),
                      sentence: displayPreviousPhase ? room.previousPhase.sentence : room?.phase?.sentence,
                      instructionsColor: instructionsColor,
                      instructions: instructionsText,
                      turn: room != null ? room.turn - (displayPreviousPhase ? 1 : 0) : null,
                      phaseNumber: displayPreviousPhase ? room.previousPhase.number : room?.phase?.number,
                    ),

                    // Content
                    Expanded(
                      child: child,
                    ),

                  ],
                );
              }
            ),
          );
        }
      ),
    );
  }

  Color _buildInstructionsColor(bool hasTodo) => hasTodo == true ? Colors.greenAccent : Colors.grey;

  String _buildWaitText(Iterable<String> waitedPlayersNames) {
    String text;

    if (waitedPlayersNames.length > 1) {
      const separator = ', ';
      text = waitedPlayersNames.join(separator);
      text = text.replaceLast(separator, ' et ');
    } else if (waitedPlayersNames.length == 1) {
      text = waitedPlayersNames.first;
    }

    return text != null ? "En attente de : $text" : "Attendre";
  }
}

class GameHeader extends StatelessWidget {
  final String roomName;
  final String playerName;
  final String storytellerText;
  final String sentence;
  final String instructions;
  final Color instructionsColor;
  final int turn;
  final int phaseNumber;

  const GameHeader({Key key, this.instructionsColor, this.roomName, this.playerName, this.storytellerText, this.instructions, this.turn, this.phaseNumber, this.sentence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,     // TODO doesn't work
      color: AppResources.ColorSand,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[

            // Top
            Row(
              children: <Widget>[

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[

                        // Information
                        Row(
                          children: <Widget>[

                            // Player and room's names
                            Text('$playerName @ $roomName'),

                            // Game info
                            Spacer(),
                            if (turn != null && turn > 0)
                              Text('Tour $turn, Phase $phaseNumber'),   // TODO at the end of the game, phaseNumber is null. Maybe just remove phase number from header ?

                          ],
                        ),

                        // Storyteller name
                        if (storytellerText?.isNotEmpty == true)
                          ...[
                            AppResources.SpacerTiny,
                            Text(storytellerText),
                          ],

                        if (sentence?.isNotEmpty == true)
                          ...[
                            AppResources.SpacerTiny,
                            Text(
                              sentence,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],

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

            // Instructions
            AppResources.SpacerTiny,
            Container(
              color: instructionsColor,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(instructions),
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
    return Material(
      color: Theme.of(context).backgroundColor,
      child: Padding(
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
                Spacer(),
                AsyncButton(
                  text: 'Commencer',
                  onPressed: onStartGame,   // TODO min 4 players
                )
              ],

          ],
        ),
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
  final int playedCardID;
  final Map<String, int> scores;    // <playerName, score>
  final Map<int, String> boardCardsTextTop;    // <cardID, text>
  final Map<int, String> boardCardsTextBottom; // <cardID, text>

  const GameBoard({Key key, this.playerCards, this.boardCards, this.onHandCardSelected, this.onBoardCardSelected, this.mustChooseSentence, this.playedCardID, this.scores, this.boardCardsTextBottom, this.boardCardsTextTop}) : super(key: key);

  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<GamePageBloc>(
      builder: (context, bloc, _) {
        var todoTabIndex = () {
          if (widget.onHandCardSelected != null )
            return 0;
          if (widget.onBoardCardSelected != null )
            return 1;
          return null;
        } ();

        return Scaffold(
          body: IndexedStack(
            children: <Widget>[

              // Player Hand
              CardsView(
                cards: widget.playerCards,
                mustSelectSentence: widget.mustChooseSentence,
                onSelected: widget.onHandCardSelected,
              ),

              // Table
              CardsView(
                cards: widget.boardCards,
                playerCardID: widget.playedCardID,
                onSelected: widget.onBoardCardSelected,
                cardsTextTop: widget.boardCardsTextTop,
                cardsTextBottom: widget.boardCardsTextBottom,
              ),

              // Scores
              Scores(widget.scores),

            ],
            index: _currentTabIndex,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: AnimatedIconHighlight(
                  child: Icon(Icons.pan_tool),
                  playing: todoTabIndex == 0 && _currentTabIndex != todoTabIndex,
                ),
                title: Text('Main'),
              ),
              BottomNavigationBarItem(
                icon: AnimatedIconHighlight(
                  child: Icon(Icons.table_chart),
                  playing: todoTabIndex == 1 && _currentTabIndex != todoTabIndex,
                ),
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
            backgroundColor: AppResources.ColorSand,
            selectedItemColor: AppResources.ColorRed,
          ),
        );
      }
    );
  }
}

typedef CardPickerSelectCallback = Future<void> Function(int card, String sentence);

class CardsView extends StatelessWidget {
  final List<CardData> cards;
  final int playerCardID;
  final bool mustSelectSentence;
  final CardPickerSelectCallback onSelected;
  final Map<int, String> cardsTextTop;   // <cardIndex, text>
  final Map<int, String> cardsTextBottom;   // <cardIndex, text>

  const CardsView({Key key, this.cards, this.onSelected, this.mustSelectSentence, this.playerCardID, this.cardsTextBottom, this.cardsTextTop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If there is no cards
    if (cards?.isNotEmpty != true)
      return Center(
        child: Icon(
          Icons.remove_circle_outline,
          size: 40,
        ),
      );

    // If there is at least one card
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1 / 1.5,
      children: cards.map((card) => _buildCard(
        card,
        topText: cardsTextTop?.getElement(card.id),
        bottomText: cardsTextBottom?.getElement(card.id),
        onPressed: () => navigateTo(context, () => CardPicker(
          cards: cards,
          initialCardID: card.id,
          playerCardID: playerCardID,
          mustSelectSentence: mustSelectSentence,
          onSelected: onSelected,
        )),
      )).toList(growable: false),
      padding: _pageContentPadding,
    );
  }

  Widget _buildCard(CardData card, { String topText, String bottomText, VoidCallback onPressed }) {
    return Card(
      margin: EdgeInsets.all(6),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: <Widget>[

          // Image
          BlurHash(
            hash: card.blurHash,
            image: WebServices.getCardUrl(card.filename),
            duration: Duration(seconds: 1),
          ),

          // Top Text
          if (topText?.isNotEmpty == true)
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTextZone(topText)
            ),

          // Bottom Text
          if (bottomText?.isNotEmpty == true)
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildTextZone(bottomText)
            ),

          // Tap detector
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                child: Container(),
                onTap: onPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextZone(String text) {
    return Container(
      color: AppResources.ColorSand.withOpacity(0.6),
      alignment: Alignment.center,
      padding: EdgeInsets.all(5),
      child: Text(text),
    );
  }
}

class CardPicker extends StatefulWidget {
  final List<CardData> cards;
  final int initialCardID;
  final int playerCardID;
  final bool mustSelectSentence;
  final CardPickerSelectCallback onSelected;

  const CardPicker({Key key, this.cards, this.playerCardID, this.mustSelectSentence, this.onSelected, this.initialCardID}) : super(key: key);

  @override
  _CardPickerState createState() => _CardPickerState();
}

class _CardPickerState extends State<CardPicker> {
  PageController _pageController;
  String _sentence;

  int get _currentCardIndex => _pageController.hasClients && (_pageController.position.pixels == null || (_pageController.position.minScrollExtent != null && _pageController.position.maxScrollExtent != null)) && _pageController.page != null
    ? _pageController.page.round()
    : _pageController.initialPage;

  final isBusy = BehaviorSubject.seeded(false);

  @override
  void initState() {
    _pageController = PageController(initialPage: widget.cards.indexWhere((card) => card.id == widget.initialCardID));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[

          // Image gallery
          Expanded(
            child: Stack(
              children: <Widget>[

                // Image
                PhotoViewGallery(
                  pageController: _pageController,
                  scrollPhysics: const BouncingScrollPhysics(),
                  pageOptions: widget.cards.map((card) {
                    return PhotoViewGalleryPageOptions(
                      key: ValueKey(card.id),
                      imageProvider: NetworkImage(WebServices.getCardUrl(card.filename)),
                      initialScale: PhotoViewComputedScale.contained * 0.8,
                      minScale: PhotoViewComputedScale.contained * 0.5,
                      maxScale: PhotoViewComputedScale.contained * 1.5,
                      //heroAttributes: HeroAttributes(tag: galleryItems[index].id),
                    );
                  }).toList(growable: false),
                  loadingBuilder: (context, event) {
                    return BlurHash(
                      hash: widget.cards[_currentCardIndex].blurHash,
                    );

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
                      //_currentCardIndex = index;
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
            ),
          ),

          // Card Text
          /**() {
            var cardText = widget.cardsTextBottom?.getElement(widget.cards?.elementAt(_currentCardIndex)?.id);

            if (cardText?.isNotEmpty == true)
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(cardText),
              );

            return SizedBox();
          } (),*/

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
                          ...[
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Phrase',
                              ),
                              textInputAction: TextInputAction.done,
                              validator: AppResources.validatorNotEmpty,
                              onFieldSubmitted: (value) => validate(context),
                              onSaved: (value) => _sentence = value,
                            ),
                            AppResources.SpacerSmall,
                          ],

                        // Validate button
                        StreamBuilder<bool>(
                          stream: isBusy,
                          initialData: isBusy.value,
                          builder: (context, snapshot) {
                            return AsyncButton(
                              text: 'Valider',
                              onPressed: widget.cards[_currentCardIndex].id != widget.playerCardID
                                ? () => validate(context)
                                : null,
                              isBusy: snapshot.data,
                            );
                          }
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),

        ],
      ),
    );
  }

  Future<void> validate(BuildContext context) async {
    // Clear focus
    clearFocus(context);   // Keyboard is closed automatically when called from "done" keyboard key, but not in other cases.

    // Validate form
    var form = Form.of(context);
    if (form.validate())
      form.save();
    else
      return;

    // Callback
    try {
      isBusy.add(true);

      await widget.onSelected(widget.cards[_currentCardIndex].id, _sentence);

      // Navigate back
      Navigator.of(context).pop();
    }

    catch (e) {
      isBusy.add(false);
    }
  }

  @override
  void dispose() {
    isBusy.close();
    super.dispose();
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
  int _currentPhaseNumber;

  BuildContext context;

  GamePageBloc({this.context, this.playerName, this.roomName, this.cards}) :
    roomStream = DatabaseService.getRoomStream(roomName) {
    //Subscribe to room modifications
    _roomStreamSubscription = roomStream.listen(onRoomUpdate);

    //Keep screen awake
    Screen.keepOn(true);
  }

  void onRoomUpdate(Room room) {
    print('onRoomUpdate');

    var newPhaseNumber = room.phase?.number;
    if (_currentPhaseNumber != newPhaseNumber) {
      String message;
      if (room.previousPhase?.number == 4)
        message = "Le tour est terminé";
      else if (newPhaseNumber == 2)
        message = "Le conteur s'est décidé";
      else if (newPhaseNumber == 3)
        message = "Place au vote";

      if (message?.isNotEmpty == true)
        showMessage(context, message);

      _currentPhaseNumber = newPhaseNumber;
    }

    var isStoryteller = playerName == room.phase?.storytellerName;

    // TODO prevent calling a function again before it has done.
    // If everyone has chosen a card, go to phase 3
    if (isStoryteller && room.phase.number == Phase.Phase2_cardSelect && room.phase.playedCards.length == room.players.length)
      _toVotePhase(room);

    // If everyone has voted a card, go to phase 4
    if (isStoryteller && room.phase.number == Phase.Phase3_vote && room.phase.votes.values.fold(0, (sum, players) => sum + players.length) == room.players.length)
      _toScoresPhase(room);
  }

  List<CardData> getCardDataFromIDs(Iterable<int> cardsIDs) => cardsIDs?.map((id) => cards[id])?.toList(growable: false);

  final _random = Random();

  /// Draw cards from deck
  List<int> _drawCards(Room room, int quantity) {
    // Build deck (card left to be drawn)
    var deck = cards.keys.toList()..removeAll(room.drawnCards);    // Other way (more expensive ?) : cards.keys.toList()..removeWhere((cardID) => room.drawnCardsIds.contains(cardID));

    // draw cards
    var drawnCards = List.generate(quantity, (_) => deck.removeAt(_random.nextInt(deck.length)));

    // Add to drawnCard list
    room.drawnCards.addAll(drawnCards);

    return drawnCards;
  }
  
  Future<void> startGame(Room room) async {
    // Draw card for each player
    for (var player in room.players.values)
      player.cards = _drawCards(room, 6);

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
    // Shuffle played card
    room.phase.playedCards = Map.fromEntries(room.phase.playedCards.entries.toList(growable: false)..shuffle());    //TODO because order is not guaranteed by Firebase, this may be pointless ?

    // Update phase
    room.phase.number = Phase.Phase3_vote;

    // Directly update DB
    await DatabaseService.savePhase(room.name, room.phase);
  }

  Future<void> voteCard(Room room, int card) async {
    // Vote directly using DB
    await DatabaseService.addVote(room.name, playerName, card);
  }

  Future<void> _toScoresPhase(Room room) async {
    // ---- Count score ----
    var storytellerName = room.phase.storytellerName;
    var storytellerCardID = room.phase.playedCards[storytellerName];
    var votes = room.phase.votes;
    var getCardOwner = (int cardID) => room.players[room.phase.playedCards.entries.firstWhere((entry) => entry.value == cardID).key];

    // If none or all player(s) voted for the storyteller's card
    var storytellerCardVotes = votes[storytellerCardID]?.length ?? 0;
    if (storytellerCardVotes == 0 || storytellerCardVotes == room.players.length - 1) {
      // Give 2 points for each players except main player
      for (var player in room.players.values) {
        if (player.name != storytellerName)
          player.score += 2;
      }

      // Give 1 point to the owner of the card voted by the storyteller
      var storytellerVotedCardID = votes.entries.firstWhere((entry) => entry.value.contains(storytellerName)).key;
      getCardOwner(storytellerVotedCardID).score += 1;
    }

    // If not
    else {
      // For each card vote
      for (var voteEntry in votes.entries) {
        var cardOwner = getCardOwner(voteEntry.key);

        // If it's the storyteller's card
        if (cardOwner.name == storytellerName) {
          // Give 3 points for each player who has voted for the storyteller's card
          voteEntry.value.forEach((playerName) => room.players[playerName].score += 3);

          // Give 3 point for the storyteller
          cardOwner.score += 3;
        }

        // If not
        else {
          // Give 1 point per voter to the owner
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
      var previousStorytellerPosition = room.players[room.previousPhase.storytellerName].position;
      var nextStorytellerPosition = (previousStorytellerPosition % room.players.length) + 1;
      var nextStoryteller = room.players.values.firstWhere((player) => player.position == nextStorytellerPosition).name;
      room.phase = Phase(nextStoryteller);

      // Draw cards
      var drawnCards = _drawCards(room, room.players.length);   // Drawing multiple at once is less expansive.
      room.players.forEach((_, p) => p.cards.add(drawnCards.removeAt(0)));

      // Next turn
      room.turn ++;
    }

    // ---- Update DB -----
    await DatabaseService.saveRoom(room);
  }

  @override
  void dispose() {
    //Keep screen awake
    Screen.keepOn(false);

    _roomStreamSubscription.cancel();
    super.dispose();
  }
}