import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/guided_flow/step1_select_source.dart';
import 'package:how_many_mobile_meeple/guided_flow/step2_whos_playing.dart';
import 'package:how_many_mobile_meeple/guided_flow/step3_time_available.dart';
import 'package:how_many_mobile_meeple/guided_flow/step4_game_style.dart';
import 'package:how_many_mobile_meeple/guided_flow/step5_final_actions.dart';
import 'package:how_many_mobile_meeple/guided_flow/advanced_mode_widget.dart';
import 'package:how_many_mobile_meeple/components/pwa_install_banner.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'package:how_many_mobile_meeple/components/empty_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  final int _totalSteps = 5;

  bool _getPreferAdvancedMode(AppModel model) {
    final setting = model.settings.setting('preferAdvancedMode');
    return setting.getBool();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        if (!model.hasLoadedPersistedData) {
          model.loadStoredData();
          model.refreshFromUrl();
        }

        // Use the setting as the single source of truth
        final showAdvancedMode = _getPreferAdvancedMode(model);

        return Scaffold(
          appBar: HowManyMeepleAppBar(
            AppCommon.optionsPageTitle,
            hasSaveDialog: true,
            isHomePage: true,
            model: model,
            context: context,
          ),
          drawer: widget.pageDrawer(context),
          body: Column(
            children: [
              const PwaInstallBanner(),
              Expanded(
                child: showAdvancedMode
                    ? _buildAdvancedMode(context)
                    : _buildGuidedFlow(context),
              ),
            ],
          ),
          bottomNavigationBar: _buildFooter(context),
          persistentFooterButtons:
              !showAdvancedMode && _currentStep == _totalSteps - 1
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

                // Finish button — skip straight to results
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
        // BGG Attribution on the left, taking full vertical height
        Container(
          height: double.infinity,
          child: BGGAttribution(),
        ),
        // Version on the right, vertically centered
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: DisclaimerText("(v:$version)", context),
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
