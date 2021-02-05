import 'dart:collection';
import 'dart:math';

import 'package:diacritic/diacritic.dart';
import 'package:dixit/resources/resources.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

Future<T> navigateTo<T extends Object>(BuildContext context, Widget Function() builder, {int removePreviousRoutesAmount, bool clearHistory = false}) async {
  if (clearHistory == true && removePreviousRoutesAmount != null)
    throw ArgumentError("clearHistory and removePreviousRoutesAmount cannot be both set at the same");

  final route = MaterialPageRoute<T>(
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
  final mainPageContext = Scaffold.maybeOf(context)?.context;
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
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 70),
        position: FlashPosition.bottom,
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
Future<bool> askUserConfirmation({ BuildContext context, String title, String message, String okText }) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: TextStyle(color: AppResources.ColorRed),
      ),
      backgroundColor: AppResources.ColorSand,
      content: Text(message),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Annuler',
            style: TextStyle(color: AppResources.ColorDarkGrey),
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FlatButton(
          child: Text(
            okText,
            style: TextStyle(color: AppResources.ColorRed),
          ),
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

Future<void> startAsyncTask(AsyncCallback action, BehaviorSubject<bool> isBusyStream, { BuildContext showErrorContext}) async {
  try {
    isBusyStream.add(true);
    await action();
  } catch (e) {
    if (showErrorContext != null)
      showMessage(showErrorContext, AppResources.TextError, exception: e);
  } finally {
    if (!isBusyStream.isClosed && isBusyStream.value != false)
      isBusyStream.add(false);
  }
}

bool isStringNullOrEmpty(String s) => s == null || s.isEmpty;

String plural(int count, String input) => '$count $input${count > 1 ? 's' : ''}';

DateTime dateFromString(String dateString) => DateTime.tryParse(dateString ?? '')?.toLocal();

String dateToString(DateTime date) => date?.toUtc()?.toIso8601String();

/// Compares two iterables for deep equality.
/// Copied from flutter's listEquals()
///
/// Returns true if the iterables are both null, or if they are both non-null, have
/// the same length, and contain the same members in the same order. Returns
/// false otherwise.
///
/// The term "deep" above refers to the first level of equality: if the elements
/// are maps, lists, sets, or other collections/composite objects, then the
/// values of those elements are not compared element by element unless their
/// equality operators ([Object.operator==]) do so.
bool iterableEquals<T>(Iterable<T> a, Iterable<T> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  if (identical(a, b))
    return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a.elementAt(index) != b.elementAt(index))
      return false;
  }
  return true;
}

extension ExtendedString on String {
  /// Normalize a string by removing diacritics and transform to lower case
  String get normalized => removeDiacritics(this.toLowerCase());

  /// Returns a new string in which the last occurrence of [from] in this string is replaced with [to]
  String replaceLast(String from, String to) {
    return this.replaceFirst(from, to, this.lastIndexOf(from));
  }
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
  ///
  V getElement(K key) => this[key];

  /// Returns the first key of [value], or null
  K keyOf(V value) => this.entries.firstWhere((entry) => entry.value == value, orElse: () => null)?.key;

  /// Return a LinkedHashMap sorted using [compare] function
  LinkedHashMap<K, V> sorted([int compare(MapEntry<K, V> a, MapEntry<K, V> b)]) {
    if (this.length <= 1) return this;
    final sortedEntries = this.entries.toList(growable: false)..sort(compare);
    return LinkedHashMap.fromEntries(sortedEntries);
  }
}

extension ExtendedList<T> on List<T> {
  void removeAll(Iterable<T> values) {
    for (var value in values)
      this.remove(value);
  }
}

extension ExtendedWidgetList on List<Widget> {
  /// Insert [widget] between each member of this list
  List<Widget> insertBetween(Widget widget) {
    if (this.length > 1) {
      for (var i = this.length - 1; i > 0 ; i--)
        this.insert(i, widget);
    }

    return this;
  }
}