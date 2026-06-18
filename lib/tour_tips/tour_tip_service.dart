import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'tour_tip.dart';
import 'tour_tip_definitions.dart';
import 'tour_tip_storage.dart';

class TourTipService {
  static Future<TourTipService>? _instanceFuture;
  late TourTipStorage _storage;
  bool _isShowing = false;
  final List<Completer<void>> _queue = [];
  TutorialCoachMark? _activeMark;

  TourTipService._(this._storage);

  static Future<TourTipService> instance() {
    _instanceFuture ??= _create();
    return _instanceFuture!;
  }

  static Future<TourTipService> _create() async {
    final storage = await TourTipStorage.create();
    return TourTipService._(storage);
  }

  static void resetForTesting() {
    _instanceFuture = null;
  }

  bool get isEnabled => !_storage.isGloballyDisabled;

  bool get isShowing => _isShowing;

  Future<void> setEnabled(bool enabled) async {
    await _storage.setGloballyDisabled(!enabled);
  }

  Future<void> showTipsForPage({
    required BuildContext context,
    required String pageId,
    required Map<String, GlobalKey> targets,
  }) async {
    if (!isEnabled) return;

    if (_isShowing) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
      if (!context.mounted || !isEnabled) return;
    }

    final pageTips = TourTipDefinitions.forPage(pageId);
    final unseen = _storage.unseenTips(pageTips);
    if (unseen.isEmpty) return;

    final hasValidTargets =
        unseen.any((t) => targets[t.id]?.currentContext != null);
    if (!hasValidTargets) return;

    _isShowing = true;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) {
      _finishAndDrainQueue();
      return;
    }

    final targetFocusList = _buildTargets(unseen, targets);
    if (targetFocusList.isEmpty) {
      _finishAndDrainQueue();
      return;
    }

    final showCompleter = Completer<void>();

    _activeMark = TutorialCoachMark(
      targets: targetFocusList,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
      hideSkip: true,
      onFinish: () async {
        await _markTipsAsSeen(unseen);
        _activeMark = null;
        _finishAndDrainQueue();
        showCompleter.complete();
      },
      onSkip: () {
        _markTipsAsSeen(unseen);
        _activeMark = null;
        _finishAndDrainQueue();
        showCompleter.complete();
        return true;
      },
    )..show(context: context);

    await showCompleter.future;
  }

  void _finishAndDrainQueue() {
    _isShowing = false;
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.complete();
    }
  }

  Future<void> dismissAll() async {
    await _storage.setGloballyDisabled(true);
    _activeMark?.skip();
  }

  static const double _maxFocusRadius = 150.0;

  double _cappedPaddingForKey(GlobalKey key, double screenWidth) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 10;
    final targetSize = renderBox.size;
    final maxDimension = math.max(targetSize.width, targetSize.height);
    final maxRadius = math.min(_maxFocusRadius, screenWidth * 0.2);
    final padding = maxRadius - maxDimension * 0.6;
    return math.max(padding, 4);
  }

  List<TargetFocus> _buildTargets(
    List<TourTip> tips,
    Map<String, GlobalKey> targets,
  ) {
    final result = <TargetFocus>[];

    for (final tip in tips) {
      final key = targets[tip.id];
      if (key == null || key.currentContext == null) continue;

      final screenWidth = MediaQuery.of(key.currentContext!).size.width;
      final padding = _cappedPaddingForKey(key, screenWidth);

      result.add(
        TargetFocus(
          identify: tip.id,
          keyTarget: key,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          enableTargetTab: true,
          paddingFocus: padding,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                final screenWidth = MediaQuery.of(context).size.width;
                return Container(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Tap anywhere to continue',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => dismissAll(),
                            child: const Text(
                              'Dismiss Tour',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return result;
  }

  Future<void> _markTipsAsSeen(List<TourTip> tips) async {
    for (final tip in tips) {
      await _storage.markSeen(tip.id);
    }
  }

  Future<void> resetAllTips() async {
    await _storage.resetAll();
  }
}
