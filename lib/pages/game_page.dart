import 'dart:async';
import 'dart:math';

import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:dixit/services/web_services.dart';
import 'package:dixit/widgets/_widgets.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:screen/screen.dart';
import 'package:timeago/timeago.dart' as timeago;

const _pageContentPadding = EdgeInsets.all(15);

class GamePage extends StatelessWidget {
  final String playerName;
  final String roomName;
  final Map<int, CardData> cards;

  const GamePage({Key key, this.playerName, this.roomName, this.cards}) : super(key: key);

  static Future<bool> askExit(BuildContext context) async => await askUserConfirmation(
    context: context,
    title: 'Quitter la partie',
    message: 'Êtes-vous sûr de vouloir quitter la partie en cours ?',
    okText: 'Quitter',
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

                // If data is not available (either not yet available OR room deleted while playing)
                if (room == null) {
                  return Scaffold(
                    body: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircularProgressIndicator(),
                            AppResources.SpacerMedium,
                            Text('Synchronisation en cours'),
                            AppResources.SpacerMedium,
                            RaisedButton(
                              child: Text('Quitter la partie'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Prepare
                Color instructionsColor;
                String instructionsText;
                var phaseNumber = room.phase?.number ?? 0;
                var displayPhase = room.turn >= 2 && phaseNumber <= Phase.Phase1_storytellerSentence ? room.previousPhase : room.phase;

                // Build content
                Widget child = () {
                  // Vars
                  var player = room.players[bloc.playerName];
                  var isHost = player.position == 1;

                  // WaitingLobby
                  if (room.startDate == null) {
                    instructionsColor = _buildInstructionsColor(isHost);
                    instructionsText = isHost
                      ? "Commencez la partie quand tout le monde est là"
                      : "En attente de ${room.players.values.firstWhere((player) => player.position == 1).name}";

                    return WaitingLobby(
                      room.players.keys.toList(growable: false),
                      showStartButton: isHost,
                      onStartGame: (endGameScore) async => await bloc.startGame(room, endGameScore),
                    );
                  }

                  // Vars
                  var isStoryteller = player.name == room.phase?.storytellerName;

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
                  else if (phaseNumber == 0) {
                    instructionsColor = _buildInstructionsColor(false);
                    instructionsText = "Partie terminée !";
                  }

                  var displayPlayedCards = phaseNumber != Phase.Phase2_cardSelect
                    ? displayPhase.playedCards
                    : () {
                        var playedCard = displayPhase.playedCards.getElement(player.name);
                        return playedCard != null ? { player.name: playedCard } : null;
                      } ();

                  // Build Game board
                  return GameBoard(
                    playerCards: bloc.getCardDataFromIDs(player.cards),
                    boardCards: bloc.getCardDataFromIDs(displayPlayedCards?.values)?.map((card) {
                      var displayOwner = displayPlayedCards.keyOf(card.id);
                      if (phaseNumber >= Phase.Phase2_cardSelect && displayOwner != playerName)
                        displayOwner = null;

                      var displayVoters = displayPhase.votes?.getElement(card.id);
                      if (phaseNumber >= Phase.Phase2_cardSelect) {
                        if (displayVoters?.contains(playerName) == true)
                          displayVoters = [playerName];
                        else
                          displayVoters = null;
                      }

                      return _BoardCardData(
                        id: card.id,
                        filename: card.filename,
                        blurHash: card.blurHash,
                        owner: displayOwner,
                        voters: displayVoters,
                      );
                    }),
                    //playedCardID: displayPlayedCards?.getElement(player.name),
                    storytellerName: displayPhase?.storytellerName,
                    onHandCardSelected: onHandCardSelectedCallback,
                    onBoardCardSelected: onBoardCardSelectedCallback,
                    mustChooseSentence: mustChooseSentence,
                  );

                } ();

                // Build page
                return Column(
                  children: <Widget>[

                    // Indications header
                    GameHeader(
                      storytellerText: () {
                        var storytellerName = displayPhase?.storytellerName;
                        if (storytellerName == null)
                          return roomName;
                        return storytellerName == playerName
                          ? "Vous êtes le conteur"
                          : "Le conteur est $storytellerName";
                      } (),
                      sentence: displayPhase?.sentence,
                      instructionsColor: instructionsColor,
                      instructions: instructionsText,
                    ),

                    // Content
                    Expanded(
                      child: Provider.value(
                        value: room,
                        child: child,
                      ),
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

  Color _buildInstructionsColor(bool hasTodo) => hasTodo == true ? AppResources.ColorGreen : AppResources.ColorDarkSand;

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
  final String storytellerText;
  final String sentence;
  final String instructions;
  final Color instructionsColor;

  const GameHeader({Key key, this.instructionsColor, this.storytellerText, this.instructions, this.sentence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,     // TODO doesn't work
      color: AppResources.ColorOrange,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[

            // Top
            if (storytellerText?.isNotEmpty == true)
              ...[
                Row(
                  children: <Widget>[

                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: <Widget>[

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
                  ],
                ),
                AppResources.SpacerTiny,
              ],

            // Instructions
            Container(
              color: instructionsColor,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                instructions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaitingLobby extends StatefulWidget {
  final List<String> playersName;
  final bool showStartButton;
  final Future<void> Function(int endGameScore) onStartGame;

  const WaitingLobby(this.playersName, {this.showStartButton, this.onStartGame});

  @override
  _WaitingLobbyState createState() => _WaitingLobbyState();
}

class _WaitingLobbyState extends State<WaitingLobby> {
  double _endGameScore = 30;

  final isBusy = BehaviorSubject.seeded(false);

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
            Text(plural(widget.playersName.length, 'joueur')),

            // Players
            AppResources.SpacerMedium,
            ...widget.playersName.map((p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  p
                ),
              ),
            )).toList(growable: false),

            // Host controls
            if (widget.showStartButton)
              ...[
                Spacer(),

                //
                Text('Partie en ${_endGameScore.toInt()} points'),

                //
                FlutterSlider(
                  values: [_endGameScore],
                  min: 5,
                  max: 50,
                  step: FlutterSliderStep(
                    step: 5
                  ),
                  tooltip: FlutterSliderTooltip(
                    disabled: true,
                    format: (value) => '${double.parse(value).toInt()}',    //Doesn't work, see https://github.com/Ali-Azmoud/flutter_xlider/issues/65
                  ),
                  onDragging: (handlerIndex, lowerValue, upperValue) {
                    setState(() {
                      _endGameScore = lowerValue;
                    });
                  },
                  trackBar: FlutterSliderTrackBar(
                    activeTrackBar: BoxDecoration(
                      color: AppResources.ColorOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  handler: FlutterSliderHandler(
                    decoration: BoxDecoration(
                      color: AppResources.ColorSand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          spreadRadius: 0.2,
                          offset: Offset(0, 1)
                        )
                      ],
                    ),
                  ),
                ),

                // Start button
                AppResources.SpacerMedium,
                StreamBuilder<bool>(
                  stream: isBusy,
                  initialData: isBusy.value,
                  builder: (context, snapshot) {
                    return AsyncButton(
                      text: 'Commencer',
                      onPressed: () {     // TODO min 4 players
                        startAsyncTask(
                          () async => await widget.onStartGame(_endGameScore.toInt()),
                          isBusy,
                          showErrorContext: context
                        );
                      },
                      isBusy: snapshot.data,
                    );
                  }
                ),
              ],

          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    isBusy.close();
    super.dispose();
  }
}

class GameBoard extends StatefulWidget {
  final List<CardData> playerCards;
  final Iterable<_BoardCardData> boardCards;
  final CardPickerSelectCallback onHandCardSelected;
  final CardPickerSelectCallback onBoardCardSelected;
  final bool mustChooseSentence;
  final String storytellerName;

  const GameBoard({Key key, this.playerCards, this.boardCards, this.onHandCardSelected, this.onBoardCardSelected, this.mustChooseSentence, this.storytellerName}) : super(key: key);

  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  int _currentTabIndex = 0;
  PageController _pageController;

  @override
  void initState() {
    _pageController = PageController(initialPage: _currentTabIndex);
    _pageController.addListener(() {
      var currentPage = _pageController.page.round();
      if (currentPage != _currentTabIndex)
      _updateTabIndex(currentPage);
    });
    super.initState();
  }

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
          body: PageView(
            controller: _pageController,
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
                storytellerName: widget.storytellerName,
                playerCardID: widget.boardCards?.firstWhere((card) => card.owner == bloc.playerName, orElse: () => null)?.id,
                onSelected: widget.onBoardCardSelected,
              ),

              // Scores
              Stats(),

            ],
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
                title: Text('Stats'),
              ),
            ],
            currentIndex: _currentTabIndex,
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: AppResources.DurationAnimationMedium,
                curve: Curves.easeInOut
              );
              _updateTabIndex(index);
            },
            showUnselectedLabels: false,
            backgroundColor: AppResources.ColorOrange,
            selectedItemColor: AppResources.ColorRed,
            unselectedItemColor: AppResources.ColorDarkGrey,
          ),
        );
      }
    );
  }

  void _updateTabIndex(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }
}

typedef CardPickerSelectCallback = Future<void> Function(int card, String sentence);

class CardsView extends StatelessWidget {
  final Iterable<CardData> cards;
  final String storytellerName;
  final int playerCardID;
  final bool mustSelectSentence;
  final CardPickerSelectCallback onSelected;

  const CardsView({Key key, this.cards, this.onSelected, this.mustSelectSentence, this.playerCardID, this.storytellerName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GamePageBloc>(
      builder: (context, bloc, _) {
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
          children: cards.map((card) {
            _BoardCardData boardCard;
            if (card is _BoardCardData)
              boardCard = card;

            var isPlayerCard = boardCard?.owner == bloc.playerName;

            return Card(
              margin: EdgeInsets.all(6),
              elevation: 6,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: () {
                  if (storytellerName != null && boardCard?.owner == storytellerName)
                    return BorderSide(
                      color: AppResources.ColorOrange,
                      width: 2.5,
                    );
                  if (boardCard?.owner == bloc.playerName)
                    return BorderSide(
                      color: AppResources.ColorGreen,
                      width: 2.5,
                    );
                  return BorderSide.none;
                } (),
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
                  if (boardCard?.owner?.isNotEmpty == true)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildOverlayZone(
                        Text(isPlayerCard
                          ? 'Ma carte'
                          : boardCard.owner,
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ),

                  // Bottom Text
                  if (boardCard?.voters?.isNotEmpty == true)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildOverlayZone(Wrap(
                        children: boardCard.voters.map((voter) => Padding(
                          padding: const EdgeInsets.all(2),
                          child: TextChip(
                            voter == bloc.playerName ? 'Moi' : voter,
                            color: voter == bloc.playerName
                              ? AppResources.ColorGreen
                              : AppResources.ColorDarkSand,
                          ),
                        )).toList(growable: false),
                      ))
                    ),

                  // Tap detector
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        child: Container(),
                        onTap: () => navigateTo(context, () => CardPicker(
                          cards: cards.toList(growable: false),
                          initialCardID: card.id,
                          playerCardID: playerCardID,
                          mustSelectSentence: mustSelectSentence,
                          onSelected: onSelected,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(growable: false),
          padding: _pageContentPadding,
        );
      }
    );
  }

  Widget _buildOverlayZone(Widget child) {
    return Container(
      color: AppResources.ColorDarkGrey.withOpacity(0.6),
      alignment: Alignment.center,
      padding: EdgeInsets.all(5),
      child: child,
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
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.contained * 1.5,
                      //heroAttributes: HeroAttributes(tag: galleryItems[index].id),
                    );
                  }).toList(growable: false),
                  loadingBuilder: (context, event) {
                    return BlurHash(
                      hash: widget.cards[_currentCardIndex].blurHash,
                    );
                  },
                  backgroundDecoration: const BoxDecoration(
                    color: AppResources.ColorSand,
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

                // Exit button
                Positioned(
                  top: 10,
                  left: 10,
                  child: SafeArea(
                    child: FloatingActionButton(
                      child: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                )

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
      showMessage(context, AppResources.TextError, exception: e);
      if (!isBusy.isClosed && isBusy.value != false)
        isBusy.add(false);
    }
  }

  @override
  void dispose() {
    isBusy.close();
    super.dispose();
  }
}

class Stats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GamePageBloc>(
      builder: (context, bloc, _) {
        return Consumer<Room>(
          builder: (context, room, _) {
            return LayoutBuilder(
              builder: (context, box) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: box.maxHeight,
                    ),
                    child: Padding(
                      padding: _pageContentPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          // Content
                          Column(
                            children: <Widget>[

                              // Scores
                              _buildCard(
                                context: context,
                                icon: Icons.stars,
                                title: 'Scores',
                                child: _buildScores(
                                    room.players.map((playerName, player) => MapEntry(playerName, player.score))
                                ),
                              ),

                              // Previous phase info
                              if (room.previousPhase != null)
                              ...[
                                AppResources.SpacerMedium,
                                _buildCard(
                                  context: context,
                                  icon: Icons.undo,
                                  title: 'Tour précédent',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('Le conteur était '),
                                          Text(
                                            room.previousPhase.storytellerName,
                                            style: TextStyle(fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                      AppResources.SpacerTiny,
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('La phrase était '),
                                          Text(
                                            room.previousPhase.sentence,
                                            style: TextStyle(fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                      AppResources.SpacerSmall,
                                      _buildScores(
                                        room.previousPhase.scores,
                                        delta: true
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Room info
                              AppResources.SpacerMedium,
                              _buildCard(
                                context: context,
                                icon: Icons.info,
                                title: room.name,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(bloc.playerName),
                                    Text('Tour ${room.turn}'),
                                    Text('Partie en ${room.endScore} points'),
                                    Text('${room.players.length} joueurs'),
                                    Text("${room.drawnCards.length} cartes piochées"),
                                    Text('Commencé le ${AppResources.formatterFriendlyDate.format(room.startDate)}'),
                                    if (room.endDate != null)
                                      ...[
                                        Text('Terminé ${timeago.format(room.endDate)}'),
                                        Text('La partie à duré environ ${printDuration(
                                          room.endDate.difference(room.startDate),
                                          locale: frenchLocale,
                                          delimiter: ', ',
                                          conjugation: ' et ',
                                          tersity: DurationTersity.minute
                                        )}')
                                      ],
                                  ],
                                ),
                              ),

                            ],
                          ),

                          // Exit button
                          AppResources.SpacerMedium,
                          Align(
                            alignment: Alignment.centerRight,
                            child: RaisedButton(
                              child: Text('Quitter la partie'),
                              onPressed: () async {
                                if (await GamePage.askExit(context))
                                  Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildCard({ BuildContext context, IconData icon, String title, Widget child }) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null)
                  ...[
                    Icon(
                      icon,
                      size: 15,
                    ),
                    AppResources.SpacerTiny,
                  ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ],
            ),
            AppResources.SpacerSmall,
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildScores(Map<String, int> scores, { bool delta }) {
    return IntrinsicWidth(
      child: Row(
        children: () {
          // Sort by score
          var sortedScores = scores.entries.toList(growable: false)
            ..sort((e1, e2) => e2.value.compareTo(e1.value));

          // Build widgets
          return [
            if (delta != true)
              ...[
                _buildScoreColumn(
                  texts: List.generate(sortedScores.length, (index) => '#${index + 1}'),
                  bold: true,
                ),
                AppResources.SpacerSmall,
              ],
            Flexible(
              child: _buildScoreColumn(
                texts: sortedScores.map((score) => score.key),
              ),
            ),
            AppResources.SpacerSmall,
            _buildScoreColumn(
              texts: sortedScores.map((score) => (delta == true ? '+' : '') + '${score.value} points'),
            ),
          ];
        } (),
      ),
    );
  }

  Widget _buildScoreColumn({ Iterable<String> texts, bool bold }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: texts.map<Widget>((text) => Text(
        text,
        style: bold == true
          ? TextStyle(
              fontWeight: FontWeight.bold,
            )
          : null,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )).toList().insertBetween(AppResources.SpacerTiny),
    );
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
      if (room.previousPhase?.number == Phase.Phase4_scores && newPhaseNumber == Phase.Phase1_storytellerSentence)
        message = "Le tour est terminé";
      else if (newPhaseNumber == Phase.Phase2_cardSelect)
        message = "Le conteur s'est décidé";
      else if (newPhaseNumber == Phase.Phase3_vote)
        message = "Place au vote";
      else if (newPhaseNumber == Phase.Phase4_scores)
        message = "Partie terminée";

      if (message?.isNotEmpty == true)
        showMessage(context, message);

      _currentPhaseNumber = newPhaseNumber;
    }

    // Go to next phase if needed
    _tryToNextPhase(room);
  }

  Future _currentTask;
  Room _pendingTaskRoom;
  Timer _pendingRetry;
  Future<void> _tryToNextPhase(Room room) async {
    print('tryToNextPhase.start');

    // Only if player is storyteller
    if (playerName != room.phase?.storytellerName)
      return;

    // If a task is already running
    if (_currentTask != null) {
      // Add room to be processed ASAP (just keep the more recent one)
      print('tryToNextPhase.addPending');
      _pendingTaskRoom = room;
      return;
    }

    // Clean retry timer
    _pendingRetry?.cancel();
    _pendingRetry = null;

    // Start task
    try {
      _currentTask = _toNextPhase(room);
      await _currentTask;
    }

    // Task failed
    catch(e) {
      print('tryToNextPhase.Error : $e');

      // Retry after a delay
      if (_pendingTaskRoom == null)
        _pendingRetry = Timer(Duration(seconds: 5), () => _tryToNextPhase(room));
    }

    // Clean
    print('tryToNextPhase.clean');
    _currentTask = null;

    // Execute pending task
    if (_pendingTaskRoom != null) {
      print('tryToNextPhase.startPending');
      _tryToNextPhase(_pendingTaskRoom);
      _pendingTaskRoom = null;
    }
  }

  Future<void> _toNextPhase(Room room) async {
    // If everyone has chosen a card, go to phase 3
    if (room.phase.number == Phase.Phase2_cardSelect && room.phase.playedCards.length == room.players.length)
      await _toVotePhase(room);

    // If everyone has voted a card, go to phase 4
    else if (room.phase.number == Phase.Phase3_vote && room.phase.votes.values.fold(0, (sum, players) => sum + players.length) == room.players.length)
      await _toScoresPhase(room);
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
  
  Future<void> startGame(Room room, int endGameScore) async {
    // Draw card for each player
    for (var player in room.players.values)
      player.cards = _drawCards(room, 6);

    // Room info
    room.startDate = DateTime.now();
    room.endScore = endGameScore;
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
    await DatabaseService.savePlayer(room.name, player);
    await DatabaseService.savePhase(room.name, room.phase);
  }

  Future<void> _toVotePhase(Room room) async {
    // => No need to shuffle played card because it's sorted by CardID (which is arbitrary)
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
    var getCardOwnerName = (int cardID) => room.phase.playedCards.keyOf(cardID);

    // Init this phase's scores
    var scores = room.phase.scores = room.players.map((playerName, _) => MapEntry(playerName, 0));

    // If none or all player(s) voted for the storyteller's card
    var storytellerCardID = room.phase.playedCards[storytellerName];
    var storytellerCardVotes = votes[storytellerCardID]?.length ?? 0;
    if (storytellerCardVotes == 0 || storytellerCardVotes == room.players.length - 1) {
      // Give 2 points for each players except main player
      for (var playerName in scores.keys) {
        if (playerName != storytellerName)
          scores[playerName] += 2;
      }

      // Give 1 point to the owner of the card voted by the storyteller
      var storytellerVotedCardID = votes.entries.firstWhere((entry) => entry.value.contains(storytellerName)).key;
      scores[getCardOwnerName(storytellerVotedCardID)] += 1;
    }

    // If not
    else {
      // For each card vote
      for (var voteEntry in votes.entries) {
        var cardOwnerName = getCardOwnerName(voteEntry.key);

        // If it's the storyteller's card
        if (cardOwnerName == storytellerName) {
          // Give 3 points for each player who has voted for the storyteller's card
          voteEntry.value.forEach((playerName) => scores[playerName] += 3);

          // Give 3 point for the storyteller
          scores[storytellerName] += 3;
        }

        // If not
        else {
          // Give 1 point per voter to the owner
          voteEntry.value.forEach((playerName) => scores[cardOwnerName] += 1);
        }
      }
    }

    // Sum phase's scores to players's score
    room.players.forEach((playerName, player) => player.score += scores[playerName]);

    // ---- Apply new phase data -----
    // Phase number
    room.phase.number = Phase.Phase4_scores;

    // Move phase
    room.previousPhase = room.phase;
    room.phase = null;

    // End game
    if (room.players.values.any((player) => player.score >= room.endScore)) {
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

    //Clean up
    _roomStreamSubscription.cancel();
    super.dispose();
  }
}

class _BoardCardData extends CardData {
  final String owner;
  final Iterable<String> voters;

  const _BoardCardData({int id, String filename, String blurHash, this.owner, this.voters}) : super(
    id,
    filename,
    blurHash,
  );
}