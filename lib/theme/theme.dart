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
        fontSize: 36.0,
        fontWeight: FontWeight.w300,
        color: surfaceColor,
        height: 1.0,
        fontStyle: FontStyle.italic),
    headlineSmall: GoogleFonts.sourceSerif4(
        fontSize: 24.0,
        fontWeight: FontWeight.w100,
        color: surfaceColor,
        height: 1.0,
        fontStyle: FontStyle.italic),
    displayLarge: GoogleFonts.sortsMillGoudy(
        fontSize: 32,
        fontWeight: FontWeight.w100,
        color: surfaceColor,
        height: 1.0,
        fontStyle: FontStyle.italic),
    displayMedium: GoogleFonts.sortsMillGoudy(
        fontSize: 20,
        fontWeight: FontWeight.w100,
        color: surfaceColor,
        height: 1.0,
        fontStyle: FontStyle.italic),
    displaySmall: GoogleFonts.sortsMillGoudy(
        fontSize: 16,
        fontWeight: FontWeight.w100,
        color: surfaceColor,
        height: 1.0,
        fontStyle: FontStyle.normal),
    bodyLarge: GoogleFonts.sourceSerif4(
        fontSize: 20.0, color: surfaceColor, fontWeight: FontWeight.w200),
    bodyMedium: GoogleFonts.sourceSerif4(
        fontSize: 14.0, color: surfaceColor, fontWeight: FontWeight.w300),
    bodySmall: GoogleFonts.sourceSerif4(
        fontSize: 12.0,
        color: const Color.fromARGB(127, 255, 255, 255),
        fontWeight: FontWeight.w300),
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
  inputDecorationTheme: InputDecorationTheme(
    counterStyle: TextStyle(
      color: Colors.white,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(
        color: const Color.fromARGB(100, 255, 255, 255),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(
        color: const Color.fromARGB(100, 255, 255, 255),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(
        color: Colors.white,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: secondaryColor,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: secondaryColor,
      ),
    ),
    labelStyle: GoogleFonts.sortsMillGoudy(
        color: const Color.fromARGB(100, 255, 255, 255),
        fontSize: 20.0,
        height: 1.0),
    floatingLabelStyle: GoogleFonts.sortsMillGoudy(
        color: const Color.fromARGB(100, 255, 255, 255),
        fontSize: 20.0,
        height: 1.0),
    iconColor: const Color.fromARGB(100, 255, 255, 255),
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
