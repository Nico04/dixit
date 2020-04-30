import 'dart:collection';
import 'dart:math';

import 'package:diacritic/diacritic.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

Future<T> navigateTo<T extends Object>(BuildContext context, Widget Function() builder, {int removePreviousRoutesAmount, bool clearHistory = false}) async {
  if (clearHistory == true && removePreviousRoutesAmount != null)
    throw ArgumentError("clearHistory and removePreviousRoutesAmount cannot be both set at the same");

  var route = MaterialPageRoute<T>(
    builder: (context) => builder()
  );

  if (clearHistory != true && removePreviousRoutesAmount == null) {
    return await Navigator.of(context).push(route);
  } else {
    int removedCount = 0;
    return await Navigator.of(context).pushAndRemoveUntil(route,
      (r) => clearHistory != true &&
      (removePreviousRoutesAmount != null && removedCount++ >= removePreviousRoutesAmount)
    );
  }
}

//Store last controller to be able to dismiss it
FlashController _messageController;

/// Display a message to the user, like a SnackBar
Future<void> showMessage(BuildContext context, String message, {bool isError, Object exception, int durationInSeconds}) async {
  isError ??= exception == null ? false : true;

  //Try to get higher level context, so the Flash message's position is relative to the phone screen (and not a child widget)
  var mainPageContext = Scaffold.of(context, nullOk: true)?.context;
  if (mainPageContext != null)
    context = mainPageContext;

  //Dismiss previous message
  _messageController?.dismiss();

  //Display new message
  await showFlash(
    context: context,
    duration: Duration(seconds: durationInSeconds ?? 4),
    builder: (context, controller) {
      _messageController = controller;

      return Flash(
        controller: controller,
        backgroundColor: isError ? Colors.red : Colors.white,
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        position: FlashPosition.top,
        horizontalDismissDirection: HorizontalDismissDirection.horizontal,
        borderRadius: BorderRadius.circular(8.0),
        boxShadows: kElevationToShadow[8],
        onTap: exception == null
          ? () => controller.dismiss()
          : null,
        child: FlashBar(
          message: Center(
            child: Text(
              message,
            ),
          ),
          primaryAction: exception == null
            ? null
            : FlatButton(
                child: Text('Détails'),
                textColor: Colors.white,
                onPressed: () {
                  controller.dismiss();
                  return showDialog(
                    context: context,     // context and NOT parent context must be used, otherwise it may throw error
                    builder: (context) => AlertDialog(
                      title: Text(message),
                      content: Text(exception.toString()),
                    )
                  );
                },
              )
        ),
      );
    }
  );

  _messageController = null;
}

/// Ask for user confirmation
/// Return false if user cancel or dismiss
/// Return true AFTER calling onUserConfirmed if user said yes
Future<bool> askUserConfirmation({BuildContext context, String title, String message}) async {
  var answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        FlatButton(
          child: Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FlatButton(
          child: Text('OK'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    )
  );

  return answer == true;
}

void clearFocus(BuildContext context) {
  /// Using FocusScope.of(context).unfocus() is more recommended but in some cases is makes the keyboard blink :
  /// - Validate the form with the 'done' keyboard key, then navigator.push() will make the first form field take the focus and open the keyboard
  /// see https://github.com/flutter/flutter/issues/48158
  FocusScope.of(context).requestFocus(FocusNode());
}

String plural(int count, String input) => '$count $input${count > 1 ? 's' : ''}';

DateTime dateFromString(String dateString) => DateTime.tryParse(dateString ?? '')?.toLocal();

String dateToString(DateTime date) => date?.toUtc()?.toIso8601String();

extension ExtendedString on String {
  /// Normalize a string by removing diacritics and transform to lower case
  String get normalized => removeDiacritics(this.toLowerCase());
}

extension ExtendedRandom on Random {
  /// Generates a non-negative random integer uniformly distributed in the range
  /// from 0, inclusive, to [max], exclusive.
  ///
  /// Implementation note: The default implementation supports [max] values
  /// between 1 and (1<<32) inclusive.
  int nextIntExtended(int max) {
    //if ()
    return (this.nextDouble() * max).toInt();
  }
}

extension ExtendedMap<K, V> on Map<K, V> {
  /// Return a LinkedHashMap sorted using [compare] function
  LinkedHashMap<K, V> sorted([int compare(MapEntry<K, V> a, MapEntry<K, V> b)]) {
    var sortedEntries = this.entries.toList(growable: false)..sort(compare);
    return LinkedHashMap.fromEntries(sortedEntries);
  }
}