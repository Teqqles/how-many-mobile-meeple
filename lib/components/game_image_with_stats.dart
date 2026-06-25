import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/components/rating_badge.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

class GameImageWithStats extends StatelessWidget with ScreenTools {
  final Game game;

  GameImageWithStats({super.key, required this.game});

  bool get _hasImage => game.imageUrl.isNotEmpty;
  bool get _hasRating => game.averageRating > 0;
  bool get _hasPlayers => game.minPlayers > 0 || game.maxPlayers > 0;
  bool get _hasPlaytime => game.maxPlaytime > 0;
  bool get _hasWeight => game.averageWeight > 0;

  @override
  Widget build(BuildContext context) {
    final maxHeight = getScreenHeightPercentageInPixels(
        context, ScreenTools.fiftyPercentScreen);
    return ClipRect(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (_hasImage)
              SizedBox(
                width: double.infinity,
                child: PlatformIndependentImage(
                  imageUrl: game.imageUrl,
                  fit: BoxFit.fitWidth,
                ),
              ),
            if (_hasImage)
              Positioned(
                left: 0,
                right: 0,
                top: maxHeight * 0.65,
                height: maxHeight * 0.40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.85, 1.0],
                      colors: [
                        Colors.transparent,
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            if (_hasImage && isWideScreen(context) && game.thumbnail != null)
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    height: maxHeight * 0.80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: PlatformIndependentImage(
                        imageUrl: game.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            if (_hasRating)
              Positioned(
                right: 8,
                top: 8,
                child: _RatingBadge(rating: game.averageRating),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(192),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(64),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasPlayers) ...[
                      _StatChip(
                        icon: Icons.people,
                        label: game.minPlayers == game.maxPlayers
                            ? '${game.minPlayers} players'
                            : '${game.minPlayers}-${game.maxPlayers} players',
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_hasPlaytime) ...[
                      _StatChip(
                        icon: Icons.timer,
                        label: '${game.maxPlaytime} min',
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_hasWeight) ...[
                      _StatChip(
                        icon: Icons.fitness_center,
                        label: '${game.averageWeight.toStringAsFixed(1)} / 5',
                      ),
                      const SizedBox(height: 14),
                    ],
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.boardgamegeek.com/boardgame/${game.id}')),
                        child: const _StatChip(
                          icon: Icons.open_in_new,
                          label: 'BoardGameGeek',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color textColor) = ratingColors(rating);
    const borderColor = Colors.black;
    final isStar = rating >= 5.5;

    final ratingText = rating.toStringAsFixed(1);
    const badgeSize = 56.0;
    final textWidget = Text(
      ratingText,
      style: TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );

    if (isStar) {
      return SizedBox(
        width: badgeSize + 16,
        height: badgeSize + 16,
        child: CustomPaint(
          painter: _StarPainter(fillColor: bgColor, borderColor: borderColor),
          child: Center(child: textWidget),
        ),
      );
    }

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: textWidget),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _StarPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Path _starPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.45;
    const points = 5;
    final path = Path();

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
