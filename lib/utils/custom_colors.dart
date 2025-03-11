import 'package:flutter/cupertino.dart';

class CustomCupertinoDynamicColor extends CupertinoDynamicColor {
  const CustomCupertinoDynamicColor({
    required super.color,
    required super.darkColor,
    required super.highContrastColor,
    required super.darkHighContrastColor,
    required super.elevatedColor,
    required super.darkElevatedColor,
    required super.highContrastElevatedColor,
    required super.darkHighContrastElevatedColor,
  });

  @override
  int toARGB32() {
    return value;
  }
}
