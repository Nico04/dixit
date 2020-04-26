import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _bloc = MainPageBloc();

  final _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _textFieldController,
            decoration: InputDecoration(
              labelText: 'Room Name'
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: _bloc.joinRoom,
          ),
          RaisedButton(
            child: Text('Join Room'),
            onPressed: () => _bloc.joinRoom(_textFieldController.text),
          )
        ],
      ),
    );
  }
}

class MainPageBloc {
  final database = FirebaseDatabase.instance.reference();

  void joinRoom(String name) async {
    var roomRef = database.child('rooms').child(name);
    roomRef.keepSynced(true);
    var room = await roomRef.once();
    if (room.value == null) {
      await roomRef.set("new !");
    }

    print('r');
  }
}