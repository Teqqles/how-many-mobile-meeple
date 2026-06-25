import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/components/quick_pick_sheet.dart';
import 'package:how_many_mobile_meeple/guided_flow/step1_select_source.dart';
import 'package:how_many_mobile_meeple/guided_flow/step2_whos_playing.dart';
import 'package:how_many_mobile_meeple/guided_flow/step3_time_available.dart';
import 'package:how_many_mobile_meeple/guided_flow/step4_game_style.dart';
import 'package:how_many_mobile_meeple/guided_flow/step5_final_actions.dart';
import 'package:how_many_mobile_meeple/guided_flow/advanced_mode_widget.dart';
import 'package:how_many_mobile_meeple/components/pwa_install_banner.dart';
import 'package:how_many_mobile_meeple/components/pwa_update_banner.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'package:how_many_mobile_meeple/components/empty_widget.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_service.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_definitions.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_keys.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:how_many_mobile_meeple/about_page.dart';

/// Main guided flow homepage supporting two modes:
/// 1. Guided Flow Mode (default) - step-by-step onboarding
/// 2. Advanced Mode - full-control interface for power users
class GuidedFlowHomePage extends StatefulWidget with AppPage {
  static final String route = "Guided-flow-home-page";

  @override
  State<GuidedFlowHomePage> createState() => _GuidedFlowHomePageState();
}

class _GuidedFlowHomePageState extends State<GuidedFlowHomePage> {
  int _currentStep = 0;
  bool _showAdvancedMode = false;
  final Set<String> _tourTipTriggered = {};

  final int _totalSteps = 5;

  void _syncAdvancedMode(AppModel model) {
    final value = model.settings.setting('preferAdvancedMode').getBool();
    if (value != _showAdvancedMode) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _showAdvancedMode = value));
    }
  }

  void _triggerTourTips(AppModel model) {
    final isAdvanced = model.settings.setting('preferAdvancedMode').getBool();
    if (isAdvanced) return;

    final pageId = _currentStep == 0
        ? TourTipDefinitions.pageAppBar
        : 'step${_currentStep + 1}';

    if (_tourTipTriggered.contains(pageId)) return;
    _tourTipTriggered.add(pageId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final service = await TourTipService.instance();
      if (!service.isEnabled) return;

      await service.showTipsForPage(
        context: context,
        pageId: pageId,
        targets: TourTipKeys.forPage(pageId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        if (!model.hasLoadedPersistedData) {
          model.loadStoredData();
          model.refreshFromUrl();
        }

        _syncAdvancedMode(model);
        _triggerTourTips(model);

        return Scaffold(
          appBar: HowManyMeepleAppBar(
            AppCommon.optionsPageTitle,
            hasSaveDialog: _showAdvancedMode,
            isHomePage: true,
            model: model,
            context: context,
          ),
          endDrawer: widget.pageDrawer(context),
          body: Column(
            children: [
              const PwaUpdateBanner(),
              const PwaInstallBanner(),
              Expanded(
                child: _showAdvancedMode
                    ? _buildAdvancedMode(context)
                    : _buildGuidedFlow(context),
              ),
            ],
          ),
          bottomNavigationBar: _buildFooter(context),
          persistentFooterButtons:
              !_showAdvancedMode && _currentStep == _totalSteps - 1
                  ? [widget.iconButtonGroup(context)]
                  : null,
        );
      },
    );
  }

  /// Builds the guided flow with step progression
  Widget _buildGuidedFlow(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final model = AppModel.of(context, listen: false);
        if (velocity < -300 && _currentStep < _totalSteps - 1) {
          final canProceed =
              _currentStep != 0 || model.items.itemList.isNotEmpty;
          if (canProceed) setState(() => _currentStep++);
        } else if (velocity > 300 && _currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 24),

              // Current step content
              _buildCurrentStep(),

              const SizedBox(height: 24),

              // Navigation buttons (for steps 0-3)
              if (_currentStep < _totalSteps - 1) _buildStepNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress indicator showing current step with clickable step indicators
  Widget _buildProgressIndicator() {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        // Check if step 1 has items for validation
        final canAccessSteps = model.items.itemList.isNotEmpty;

        return Column(
          children: [
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),

            // Clickable step indicators
            Row(
              children: List.generate(_totalSteps, (index) {
                final isAccessible = index == 0 || canAccessSteps;
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: GestureDetector(
                    onTap: isAccessible
                        ? () => setState(() => _currentStep = index)
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        height: 8,
                        margin: EdgeInsets.only(
                            right: index < _totalSteps - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isActive
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Step labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepLabel(
                    0, 'Source', canAccessSteps || _currentStep == 0),
                _buildStepLabel(1, 'Players', canAccessSteps),
                _buildStepLabel(2, 'Time', canAccessSteps),
                _buildStepLabel(3, 'Style', canAccessSteps),
                _buildStepLabel(4, 'Done', canAccessSteps),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepLabel(int stepIndex, String label, bool isAccessible) {
    final isActive = stepIndex == _currentStep;
    return InkWell(
      onTap:
          isAccessible ? () => setState(() => _currentStep = stepIndex) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isAccessible
                    ? (isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface)
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
              ),
        ),
      ),
    );
  }

  /// Builds the current step widget
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return const Step1SelectSource();
      case 1:
        return const Step2WhosPlaying();
      case 2:
        return const Step3TimeAvailable();
      case 3:
        return const Step4GameStyle();
      case 4:
        return Consumer<AppModel>(
          builder: (context, model, child) => Step5FinalActions(
            onSwitchToAdvanced: () {
              final setting = model.settings.setting('preferAdvancedMode');
              setting.value = true;
              model.updateStore();
            },
          ),
        );
      default:
        return const SizedBox();
    }
  }

  /// Step navigation buttons (Next/Skip)
  Widget _buildStepNavigation() {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final canProceedFromStep1 =
            _currentStep != 0 || model.items.itemList.isNotEmpty;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button (except on first step)
            if (_currentStep > 0)
              OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              )
            else
              const SizedBox.shrink(),

            Row(
              children: [
                // Skip button (not available on Step 1)
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () => setState(() {
                      if (_currentStep < _totalSteps - 1) _currentStep++;
                    }),
                    child: const Text('Skip'),
                  ),
                if (_currentStep > 0) const SizedBox(width: 8),

                // Next button
                FilledButton.icon(
                  onPressed: canProceedFromStep1
                      ? () => setState(() {
                            if (_currentStep < _totalSteps - 1) _currentStep++;
                          })
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),

                // Quick Pick button
                if (_currentStep < _totalSteps - 1) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    key: TourTipKeys.appBarQuickPick,
                    onPressed: canProceedFromStep1
                        ? () => QuickPickSheet.show(context)
                        : null,
                    icon: const Icon(Icons.bolt),
                    label: const Text('Quick Pick'),
                  ),
                ],

                // Finish button - skip straight to results
                if (_currentStep < _totalSteps - 1) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: canProceedFromStep1
                        ? () => setState(() => _currentStep = _totalSteps - 1)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Finish'),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  /// Builds the BGG attribution footer (required by BGG API usage guidelines)
  Widget _buildFooter(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).highlightColor,
      child: FutureBuilder<Widget>(
        future: _footerDisplay(context),
        builder: (context, snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          return EmptyWidget();
        },
      ),
    );
  }

  Future<Widget> _footerDisplay(BuildContext context) async {
    var version = await _getAppVersion();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          height: double.infinity,
          child: BGGAttribution(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DisclaimerText("(v:$version)", context),
              const SizedBox(width: 4),
              Tooltip(
                message: 'About',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Advanced mode - shows the full existing UI
  Widget _buildAdvancedMode(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        // Only show "Back to Guided Flow" if user hasn't set "Always Use Advanced Mode"
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Back to guided flow button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final setting =
                          model.settings.setting('preferAdvancedMode');
                      setting.value = false;
                      setting.enabled = true;
                      model.settings.updateSetting(setting);
                      await model.updateStore();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Guided Flow'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Advanced Mode UI
                const AdvancedModeWidget(),

                const SizedBox(height: 16),

                // Action buttons at bottom
                widget.iconButtonGroup(context),
              ],
            ),
          ),
        );
      },
    );
  }
}
