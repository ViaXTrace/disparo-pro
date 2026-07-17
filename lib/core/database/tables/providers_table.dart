import 'package:drift/drift.dart';

@DataClassName('ProviderConfig')
class ProvidersTable extends Table {
  @override
  String get tableName => 'providers';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get type => text()();
  // zenvia | infobip | twilio | sinch | totalvoice | custom_webhook
  TextColumn get channels => text()(); // JSON: ["sms","rcs","whatsapp"]
  TextColumn get credentials => text()(); // JSON blob
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get extraConfig => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
