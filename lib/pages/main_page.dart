import 'package:dixit/utils/_utils.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/pages/_pages.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:dixit/services/storage_service.dart';
import 'package:dixit/services/web_services.dart';
import 'package:dixit/utils/runtime_info.dart';
import 'package:dixit/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
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
    final playerName = StorageService.readPlayerName();
    if (playerName != null)
      _playerNameController.text = playerName;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClearFocusBackground(
      child: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[

            // Header
            Material(
              elevation: 6,
              child: Image.asset('assets/logo.png'),
            ),

            // Content
            Expanded(
              child: FillRemainsScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    child: Builder(
                      builder: (context) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            // Top
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[

                                // Title
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Bienvenue !',
                                        style: Theme.of(context).textTheme.headline6,
                                      ),
                                    ),
                                    StreamBuilder<String>(
                                      stream: _bloc.appVersion,
                                      initialData: _bloc.appVersion.value,
                                      builder: (context, snapshot) {
                                        final appVersion = snapshot.data;
                                        return Text(
                                          isStringNullOrEmpty(appVersion) ? '' : 'v$appVersion',
                                          textAlign: TextAlign.end,
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                // Instructions
                                AppResources.SpacerMedium,
                                Text('Pour rejoindre une partie, entrez votre pseudo et le nom de la partie'),

                                // Pseudo
                                AppResources.SpacerLarge,
                                TextFormField(
                                  controller: _playerNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Pseudo'
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: AppResources.validatorLengthAndSpecialChar,
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
                                  validator: AppResources.validatorLengthAndSpecialChar,
                                  onFieldSubmitted: (value) => _bloc.validate(context),
                                  onSaved: (value) => _bloc.roomName = value,
                                ),
                              ],
                            ),

                            // Bottom
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                // Button or status
                                AppResources.SpacerLarge,
                                StreamBuilder<bool>(
                                  stream: _bloc.isBusy,
                                  initialData: _bloc.isBusy.value,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError)
                                      return Column(
                                        children: <Widget>[
                                          Tooltip(
                                            child: Text(r'/!\ Echec de la synchronisation des données /!\'),
                                            message: snapshot.error.toString(),
                                          ),
                                          ElevatedButton(
                                            child: Text('Re-essayer'),
                                            onPressed: _bloc.init,
                                          )
                                        ],
                                      );

                                    return AsyncButton(
                                      text: 'Rejoindre la partie',
                                      onPressed: () => _bloc.validate(context),
                                      isBusy: snapshot.data,
                                    );
                                  },
                                ),

                              ],
                            ),

                          ],
                        );
                      },
                    ),
                  ),
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

  final appVersion = BehaviorSubject.seeded('');
  Map<int, CardData> cards;     // All existing cards

  final isBusy = BehaviorSubject.seeded(true);

  MainPageBloc() {
    init();
    getAppVersion();
  }

  Future<void> init() async {
    try {
      isBusy.add(true);   // Needed for when re-trying
      cards = await WebServices.getCardsNames();
      if (isBusy.value != false)
        isBusy.tryAdd(false);
    } catch (e) {
      isBusy.addError(e);
    }
  }

  Future<void> getAppVersion() async {
    if (RuntimeInfo.isWeb) return;
    final v = (await PackageInfo.fromPlatform())?.version;
    appVersion.tryAdd(v);
  }

  Future<void> validate(BuildContext context) async {
    // Clear focus
    clearFocus(context);   // Keyboard is closed automatically when called from "done" keyboard key, but not in other cases.

    // Validate form
    final form = Form.of(context);
    if (form.validate())
      form.save();
    else
      return;

    // Remove spaces
    roomName = roomName.trim();
    playerName = playerName.trim();

    // Join room
    await startAsyncTask(
      () async {
        isBusy.add(true);

        await DatabaseService.editRoomInTransaction(roomName, (room) {
          var hasBeenModified = false;

          // If room is new, create it
          if (room == null) {
            room = Room(roomName);
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
            // player.deviceID != null is useful to be able to force join by overriding database
            if (player.deviceID != App.deviceID && player.deviceID != null)
              throw ExceptionWithMessage("Impossible de changer d'appareil lors d'une partie en cours");
          }

          // Update fields
          roomName = room.name;
          playerName = player.name;

          // Save data to DB
          return hasBeenModified ? room : null;
        });

        // Save player name locally
        await StorageService.savePlayerName(playerName);

        // Go to room
        navigateTo(context, () => GamePage(
          playerName: playerName,
          roomName: roomName,
          cards: cards,
        ));
      },
      isBusy,
      showErrorContext: context,
    );
  }

  @override
  void dispose() {
    appVersion.close();
    isBusy.close();
    super.dispose();
  }
}