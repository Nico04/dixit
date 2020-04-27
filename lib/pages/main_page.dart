import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/pages/_pages.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _bloc = MainPageBloc();

  final _roomNameFocus = FocusNode();

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
                  RaisedButton(
                    child: Text('Rejoindre partie'),
                    onPressed: () => _bloc.validate(context),
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

class MainPageBloc {
  String playerName;
  String roomName;

  void validate(BuildContext context) async {
    // Clear focus
    clearFocus(context);   // Keyboard is closed automatically when called from "done" keyboard key, but not in other cases.

    // Validate form
    var form = Form.of(context);
    if (form.validate())
      form.save();
    else
      return;

    // Get room
    var room = await DatabaseService.getRoom(roomName);
    if (room == null)
      room = Room(roomName);

    // Get player
    var player = room.players.firstWhere((p) => p.name.normalized == playerName.normalized, orElse: () => null);
    if (player == null) {
      //TODO handle if same playerName is submitted on 2 different devices
      if (room.isGameStarted) {
        showMessage(context, 'Impossible de rejoindre une partie en cours', isError: true);
        return;
      }

      player = Player(playerName);
      room.players.add(player);
      await DatabaseService.saveRoom(room);
    }

    // Go to room
    navigateTo(context, () => GamePage(
      room.name,
      player.name,
    ));
  }
}