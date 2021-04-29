import 'dart:collection';
import 'dart:math';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

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

extension ExtendedBehaviorSubject<T> on BehaviorSubject<T> {
  void tryAdd(T value) {
    if (!this.isClosed) {
      this.add(value);
    }
  }

  void addNotNull(T value) {
    if (value != null) {
      this.add(value);
    }
  }

  void addDistinct(T value) {
    if (value != this.value) {
      this.add(value);
    }
  }
}