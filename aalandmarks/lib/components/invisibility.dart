import 'package:flutter/material.dart';

class Invisibility extends StatefulWidget {
  Invisibility({super.key, required this.child, required this.visible});
  Widget child;
  bool visible;

  @override
  State<Invisibility> createState() => _InvisibilityState();
}

class _InvisibilityState extends State<Invisibility> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.visible,
      child: widget.child,
    );
  }
}
