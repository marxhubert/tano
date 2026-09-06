import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.tr('option_feedback'),
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
