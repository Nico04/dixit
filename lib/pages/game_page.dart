import 'package:dixit/helpers/tools.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/resources/resources.dart';
import 'package:dixit/services/database_service.dart';
import 'package:flutter/material.dart';

const _pageContentPadding = EdgeInsets.all(15);

class GamePage extends StatefulWidget {
  final String roomName;
  final String playerName;

  const GamePage(this.roomName, this.playerName);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  GamePageBloc _bloc;

  @override
  void initState() {
    _bloc = GamePageBloc(widget.roomName, widget.playerName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await askUserConfirmation(
        context: context,
        title: 'Quitter la partie',
        message: 'Êtes-vous sûr de vouloir quitter la partie en cours ?'
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.playerName} @ ${widget.roomName}'),
        ),
        body: StreamBuilder<Room>(
          stream: _bloc.roomStream,
          builder: (context, snapshot) {
            var room = snapshot.data;
            if (room == null)
              return CircularProgressIndicator();
            
            if (room.turn == 0)
              return WaitingLobby(
                room.players,
                showStartButton: _bloc.playerName == room.players.first.name,
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
}

class WaitingLobby extends StatelessWidget {
  final List<Player> players;
  final bool showStartButton;

  const WaitingLobby(this.players, {this.showStartButton});

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
                onPressed: () {},
              )
            ],

        ],
      ),
    );
  }
}


class GamePageBloc {
  final String roomName;
  final String playerName;

  final Stream<Room> roomStream;

  GamePageBloc(this.roomName, this.playerName) :
    roomStream = DatabaseService.getRoomStream(roomName);
}