import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dixit/resources/resources.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AsyncButton extends StatelessWidget {
  final String text;
  final AsyncCallback onPressed;

  const AsyncButton({Key key, this.onPressed, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ArgonButton(
      height: 40,
      width: 300,
      minWidth: 40,
      borderRadius: 5,
      color: AppResources.ColorSand,
      child: Text(
        text,
        style: TextStyle(
          color: AppResources.ColorRed,
        ),
      ),
      loader: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FittedBox(
          child: CircularProgressIndicator(),
        ),
      ),
      onTap: onPressed != null
        ? (startLoading, stopLoading, btnState) async {
            if(btnState == ButtonState.Idle){
              startLoading();
              await onPressed();
              stopLoading();
            }
          }
        : null,
    );
  }
}
