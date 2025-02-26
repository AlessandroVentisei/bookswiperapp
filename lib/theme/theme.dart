import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final Color primaryColor = Color(0xFF373F47);
final Color secondaryColor = Color(0xFFAAAE7F);
final Color tertiaryColor = Color(0xFFD0D6B3);
final Color backgroundColor = Color(0xFFF7F7F7);
final Color surfaceColor = Color(0xFFEFEFEF);

final ThemeData appTheme = ThemeData(
  visualDensity: VisualDensity.adaptivePlatformDensity,
  textTheme: TextTheme(
    headlineLarge: GoogleFonts.sourceSerif4(
        fontSize: 64.0,
        fontWeight: FontWeight.w100,
        color: surfaceColor,
        fontStyle: FontStyle.italic,
        height: 1.0),
    headlineMedium: GoogleFonts.sourceSerif4(
        fontSize: 48.0,
        fontWeight: FontWeight.w100,
        color: surfaceColor,
        height: 1.0,
        fontStyle: FontStyle.italic),
    bodyLarge: GoogleFonts.sourceSerif4(
        fontSize: 20.0, color: surfaceColor, fontWeight: FontWeight.w200),
  ),
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
    color: primaryColor,
    titleTextStyle: ThemeData().textTheme.headlineMedium,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(secondaryColor),
      textStyle: WidgetStateProperty.all<TextStyle>(
        TextStyle(
          color: Colors.white,
        ),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      alignment: Alignment.center,
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.fromLTRB(24, 18, 24, 12)),
      backgroundColor:
          MaterialStateProperty.all<Color>(Color.fromARGB(40, 239, 239, 239)),
      foregroundColor: MaterialStateProperty.all<Color>(surfaceColor),
      shape: MaterialStateProperty.all<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      side: MaterialStateProperty.all<BorderSide>(
        BorderSide(
          color: surfaceColor,
          width: 1.0,
          style: BorderStyle.solid,
        ),
      ),
      textStyle: WidgetStateProperty.all<TextStyle>(
        GoogleFonts.sortsMillGoudy(
            color: Colors.white, fontSize: 20.0, height: 1.0),
      ),
    ),
  ),
  colorScheme: ColorScheme(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: surfaceColor,
    background: primaryColor,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black,
    onBackground: Colors.black,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
);
