import 'package:flutter/widgets.dart';

/// Wraps the whole app below the router. The security module adds the lock
/// screen here.
class AppGate extends StatelessWidget {
  const AppGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
