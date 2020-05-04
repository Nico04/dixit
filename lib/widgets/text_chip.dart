import 'package:dixit/resources/resources.dart';
import 'package:flutter/material.dart';

class TextChip extends StatelessWidget {
  final String label;
  final Color color;

  const TextChip(this.label, { this.color });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide.none,
        ),
        color: color ?? AppResources.ColorSand,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(label),
    );
  }
}
