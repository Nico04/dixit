import 'package:dixit/resources/resources.dart';
import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: AppResources.ColorRed,
    accentColor: AppResources.ColorDarkSand,
    backgroundColor: AppResources.ColorSand,
    scaffoldBackgroundColor: AppResources.ColorSand,
    cardTheme: CardTheme(
      color: AppResources.ColorOrange,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      buttonColor: AppResources.ColorDarkSand,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _shapeRoundedRectangleSmall,
        primary: AppResources.ColorDarkSand,
        onPrimary: Colors.black,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: _shapeRoundedRectangleSmall,
        primary: AppResources.ColorDarkSand,
        textStyle: TextStyle(color: AppResources.ColorDarkGrey),
      ),
    ),
  );
}

const _shapeRoundedRectangleSmall = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(5)), // Can't use short version BorderRadius.circular(15) because it's not const
);