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

import '_pages.dart';

const _pageContentPadding = EdgeInsets.all(15);

class GamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<GamePageBloc>(
      create: (context) => GamePageBloc(Provider.of<MainPageBloc>(context, listen: false)),
      dispose: (_, bloc) => bloc.dispose(),
      child: Consumer<GamePageBloc>(
        builder: (context, bloc, _) {
          return WillPopScope(
            onWillPop: () async => await askUserConfirmation(
              context: context,
              title: 'Quitter la partie',
              message: 'Êtes-vous sûr de vouloir quitter la partie en cours ?'
            ),
            child: Scaffold(
              appBar: AppBar(
                title: Text('${bloc.mainBloc.playerName} @ ${bloc.mainBloc.roomName}'),
              ),
              body: StreamBuilder<Room>(
                stream: bloc.roomStream,
                builder: (context, snapshot) {
                  var room = snapshot.data;

                  // If data is not available
                  if (room == null)
                    return CircularProgressIndicator();

                  var player = room.players[bloc.mainBloc.playerName];
                  var isHost = player.name == room.players.keys.first;

                  // WaitingLobby
                  if (room.turn == 0)
                    return WaitingLobby(
                      room.players.keys.toList(growable: false),
                      showStartButton: isHost,
                      onStartGame: () => bloc.startGame(room),
                    );

                  var isMainPlayer = player.name == room.phase.mainPlayerName;
                  var phaseNumber = room.phase.number;

                  // Prepare content
                  Color color;
                  String text;
                  bool mustSelectSentence = false;
                  CardPickerSelectCallback onSelectCallback;

                  if (phaseNumber == 1) {
                    color = isMainPlayer ? Colors.greenAccent : Colors.grey;
                    text = isMainPlayer ? 'Choisir une carte, puis une phrase' : 'Attendre';
                    mustSelectSentence = isMainPlayer;
                    if (isMainPlayer)
                      onSelectCallback = (card, sentence) => bloc.setSentence(room, card, sentence);
                  }

                  else if (phaseNumber == 2) {
                    var playerHasSelected = room.phase.playedCards.keys.contains(player.name);
                    var hasActionToDo = !isMainPlayer && !playerHasSelected;
                    color = hasActionToDo ? Colors.greenAccent : Colors.grey;
                    text = hasActionToDo ? 'Choisir une carte :\n${room.phase.sentence}' : 'Attendre';
                    if (hasActionToDo)
                      onSelectCallback = (card, _) => bloc.selectCard(room, card);
                  }

                  else if (phaseNumber == 3) {
                    var playerHasVoted = room.phase.votes.values.any((players) => players.contains(player.name));
                    color = !playerHasVoted ? Colors.greenAccent : Colors.grey;
                    text = !playerHasVoted ? 'Voter pour une carte :\n${room.phase.sentence}' : 'Attendre';
                    if (!playerHasVoted)
                      onSelectCallback = (card, _) => bloc.voteCard(room, card);
                  }

                  // Card Picker
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      // Indications
                      Container(
                        color: color,
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: text != null ? Text(text) : null,
                      ),

                      // Card Picker
                      Expanded(
                        child: CardPicker(
                          cards: room.phase.number == 3 ? room.phase.playedCards.values.toList(growable: false) : player.cards,
                          excludedCard: room.phase.number == 3 ? room.phase.playedCards[player.name] : null,
                          mustSelectSentence: mustSelectSentence,
                          onSelected: onSelectCallback,
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          );
        }
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
                onPressed: onStartGame,
              )
            ],

        ],
      ),
    );
  }
}

typedef CardPickerSelectCallback = void Function(String card, String sentence);

class CardPicker extends StatefulWidget {
  final List<String> cards;
  final String excludedCard;
  final bool mustSelectSentence;
  final CardPickerSelectCallback onSelected;

  const CardPicker({Key key, this.cards, this.onSelected, this.mustSelectSentence, this.excludedCard}) : super(key: key);

  @override
  _CardPickerState createState() => _CardPickerState();
}

class _CardPickerState extends State<CardPicker> {
  int _imageIndex = 0;
  String _sentence;

  @override
  Widget build(BuildContext context) {
    return Consumer<GamePageBloc>(
      builder: (context, bloc, _) {
        return Column(
          children: <Widget>[

            // Image gallery
            Expanded(
              child: Stack(
                children: <Widget>[

                  // Image
                  PhotoViewGallery(
                    scrollPhysics: const BouncingScrollPhysics(),
                    pageOptions: widget.cards.map((card) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: NetworkImage(WebServices.getCardUrl(card)),
                        initialScale: PhotoViewComputedScale.contained * 0.8,
                        minScale: PhotoViewComputedScale.contained * 0.5,
                        maxScale: PhotoViewComputedScale.contained * 1.5,
                        //heroAttributes: HeroAttributes(tag: galleryItems[index].id),
                      );
                    }).toList(growable: false),
                    loadingBuilder: (context, event) => Center(
                      child: Container(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded / event.expectedTotalBytes,
                        ),
                      ),
                    ),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    onPageChanged: (index) {
                      setState(() {
                        _imageIndex = index;
                      });
                    },
                  ),

                  // Indicator
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Text('Carte ${_imageIndex + 1} / ${widget.cards.length}'),
                  ),

                ],
              ),
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
                            onPressed: widget.cards[_imageIndex] != widget.excludedCard
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
    widget.onSelected(widget.cards[_imageIndex], _sentence);
  }
}

class GamePageBloc with Disposable {
  final MainPageBloc mainBloc;

  final Stream<Room> roomStream;
  StreamSubscription<Room> _roomStreamSubscription;

  final List<String> _cardDeck;   // Cards left in the pile/deck

  GamePageBloc(this.mainBloc) :
    roomStream = DatabaseService.getRoomStream(mainBloc.roomName),
    _cardDeck = List.from(mainBloc.availableCards) {
    _roomStreamSubscription = roomStream.listen(onRoomUpdate);
  }

  void onRoomUpdate(Room room) {
    var isMainPlayer = mainBloc.playerName == room.phase?.mainPlayerName;

    // If everyone has chosen a card, go to phase 3
    if (isMainPlayer && room.phase.number == 2 && room.phase.playedCards.length == room.players.length)
      _toPhase(room, 3);

    // If everyone has voted a card, go to phase 4
    if (isMainPlayer && room.phase.number == 3 && room.phase.votes.values.fold(0, (sum, players) => sum + players.length) == room.players.length)
      _toPhase(room, 4);
  }

  final _random = Random();
  String _drawCard() => _cardDeck.removeAt(_random.nextInt(_cardDeck.length));
  
  Future<void> startGame(Room room) async {
    // Draw card for each player
    for (var player in room.players.values)
      player.cards = List.generate(6, (_) => _drawCard());

    // First turn
    room.turn = 1;

    // First phase
    room.phase = Phase(
      room.players.keys.first
    );

    // Save data
    await DatabaseService.saveRoom(room);
  }

  Future<void> setSentence(Room room, String card, String sentence) async {
    // Apply new phase data
    room.phase
      ..sentence = sentence
      ..playedCards[room.phase.mainPlayerName] = card
      ..number = 2;

    // Remove played card and update DB
    await _removePlayedCardAndSaveData(room, card);
  }

  Future<void> selectCard(Room room, String card) async {
    // Apply new phase data
    room.phase.playedCards[mainBloc.playerName] = card;

    // Remove played card and update DB
    await _removePlayedCardAndSaveData(room, card);
  }

  Future<void> _removePlayedCardAndSaveData(Room room, String card) async {
    // Remove played card from player's hand
    var player = room.players[mainBloc.playerName];
    player.cards.remove(card);

    // Update DB
    await DatabaseService.savePhase(room.name, room.phase);
    await DatabaseService.savePlayer(room.name, player);
  }

  Future<void> voteCard(Room room, String card) async {
    // Apply new phase data
    room.phase.votes[card] = [mainBloc.playerName];   //Don't need to merge with other vote as the database update already merge

    // Update DB
    await DatabaseService.savePhase(room.name, room.phase);
  }

  Future<void> _toPhase(Room room, int phaseNumber) async {
    // Apply new phase data
    room.phase.number = phaseNumber;

    // Update DB
    await DatabaseService.savePhaseNumber(room.name, room.phase.number);
  }

  @override
  void dispose() {
    _roomStreamSubscription.cancel();
    super.dispose();
  }
}