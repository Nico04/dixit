import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dixit/resources/resources.dart';
import 'package:flutter/material.dart';

class AsyncButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isBusy;
  final Widget isBusyChild;

  const AsyncButton({Key key, this.onPressed, this.text, this.isBusy, this.isBusyChild}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      color: AppResources.ColorSand,
      child: AnimatedCrossFade(
        duration: AppResources.DurationAnimationMedium,   //Duration(seconds: 3), //
        firstChild: Text(
          text,
          style: TextStyle(
            color: AppResources.ColorRed,
          ),
        ),
        secondChild: isBusyChild,
        crossFadeState: isBusy != true ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
      onPressed: isBusy == true ? null : onPressed,
    );

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
