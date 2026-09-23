import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../ui/widgets/common.dart';

/// Financial reports and charts.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navReports)),
      body: EmptyState(
        icon: Icons.insights_outlined,
        message: context.l10n.emptyGeneric,
      ),
    );
  }
}
