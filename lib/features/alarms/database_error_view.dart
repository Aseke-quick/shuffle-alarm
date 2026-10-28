import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/data/providers.dart';

/// What the app shows instead of the alarms when its database cannot open,
/// such as in a browser that blocks the site's storage (docs/DECISIONS.md,
/// task 2.1). Never an empty list: that would look as if no alarm were set.
class DatabaseErrorView extends ConsumerWidget {
  const DatabaseErrorView({required this.error, super.key});

  /// What went wrong, shown in small print for a bug report.
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Alarms are not available',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The app could not open its storage, so it cannot show or '
              'save alarms, and no alarm can ring. '
              '${kIsWeb ? _webHint : _deviceHint}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              // A new database, which tries to open again.
              onPressed: () => ref.invalidate(databaseProvider),
              child: const Text('Try again'),
            ),
            const SizedBox(height: 16),
            SelectableText(
              '$error',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

const _webHint =
    'Allow this site to store data, leave private browsing, or try the '
    'latest Chrome, Edge or Firefox.';

const _deviceHint =
    'Restart the app. If that does not help, free some space on the device.';
