import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/empty_state.dart';

/// One page of the introduction: a title, a sentence, and a drawing.
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.art,
  });

  final String title;
  final String body;
  final Widget art;
}

/// The three pages, in order: the notes, the lock that protects them, and the
/// order they are kept in.
List<OnboardingSlide> onboardingSlides() => <OnboardingSlide>[
  OnboardingSlide(
    title: AppText.tr('onboarding_title_1'),
    body: AppText.tr('onboarding_body_1'),
    art: const _DrawnArt(EmptyArt.addToBox),
  ),
  OnboardingSlide(
    title: AppText.tr('onboarding_title_2'),
    body: AppText.tr('onboarding_body_2'),
    art: const _DrawnArt(EmptyArt.fileLock),
  ),
  OnboardingSlide(
    title: AppText.tr('onboarding_title_3'),
    body: AppText.tr('onboarding_body_3'),
    art: const _DrawnArt(EmptyArt.organizedFolder),
  ),
];

/// A drawing from the stock set, tinted with the app colour so a change of
/// identity carries it along — the same treatment as the empty screens.
class _DrawnArt extends StatelessWidget {
  const _DrawnArt(this.image);

  final String image;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.primary,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          image,
          width: 128.0,
          height: 128.0,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}