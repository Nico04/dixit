import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/pages/_pages.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:dixit/services/storage_service.dart';
import 'package:dixit/services/web_services.dart';
import 'package:dixit/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../main.dart';

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
      body: ClearFocusBackground(
        child: Column(
          children: <Widget>[

            // Header
            Material(
              elevation: 6,
              child: Image.asset('assets/logo.png'),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                child: Builder(
                  builder: (context) {
                    return Column(
                      children: <Widget>[

                        // Instructions
                        Text('Pour rejoindre une partie, entrez votre pseudo et le nom de la partie'),

                        // Pseudo
                        AppResources.SpacerLarge,
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

                        // Room
                        AppResources.SpacerSmall,
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Nom de la partie',
                          ),
                          textInputAction: TextInputAction.done,
                          focusNode: _roomNameFocus,
                          validator: (value) => AppResources.validatorNotEmpty(value) ?? (value == 'length' ? 'Invalide' : null),
                          onFieldSubmitted: (value) => _bloc.validate(context),
                          onSaved: (value) => _bloc.roomName = value,
                        ),

                        // Button or status
                        AppResources.SpacerLarge,
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

                            return AsyncButton(
                              text: 'Rejoindre partie',
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
          ],
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

  Future<void> validate(BuildContext context) async {
    await Future.delayed(Duration(seconds: 4));
    return;

    // Clear focus
    clearFocus(context);   // Keyboard is closed automatically when called from "done" keyboard key, but not in other cases.

    // Validate form
    var form = Form.of(context);
    if (form.validate())
      form.save();
    else
      return;

    // Remove spaces
    roomName = roomName.trim();
    playerName = playerName.trim();

    // Join room
    try {
      await DatabaseService.editRoomInTransaction(roomName, (room) {
        var hasBeenModified = false;

        // If room is new, create it
        if (room == null) {
          room = Room(roomName, cards.keys.toList());     // TODO save card only at turn 1, not now ?
          hasBeenModified = true;
        }

        // Get player
        var player = room.players.values.firstWhere((p) => p.name.normalized == playerName.normalized, orElse: () => null);

        // If this player is new to the room
        if (player == null) {
          if (room.isGameStarted)
            throw ExceptionWithMessage("Impossible d'ajouter un nouveau joueur sur une partie en cours");

          player = Player(App.deviceID, playerName, room.players.length + 1);
          room.players[player.name] = player;
          hasBeenModified = true;
        }

        // If player is not new to the room
        else {
          // Can't join game if user has changed device. This is to prevent connecting to multiple devices with the same playerName
          if (player.deviceID != App.deviceID)
            throw ExceptionWithMessage("Impossible de changer d'appareil lors d'une partie en cours");
        }

        // Update fields
        roomName = room.name;
        playerName = player.name;

        // Save data to DB
        return hasBeenModified ? room : null;
      });

      // Save player name locally
      StorageService.savePlayerName(playerName);    // Do not need to await

      // Go to room
      // TODO if 2 devices with same values join at the same time, they both go the the waiting lobby with just one player. Just getRoom(fromServer: true) before navigation ?
      navigateTo(context, () => GamePage(
        playerName: playerName,
        roomName: roomName,
        cards: cards,
      ));
    }

    catch (e) {
      showMessage(context, e.toString(), isError: true);
      return;
    }
  }

  @override
  void dispose() {
    isReady.close();
    super.dispose();
  }
}