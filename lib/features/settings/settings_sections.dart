import 'package:flutter/widgets.dart';

import '../backup/presentation/data_section.dart';
import '../security/security_section.dart';
import '../updates/presentation/update_screen.dart';
import 'reminders_section.dart';

/// Settings sections contributed by the reminders, security, data and update
/// modules, in display order.
const List<Widget> extraSettingsSections = [
  SecuritySettingsSection(),
  RemindersSettingsSection(),
  DataSettingsSection(),
  UpdatesSettingsSection(),
];
