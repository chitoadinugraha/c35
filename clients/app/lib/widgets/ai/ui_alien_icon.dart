import 'package:flutter/material.dart';

class UiAlienIcon extends StatelessWidget {
  const UiAlienIcon({super.key, required this.size, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(Icons.hub_outlined, size: size, color: color);
}
