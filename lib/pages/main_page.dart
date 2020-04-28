import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/pages/_pages.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:dixit/services/storage_service.dart';
import 'package:dixit/services/web_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _bloc = MainPageBloc();

  final _playerNameController = TextEditingController();
  final _roomNameFocus = FocusNode();

  @override
  void initState() {
    var playerName = StorageService.readPlayerName();
    if (playerName != null)
      _playerNameController.text = playerName;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          child: Builder(
            builder: (context) {
              return Column(
                children: <Widget>[
                  TextFormField(
                    controller: _playerNameController,
                    decoration: InputDecoration(
                      labelText: 'Pseudo'
                    ),
                    textInputAction: TextInputAction.next,
                    validator: AppResources.validatorNotEmpty,
                    onFieldSubmitted: (value) => FocusScope.of(context).requestFocus(_roomNameFocus),
                    onSaved: (value) => _bloc.playerName = value,
                  ),
                  AppResources.SpacerSmall,
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nom de la partie'
                    ),
                    textInputAction: TextInputAction.done,
                    focusNode: _roomNameFocus,
                    validator: (value) => AppResources.validatorNotEmpty(value) ?? (value == 'length' ? 'Invalide' : null),
                    onFieldSubmitted: (value) => _bloc.validate(context),
                    onSaved: (value) => _bloc.roomName = value,
                  ),
                  AppResources.SpacerMedium,
                  StreamBuilder<bool>(
                    stream: _bloc.isReady,
                    initialData: _bloc.isReady.value,
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return Column(
                          children: <Widget>[
                            Tooltip(
                              child: Text('Une erreur est survenue'),
                              message: snapshot.error.toString(),
                            ),
                            RaisedButton(
                              child: Text('Re-essayer'),
                              onPressed: _bloc.init,
                            )
                          ],
                        );

                      if (snapshot.data != true)
                        return Column(
                          children: <Widget>[
                            Text('Le jeu est en cours de préparation'),
                            CircularProgressIndicator(),
                          ],
                        );

                      return RaisedButton(
                        child: Text('Rejoindre partie'),
                        onPressed: () => _bloc.validate(context),
                      );
                    }
                  )
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}

class MainPageBloc with Disposable {
  String playerName;
  String roomName;

  Map<int, CardData> cards;     // All existing cards

  final isReady = BehaviorSubject.seeded(false);

  MainPageBloc() {
    init();
  }

  Future<void> init() async {
    try {
      isReady.add(false);   // Needed for when re-trying
      cards = await WebServices.getCardsNames();
      isReady.add(true);
    } catch (e) {
      isReady.addError(e);
    }
  }

  void validate(BuildContext context) async {
    // Clear focus
    clearFocus(context);   // Keyboard is closed automatically when called from "done" keyboard key, but not in other cases.

    // Validate form
    var form = Form.of(context);
    if (form.validate())
      form.save();
    else
      return;

    // Save player name locally
    StorageService.savePlayerName(playerName);    // Do not need to await

    // Get room
    var room = await DatabaseService.getRoom(roomName);
    if (room == null)
      room = Room(roomName, cards.keys.toList());
    else
      roomName = room.name;   // Update field with true value (may be normalized)

    // Get player
    var player = room.players.values.firstWhere((p) => p.name.normalized == playerName.normalized, orElse: () => null);
    if (player == null) {
      //TODO handle if same playerName is submitted on 2 different devices
      if (room.isGameStarted) {
        showMessage(context, 'Impossible de rejoindre une partie en cours', isError: true);
        return;
      }

      player = Player(playerName);
      room.players[player.name] = player;
      await DatabaseService.saveRoom(room);
    } else {
      playerName = player.name;
    }

    // Go to room
    navigateTo(context, () => GamePage(
      playerName: playerName,
      roomName: roomName,
      cards: cards,
    ));
  }

  @override
  void dispose() {
    isReady.close();
    super.dispose();
  }
}