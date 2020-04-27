import 'package:flutter/widgets.dart';

mixin Disposable {
  bool isDisposed = false;

  @mustCallSuper
  void dispose() {
    isDisposed = true;
  }
}