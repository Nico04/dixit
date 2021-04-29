import 'package:dixit/resources/resources.dart';
import 'package:flutter/material.dart';

class AsyncButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isBusy;

  const AsyncButton({Key key, this.onPressed, this.text, this.isBusy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: AnimatedCrossFade(
        duration: AppResources.DurationAnimationMedium,
        firstChild: Text(
          text,
          style: TextStyle(
            color: AppResources.ColorRed,
          ),
        ),
        secondChild: SizedBox(
          width: 25,
          height: 25,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: CircularProgressIndicator(),
          )
        ),
        crossFadeState: isBusy != true ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                key: bottomChildKey,
                child: bottomChild,
              ),
              Container(
                key: topChildKey,
                child: topChild,
              )
            ],
          );
        },
      ),
      onPressed: isBusy == true ? null : onPressed,
    );
  }
}
