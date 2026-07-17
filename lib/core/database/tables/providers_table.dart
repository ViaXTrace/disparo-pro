import 'package:drift/drift.dart';

class ProvidersTable extends Table {
  @override
  String get tableName => 'providers';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get type => text()();
  // zenvia | infobip | twilio | sinch | msg91 | brevo | totalvoice
  // claro_empresas | tim_business | vivo_ads | custom_webhook
  TextColumn get channels => text()(); // JSON list: ["sms","rcs","whatsapp"]
  TextColumn get credentials => text()(); // JSON encrypted blob
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get extraConfig => text().nullable()(); // JSON
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
