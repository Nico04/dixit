import 'dart:math';

import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '_pages.dart';

const _pageContentPadding = EdgeInsets.all(15);

class GamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => GamePageBloc(Provider.of<MainPageBloc>(context, listen: false)),
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
                  if (room == null)
                    return CircularProgressIndicator();

                  if (room.turn == 0)
                    return WaitingLobby(
                      room.players,
                      showStartButton: bloc.mainBloc.playerName == room.players.first.name,
                      onStartGame: () => bloc.startGame(room),
                    );

                  return Column(
                    children: <Widget>[
                      Text(room.players.length.toString()),
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
  final List<Player> players;
  final bool showStartButton;
  final VoidCallback onStartGame;

  const WaitingLobby(this.players, {this.showStartButton, this.onStartGame});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Counter
          Text(plural(players.length, 'joueur')),

          // Players
          AppResources.SpacerMedium,
          ...players.map((p) => Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                p.name
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

class CardPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class GamePageBloc {
  final MainPageBloc mainBloc;

  final Stream<Room> roomStream;

  GamePageBloc(this.mainBloc) :
    roomStream = DatabaseService.getRoomStream(mainBloc.roomName);
  
  Future<void> startGame(Room room) async {
    // Draw card for each player
    var random = Random();
    for (var player in room.players)
      player.cards = List.generate(6, (_) => mainBloc.availableCards[random.nextInt(mainBloc.availableCards.length)]);
    
    room.turn = 1;
    
    await DatabaseService.saveRoom(room);
  }
}