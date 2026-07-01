import 'package:flutter/material.dart';
import 'platform_independent_image.dart';

/// Small rounded game thumbnail with a casino-icon fallback, used in list rows.
class GameThumbnail extends StatelessWidget {
  final String? thumbnail;
  final double size;

  const GameThumbnail({super.key, required this.thumbnail, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: size,
        height: size,
        child: thumbnail != null
            ? PlatformIndependentImage(imageUrl: thumbnail!, fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.casino,
                    size: size / 2,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
      ),
    );
  }
}
