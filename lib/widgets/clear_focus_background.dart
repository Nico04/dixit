import 'package:dixit/helpers/tools.dart';
import 'package:flutter/material.dart';

class ClearFocusBackground extends StatelessWidget {
  final Widget child;

  const ClearFocusBackground({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => clearFocus(context),
      child: child,
    );
  }
}
