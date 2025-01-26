import 'dart:math';

import 'package:flutter/material.dart';

void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(message),
    ),
  );
}

int getRandomInt(int min, int max) {
  final random = Random();
  return min + random.nextInt(max - min + 1);
}

String getSubstringBeforeFirstDash(String input) {
  // int dashIndex = input.indexOf('-');
  // if (dashIndex == -1) {
  //   return input; // No dash found, return the whole string
  // }
  // return input.substring(0, dashIndex);
  return input;
}