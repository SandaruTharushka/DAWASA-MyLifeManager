import 'package:drift/drift.dart';

import '../time/local_date.dart';

/// Stores [LocalDate] as ISO `YYYY-MM-DD` text so that SQL string comparison
/// equals calendar comparison and time zones can never shift a date.
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toIso();
}
