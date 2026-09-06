import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.tr('about'),
      slivers: const [
        SliverFillRemaining(
          child: Center(
            child: Text('Coming soon...'),
          ),
        ),
      ],
    );
  }
}
