import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/text_scale_controller.dart';
import 'package:tano/shared/widgets/check_disc.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'settings_widgets.dart';

/// Text size, haptics and sound: how the interface looks, and how it answers.
class FeedbackSection extends StatelessWidget {
  const FeedbackSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        TextScaleController.instance,
        FeedbackController.instance,
      ]),
      builder: (BuildContext context, Widget? _) {
        return SettingsGroup(
          title: AppText.tr('menu_feedback'),
          tiles: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: sectionGap),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  for (final TanoTextSize size in TanoTextSize.values)
                    _TextSizePreview(
                      size: size,
                      isSelected: TextScaleController.instance.size == size,
                      onTap: () => TextScaleController.instance.setSize(size),
                    ),
                ],
              ),
            ),
            SettingsSwitchTile(
              title: AppText.tr('feedback_haptics'),
              value: FeedbackController.instance.haptics,
              onChanged: FeedbackController.instance.setHaptics,
            ),
            SettingsSwitchTile(
              title: AppText.tr('feedback_sound'),
              value: FeedbackController.instance.sound,
              onChanged: FeedbackController.instance.setSound,
            ),
          ],
        );
      },
    );
  }
}

/// One size, shown as an "A" that grows with it. The chosen one wears the
/// same disc as every other choice in the settings.
class _TextSizePreview extends StatelessWidget {
  const _TextSizePreview({
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final TanoTextSize size;
  final bool isSelected;
  final VoidCallback onTap;

  String get _labelKey => switch (size) {
    TanoTextSize.small => 'text_size_small',
    TanoTextSize.normal => 'text_size_normal',
    TanoTextSize.large => 'text_size_large',
    TanoTextSize.extraLarge => 'text_size_extra_large',
  };

  double get _glyphSize => switch (size) {
    TanoTextSize.small => 16.0,
    TanoTextSize.normal => 20.0,
    TanoTextSize.large => 25.0,
    TanoTextSize.extraLarge => 30.0,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppText.tr(_labelKey),
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 40.0,
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: _glyphSize,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: primaryTextColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: appPaddingTight),
            if (isSelected)
              const CheckDisc(color: tanoAmber)
            else
              Icon(
                Symbols.circle,
                color: Colors.grey.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}