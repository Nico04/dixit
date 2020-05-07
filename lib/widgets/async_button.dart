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
      color: AppResources.ColorDarkSand,
      child: AnimatedCrossFade(
        duration: AppResources.DurationAnimationMedium,   //Duration(seconds: 3), //
        firstChild: Text(
          text,
          style: TextStyle(
            color: AppResources.ColorRed,
          ),
        ),
        secondChild: isBusyChild ?? CircularProgressIndicator(),
        crossFadeState: isBusy != true ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
      onPressed: isBusy == true ? null : onPressed,
    );
  }
}
