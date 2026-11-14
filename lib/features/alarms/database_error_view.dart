import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// What the app shows instead of the alarms when its database cannot open,
/// such as in a browser that blocks the site's storage (docs/DECISIONS.md,
/// task 2.1). Never an empty list: that would look as if no alarm were set.
class DatabaseErrorView extends ConsumerWidget {
  const DatabaseErrorView({required this.error, super.key});

  /// What went wrong, shown in small print for a bug report.
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatusView(
      error: true,
      title: tr.alarmsNotAvailable,
      message: tr.storageProblem(
        kIsWeb ? tr.storageHintWeb : tr.storageHintDevice,
      ),
      action: WideButton.secondary(
        label: tr.tryAgain,
        // A new database, which tries to open again.
        onPressed: () => ref.invalidate(databaseProvider),
      ),
      detail: '$error',
    );
  }
}
