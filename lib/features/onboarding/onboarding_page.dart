import 'package:tano/shared/widgets/paper_surface.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tano/features/onboarding/onboarding_slides.dart';
import 'package:tano/features/splash/splash_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/onboarding_controller.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The introduction, shown once on the first launch and reachable again from
/// the settings.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onFinished});

  /// Runs once the introduction is over (or skipped). When null, the splash
  /// screen takes over and opens the home; the settings pass their own
  /// "go back".
  final VoidCallback? onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  /// Whether this page locked a phone to portrait, so it can hand the device
  /// back on the way out.
  bool _forcedPortrait = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_forcedPortrait || _orientationChecked) return;
    _orientationChecked = true;
    // A phone reads the introduction upright: hold it in portrait while the
    // pages are on screen. A tablet keeps the room it has to rotate freely.
    if (!tabletViewport(MediaQuery.sizeOf(context))) {
      _forcedPortrait = true;
      SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  bool _orientationChecked = false;

  @override
  void dispose() {
    // Only the first-run introduction owns the orientation: a replay opened
    // from the settings leaves the lock the settings itself applies in place.
    if (_forcedPortrait && widget.onFinished == null) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _controller.dispose();
    super.dispose();
  }

  int get _lastIndex => onboardingSlides().length - 1;

  void _finish({bool createFirstNote = false}) {
    // The choice is recorded without making the user wait for the disk: the
    // write finishes on its own while the next screen is already there.
    unawaited(OnboardingController.instance.markSeen());
    final VoidCallback? onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            SplashScreen(openEditorWhenEmpty: createFirstNote),
      ),
    );
  }

  void _next() {
    if (_index == _lastIndex) {
      // The closing label promises a first note: keep that promise.
      _finish(createFirstNote: true);
      return;
    }
    _controller.nextPage(duration: TanoMotion.base, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final List<OnboardingSlide> slides = onboardingSlides();
    final bool isLast = _index == _lastIndex;
    final Size window = MediaQuery.sizeOf(context);
    // A tablet has width to spare: the whole introduction lives in a centred
    // column as wide as the primary button, so the skip link, the pages and the
    // dots all line up with it. A phone keeps the full width.
    final bool onTablet = tabletViewport(window);
    final double contentWidth = onTablet
        ? (window.width - sectionGap * 2) / 2
        : window.width;
    return PaperSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: appPaddingTight,
                      ),
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(
                          AppText.tr('onboarding_skip'),
                          style: TextStyle(
                            color: mutedTextColor(context),
                            fontSize: TanoText.listTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: slides.length,
                      onPageChanged: (int index) =>
                          setState(() => _index = index),
                      itemBuilder: (BuildContext context, int index) =>
                          _Slide(slide: slides[index]),
                    ),
                  ),
                  _Dots(count: slides.length, index: _index),
                  const SizedBox(height: sectionGap),
                  Padding(
                    // Inside the column the button already has its width; only
                    // a phone keeps the outer inset it always had.
                    padding: EdgeInsets.symmetric(
                      horizontal: onTablet ? 0.0 : sectionGap,
                    ),
                    child: _PrimaryButton(
                      label: isLast
                          ? AppText.tr('onboarding_start')
                          : AppText.tr('onboarding_next'),
                      onPressed: _next,
                    ),
                  ),
                  const SizedBox(height: sectionGap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    // The narrow tablet column wraps the body onto more lines: let a short
    // window scroll rather than overflow, while a tall one keeps centring.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: sectionGap),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  slide.art,
                  const SizedBox(height: sectionGap),
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: TanoText.pageTitle,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: appPaddingMedium),
                  Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: TanoText.body,
                      height: 1.35,
                      color: mutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Three dots, the current one stretched into a pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final Color active = Theme.of(context).colorScheme.primary;
    final Color inactive = mutedTextColor(context).withValues(alpha: 0.35);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: TanoMotion.fast,
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: i == index ? 20.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: i == index ? active : inactive,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
      ],
    );
  }
}

/// The full-width button, Cupertino on Apple platforms and Material elsewhere.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final bool isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    if (isApple) {
      return SizedBox(
        width: double.infinity,
        height: 50.0,
        child: CupertinoButton.filled(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(pillRadius),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: TanoText.listTitle,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 54.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: TanoText.body,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
