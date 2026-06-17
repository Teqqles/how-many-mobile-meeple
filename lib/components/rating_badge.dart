import 'package:flutter/material.dart';

(Color bgColor, Color textColor) ratingColors(double rating) {
  return switch (rating) {
    >= 7.5 => (const Color(0xFFFFD700), Colors.black),
    >= 6.5 => (const Color(0xFFC0C0C0), Colors.black),
    >= 5.5 => (const Color(0xFFCD7F32), Colors.white),
    >= 4.5 => (Colors.orange, Colors.white),
    _ => (Colors.red, Colors.white),
  };
}

class MiniRatingBadge extends StatelessWidget {
  final double rating;
  final double size;

  const MiniRatingBadge({super.key, required this.rating, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color textColor) = ratingColors(rating);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withAlpha(40), width: 1),
      ),
      child: Center(
        child: Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
