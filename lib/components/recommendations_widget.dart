// coverage:ignore-file
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/game.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/recommendation.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:how_many_mobile_meeple/services/service_locator.dart';

class RecommendationsWidget extends StatefulWidget {
  final Game sourceGame;
  final AppModel model;

  const RecommendationsWidget({
    super.key,
    required this.sourceGame,
    required this.model,
  });

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  Future<List<Recommendation>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _fetchRecommendations();
  }

  Future<List<Recommendation>> _fetchRecommendations() {
    final headers = Map.fromEntries(
      widget.model.settings.enabledSettings.entries
          .where((e) => e.value.header != null)
          .map((e) => MapEntry(e.value.header!, e.value.value.toString())),
    );

    return context.recommendationsFetcher.fetchRecommendations(
      gameIds: [widget.sourceGame.id],
      headers: headers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recommendation>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError || (snapshot.hasData && snapshot.data!.isEmpty)) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final recommendations = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'These Games Are Similar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(
                height: 140,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = recommendations.length * 100.0 +
                        (recommendations.length - 1) * 12.0;
                    final needsScroll = contentWidth > constraints.maxWidth;
                    final row = Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: recommendations
                          .map((r) => _RecommendationTile(recommendation: r))
                          .toList(),
                    );
                    if (needsScroll) {
                      final controller = ScrollController();
                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        }),
                        child: Scrollbar(
                          controller: controller,
                          thumbVisibility: true,
                          interactive: true,
                          child: SingleChildScrollView(
                            controller: controller,
                            scrollDirection: Axis.horizontal,
                            child: row,
                          ),
                        ),
                      );
                    }
                    return Center(child: row);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  static final Codec<String, String> _base64 = utf8.fuse(base64Url);

  final Recommendation recommendation;

  const _RecommendationTile({required this.recommendation});

  String _proxyUrl(String url) {
    if (!kIsWeb) return url;
    return '${AppCommon.boardGameGeekProxyUrl}/cors-proxy/_${_base64.encode(url)}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(
            '${r.Router.gameDetailRoute}/${recommendation.name.replaceAll(' ', '+')}/${recommendation.gameId}'),
        child: SizedBox(
          width: 100,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: recommendation.game?.imageUrl != null
                      ? Image.network(
                          _proxyUrl(recommendation.game!.thumbnail ??
                              recommendation.game!.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.extension, size: 48),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
