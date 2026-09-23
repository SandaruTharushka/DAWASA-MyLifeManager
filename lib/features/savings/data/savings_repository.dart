import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/time/local_date.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_models.dart';

class SavingsGoalDraft {
  const SavingsGoalDraft({
    required this.id,
    required this.name,
    required this.targetAmountMinor,
    required this.currencyCode,
    this.targetDate,
    this.linkedAccountId,
    this.iconKey = 'savings',
    this.colorValue = 0xFF16A34A,
    this.remindMonthly = false,
  });

  final String id;
  final String name;
  final int targetAmountMinor;
  final String currencyCode;
  final LocalDate? targetDate;
  final String? linkedAccountId;
  final String iconKey;
  final int colorValue;
  final bool remindMonthly;
}

/// A goal with its progress.
class SavingsGoalView {
  const SavingsGoalView(this.goal, this.savedMinor);

  final SavingsGoalRow goal;
  final int savedMinor;

  int get remainingMinor =>
      (goal.targetAmountMinor - savedMinor).clamp(0, goal.targetAmountMinor);
  bool get reached => savedMinor >= goal.targetAmountMinor;
  double get fraction => goal.targetAmountMinor <= 0
      ? 0
      : (savedMinor / goal.targetAmountMinor).clamp(0, 1).toDouble();
  int get percent => (fraction * 100).floor();

  /// Monthly amount needed to reach the target by its date.
  int? monthlyNeededMinor(LocalDate today) {
    final target = goal.targetDate;
    if (target == null || reached || !target.isAfter(today)) return null;
    final months =
        (target.year - today.year) * 12 +
        (target.month - today.month) +
        (target.day >= today.day ? 1 : 0);
    if (months <= 0) return remainingMinor;
    return (remainingMinor + months - 1) ~/ months;
  }
}

class InsufficientSavingsException implements Exception {
  const InsufficientSavingsException();
}

/// Savings goals. Money added to a goal with a linked savings account is a
/// transfer between the user's own accounts – never an expense.
class SavingsRepository {
  SavingsRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionRepository _transactions;

  static const _savedSql = '''
SELECT g.*, COALESCE((
  SELECT SUM(CASE WHEN m.type = 'deposit' THEN m.amount_minor ELSE -m.amount_minor END)
  FROM savings_movements m WHERE m.goal_id = g.id), 0) AS saved
FROM savings_goals g''';

  List<SavingsGoalView> _map(List<QueryRow> rows) => [
    for (final r in rows)
      SavingsGoalView(_db.savingsGoals.map(r.data), r.read<int>('saved')),
  ];

  Stream<List<SavingsGoalView>> watchGoals() => _db
      .customSelect(
        '$_savedSql ORDER BY g.is_archived, g.created_at',
        readsFrom: {_db.savingsGoals, _db.savingsMovements},
      )
      .watch()
      .map(_map);

  Future<List<SavingsGoalView>> goals() async => _map(
    await _db
        .customSelect(
          '$_savedSql ORDER BY g.is_archived, g.created_at',
          readsFrom: {_db.savingsGoals, _db.savingsMovements},
        )
        .get(),
  );

  Future<SavingsGoalView?> goal(String id) async {
    final rows = await _db
        .customSelect(
          '$_savedSql WHERE g.id = ?',
          variables: [Variable.withString(id)],
          readsFrom: {_db.savingsGoals, _db.savingsMovements},
        )
        .get();
    return rows.isEmpty ? null : _map(rows).single;
  }

  Stream<SavingsGoalView?> watchGoal(String id) => _db
      .customSelect(
        '$_savedSql WHERE g.id = ?',
        variables: [Variable.withString(id)],
        readsFrom: {_db.savingsGoals, _db.savingsMovements},
      )
      .watch()
      .map((rows) => rows.isEmpty ? null : _map(rows).single);

  Stream<List<SavingsMovementRow>> watchMovements(String goalId) =>
      (_db.select(_db.savingsMovements)
            ..where((m) => m.goalId.equals(goalId))
            ..orderBy([
              (m) => OrderingTerm.desc(m.localDate),
              (m) => OrderingTerm.desc(m.createdAt),
            ]))
          .watch();

  Future<void> saveGoal(SavingsGoalDraft d) async {
    final companion = SavingsGoalsCompanion.insert(
      id: Value(d.id),
      name: d.name.trim(),
      targetAmountMinor: d.targetAmountMinor,
      currencyCode: Value(d.currencyCode),
      targetDate: Value(d.targetDate),
      linkedAccountId: Value(d.linkedAccountId),
      iconKey: Value(d.iconKey),
      colorValue: Value(d.colorValue),
      remindMonthly: Value(d.remindMonthly),
      updatedAt: Value(nowUtc()),
    );
    final exists = await (_db.select(
      _db.savingsGoals,
    )..where((g) => g.id.equals(d.id))).getSingleOrNull();
    if (exists == null) {
      await _db.into(_db.savingsGoals).insert(companion);
    } else {
      await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(d.id)))
          .write(companion.copyWith(createdAt: const Value.absent()));
    }
    await _updateCompletion(d.id);
  }

  Future<void> deleteGoal(String id) =>
      (_db.delete(_db.savingsGoals)..where((g) => g.id.equals(id))).go();

  Future<void> setArchived(String id, {required bool archived}) =>
      (_db.update(_db.savingsGoals)..where((g) => g.id.equals(id))).write(
        SavingsGoalsCompanion(
          isArchived: Value(archived),
          updatedAt: Value(nowUtc()),
        ),
      );

  /// Adds money to a goal. When the goal has a linked account different from
  /// [fromAccountId], a transfer is recorded from that account to the linked
  /// account; otherwise the amount is only set aside (no balance change).
  Future<void> deposit({
    required String movementId,
    required String goalId,
    required int amountMinor,
    required DateTime occurredAt,
    String? fromAccountId,
    String? note,
  }) => _move(
    movementId: movementId,
    goalId: goalId,
    type: SavingsMovementType.deposit,
    amountMinor: amountMinor,
    occurredAt: occurredAt,
    otherAccountId: fromAccountId,
    note: note,
  );

  /// Takes money out of a goal (optionally transferring it from the linked
  /// account to [toAccountId]).
  Future<void> withdraw({
    required String movementId,
    required String goalId,
    required int amountMinor,
    required DateTime occurredAt,
    String? toAccountId,
    String? note,
  }) => _move(
    movementId: movementId,
    goalId: goalId,
    type: SavingsMovementType.withdrawal,
    amountMinor: amountMinor,
    occurredAt: occurredAt,
    otherAccountId: toAccountId,
    note: note,
  );

  Future<void> _move({
    required String movementId,
    required String goalId,
    required SavingsMovementType type,
    required int amountMinor,
    required DateTime occurredAt,
    String? otherAccountId,
    String? note,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.savingsMovements,
      )..where((m) => m.id.equals(movementId))).getSingleOrNull();
      if (existing != null) return;
      final view = await goal(goalId);
      if (view == null) throw StateError('Unknown goal $goalId');
      if (type == SavingsMovementType.withdrawal &&
          amountMinor > view.savedMinor) {
        throw const InsufficientSavingsException();
      }
      final linked = view.goal.linkedAccountId;
      String? transactionId;
      if (linked != null &&
          otherAccountId != null &&
          otherAccountId != linked) {
        transactionId = deterministicId('savings:$movementId');
        final deposit = type == SavingsMovementType.deposit;
        await _transactions.insertWithinTransaction(
          TransactionDraft(
            id: transactionId,
            type: TransactionType.transfer,
            amountMinor: amountMinor,
            currencyCode: view.goal.currencyCode,
            accountId: deposit ? otherAccountId : linked,
            toAccountId: deposit ? linked : otherAccountId,
            occurredAt: occurredAt,
            description: view.goal.name,
            note: note,
            source: TransactionSource.savings,
            sourceRefId: goalId,
          ),
        );
      }
      await _db
          .into(_db.savingsMovements)
          .insert(
            SavingsMovementsCompanion.insert(
              id: Value(movementId),
              goalId: goalId,
              type: type,
              amountMinor: amountMinor,
              localDate: LocalDate.fromDateTime(occurredAt),
              occurredAt: occurredAt.toUtc(),
              transactionId: Value(transactionId),
              note: Value(note),
            ),
          );
      await _updateCompletion(goalId);
    });
  }

  Future<void> deleteMovement(String movementId) {
    return _db.transaction(() async {
      final m = await (_db.select(
        _db.savingsMovements,
      )..where((x) => x.id.equals(movementId))).getSingleOrNull();
      if (m == null) return;
      if (m.transactionId != null) {
        // Cascades to the movement.
        await _transactions.delete(m.transactionId!);
      }
      await (_db.delete(
        _db.savingsMovements,
      )..where((x) => x.id.equals(movementId))).go();
      await _updateCompletion(m.goalId);
    });
  }

  Future<void> _updateCompletion(String goalId) async {
    final view = await goal(goalId);
    if (view == null) return;
    final completed = view.reached;
    if (completed == (view.goal.completedAt != null)) return;
    await (_db.update(
      _db.savingsGoals,
    )..where((g) => g.id.equals(goalId))).write(
      SavingsGoalsCompanion(completedAt: Value(completed ? nowUtc() : null)),
    );
  }

  /// Total moved into savings accounts via goal deposits in a date range.
  Future<int> depositedBetween(LocalDate start, LocalDate end) async {
    final row = await _db
        .customSelect(
          '''
SELECT COALESCE(SUM(amount_minor), 0) AS total FROM savings_movements
WHERE type = 'deposit' AND local_date BETWEEN ? AND ?''',
          variables: [
            Variable.withString(start.toIso()),
            Variable.withString(end.toIso()),
          ],
          readsFrom: {_db.savingsMovements},
        )
        .getSingle();
    return row.read<int>('total');
  }
}
