import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppResources {
  // Color
  static const ColorSand = Color(0xFFF0DCA1);
  static const ColorDarkSand = Color(0xFFE0B255);
  static const ColorOrange = Color(0xFFE29644);
  static const ColorRed = Color(0xFF942B28);
  static const ColorDarkGrey = Color(0xFF6E654A);
  static const ColorGreen = Color(0xFF4EA8B2);

  // Spacer
  static const SpacerLarge = SizedBox(width: 20, height: 20);
  static const SpacerMedium = SizedBox(width: 15, height: 15);
  static const SpacerSmall = SizedBox(width: 10, height: 10);
  static const SpacerTiny = SizedBox(width: 5, height: 5);

  // Duration
  static const DurationAnimationMedium = const Duration(milliseconds: 250);
  static const DurationAnimationShort = const Duration(milliseconds: 150);

  // Validator
  static final validatorNotEmpty = (String value) => value?.isNotEmpty != true ? "Obligatoire" : null;

  //Formatter
  static final formatterFriendlyDate = DateFormat("d MMM yyyy 'à' HH'h'mm");
}