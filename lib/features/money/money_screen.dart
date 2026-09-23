import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/l10n/l10n.dart';
import '../accounts/presentation/accounts_tab.dart';
import '../transactions/presentation/transactions_tab.dart';

/// A secondary tab inside a hub screen.
class HubTab {
  const HubTab({
    required this.key,
    required this.label,
    required this.body,
    this.fabLabel,
    this.fabIcon = Icons.add_rounded,
    this.onFab,
  });

  final String key;
  final String label;
  final Widget body;
  final String? fabLabel;
  final IconData fabIcon;
  final void Function(BuildContext context)? onFab;
}

/// Scaffold with scrollable secondary tabs and a per-tab action button.
class HubScaffold extends StatefulWidget {
  const HubScaffold({
    super.key,
    required this.title,
    required this.tabs,
    this.initialTab,
  });

  final String title;
  final List<HubTab> tabs;
  final String? initialTab;

  @override
  State<HubScaffold> createState() => _HubScaffoldState();
}

class _HubScaffoldState extends State<HubScaffold>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  int _indexOf(String? key) {
    final i = widget.tabs.indexWhere((t) => t.key == key);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: _indexOf(widget.initialTab),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant HubScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      _controller.animateTo(_indexOf(widget.initialTab));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tabs[_controller.index];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _controller,
          isScrollable: true,
          tabs: [for (final t in widget.tabs) Tab(text: t.label)],
        ),
      ),
      floatingActionButton: tab.onFab == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'hub-fab-${tab.key}',
              onPressed: () => tab.onFab!(context),
              icon: Icon(tab.fabIcon),
              label: Text(tab.fabLabel ?? context.l10n.actionAdd),
            ),
      body: TabBarView(
        controller: _controller,
        children: [for (final t in widget.tabs) t.body],
      ),
    );
  }
}

/// Money hub: transactions, accounts, budgets, bills, savings and loans.
class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HubScaffold(
      title: l10n.moneyTitle,
      initialTab: initialTab,
      tabs: [
        HubTab(
          key: 'transactions',
          label: l10n.tabTransactions,
          body: const TransactionsTab(),
          fabLabel: l10n.quickAddExpense,
          onFab: (c) => c.push(Routes.newTransaction()),
        ),
        HubTab(
          key: 'accounts',
          label: l10n.tabAccounts,
          body: const AccountsTab(),
          fabLabel: l10n.accountAdd,
          onFab: (c) => c.push(Routes.newAccount),
        ),
      ],
    );
  }
}
