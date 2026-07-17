import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/providers_dao.dart';
import '../../../core/database/tables/providers_table.dart';
import '../../../core/gateway/gateway_registry.dart';
import '../../../core/gateway/message_gateway.dart';

class ProviderRepository {
  final ProvidersDao _dao;

  ProviderRepository(AppDatabase db) : _dao = db.providersDao;

  Stream<List<ProviderConfig>> watchAll() => _dao.watchAll();
  Future<List<ProviderConfig>> getAll() => _dao.getAll();
  Future<ProviderConfig?> getById(int id) => _dao.getById(id);
  Future<ProviderConfig?> getDefault() => _dao.getDefault();

  Future<ProviderConfig> add({
    required String name,
    required String type,
    required Map<String, dynamic> credentials,
    required List<MessageChannel> channels,
    bool isDefault = false,
  }) async {
    final id = await _dao.insert(ProvidersTableCompanion.insert(
      name: name,
      type: type,
      credentials: jsonEncode(credentials),
      channels: jsonEncode(channels.map((c) => c.name).toList()),
      isDefault: Value(isDefault),
    ));
    return (await _dao.getById(id))!;
  }

  Future<void> update(ProviderConfig provider, {
    String? name,
    Map<String, dynamic>? credentials,
    List<MessageChannel>? channels,
    bool? isDefault,
    bool? isActive,
  }) => _dao.updateProvider(ProvidersTableCompanion(
        id: Value(provider.id),
        name: name != null ? Value(name) : const Value.absent(),
        credentials: credentials != null ? Value(jsonEncode(credentials)) : const Value.absent(),
        channels: channels != null ? Value(jsonEncode(channels.map((c) => c.name).toList())) : const Value.absent(),
        isDefault: isDefault != null ? Value(isDefault) : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
      ));

  Future<int> delete(int id) => _dao.deleteProvider(id);
  Future<void> setDefault(int id) => _dao.setDefault(id);

  Future<bool> validate(String type, Map<String, dynamic> credentials) async {
    final gw = GatewayRegistry.build(type);
    return gw.validateCredentials(credentials);
  }

  Map<String, dynamic> decodeCredentials(ProviderConfig p) =>
      jsonDecode(p.credentials) as Map<String, dynamic>;

  List<String> decodeChannels(ProviderConfig p) =>
      List<String>.from(jsonDecode(p.channels) as List);
}
