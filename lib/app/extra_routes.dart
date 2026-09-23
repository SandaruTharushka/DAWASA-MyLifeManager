import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

typedef PageRouteFactory = GoRoute Function(
  String path,
  Widget Function(GoRouterState state) builder,
);

/// Full-screen routes of the planner, budgets, bills, savings, loans,
/// reports, security, backup and update modules.
List<GoRoute> extraRoutes(PageRouteFactory page) => [];
