import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:how_many_mobile_meeple/components/platform_independent_image.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/screen_tools.dart';

class GameImageWithStats extends StatelessWidget with ScreenTools {
  final Game game;

  GameImageWithStats({super.key, required this.game});

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
            SizedBox(
              width: double.infinity,
              child: PlatformIndependentImage(
                imageUrl: game.imageUrl,
                fit: BoxFit.fitWidth,
              ),
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
                    _StatChip(
                      icon: Icons.people,
                      label: game.minPlayers == game.maxPlayers
                          ? '${game.minPlayers} players'
                          : '${game.minPlayers}-${game.maxPlayers} players',
                    ),
                    const SizedBox(height: 14),
                    _StatChip(
                      icon: Icons.timer,
                      label: '${game.maxPlaytime} min',
                    ),
                    const SizedBox(height: 14),
                    _StatChip(
                      icon: Icons.fitness_center,
                      label: '${game.averageWeight.toStringAsFixed(1)} / 5',
                    ),
                    const SizedBox(height: 14),
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
