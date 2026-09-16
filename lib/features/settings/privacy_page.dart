import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';

/// The privacy policy, kept inside the app because there is no website.
///
/// It states the product promises: nothing leaves the device, the local data
/// is encrypted at rest, and the optional crash reports are anonymous and can
/// be switched off at any time. The same text feeds the store listings — see
/// `docs/confidentialite.md`.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  /// The sections of the policy, as (title key, body key) pairs, in reading
  /// order.
  static const List<(String, String)> sections = <(String, String)>[
    ('privacy_local_title', 'privacy_local_body'),
    ('privacy_encryption_title', 'privacy_encryption_body'),
    ('privacy_crash_title', 'privacy_crash_body'),
    ('privacy_tracking_title', 'privacy_tracking_body'),
    ('privacy_delete_title', 'privacy_delete_body'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.tr('privacy'),
      actions: const <Widget>[ThemeToggleButton()],
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 0.0),
          sliver: SliverToBoxAdapter(
            child: _Paragraph(text: AppText.tr('privacy_intro')),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 40.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              for (final (String title, String body) in sections)
                _Section(titleKey: title, bodyKey: body),
              const SizedBox(height: 32.0),
              _Paragraph(text: AppText.tr('privacy_updated'), muted: true),
            ]),
          ),
        ),
      ],
    );
  }
}

/// One titled block of the policy.
class _Section extends StatelessWidget {
  const _Section({required this.titleKey, required this.bodyKey});

  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppText.tr(titleKey),
            style: TextStyle(
              color: primaryTextColor(context),
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          // The crash section names the consent switch, so the reader knows
          // exactly which control to flip.
          _Paragraph(
            text: AppText.tr(bodyKey, <String, String>{
              'option_bug_report': AppText.tr('option_bug_report'),
            }),
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: muted ? mutedTextColor(context) : primaryTextColor(context),
        fontSize: muted ? 13.0 : 16.0,
        height: 1.6,
      ),
    );
  }
}
