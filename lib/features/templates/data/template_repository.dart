import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/templates_dao.dart';
import '../../../core/database/tables/templates_table.dart';

class TemplateRepository {
  final TemplatesDao _dao;

  TemplateRepository(AppDatabase db) : _dao = db.templatesDao;

  Stream<List<Template>> watchAll({String? channel}) => _dao.watchAll(channel: channel);
  Future<List<Template>> getAll({String? channel}) => _dao.getAll(channel: channel);
  Future<Template?> getById(int id) => _dao.getById(id);

  Future<Template> create({
    required String name,
    required String body,
    String channel = 'all',
    String? mediaUrl,
    List<String>? variables,
  }) async {
    final id = await _dao.insert(TemplatesTableCompanion.insert(
      name: name,
      body: body,
      channel: Value(channel),
      mediaUrl: Value(mediaUrl),
      variables: Value(variables != null ? jsonEncode(variables) : null),
    ));
    return (await _dao.getById(id))!;
  }

  Future<void> update(Template template, {
    String? name,
    String? body,
    String? channel,
    String? mediaUrl,
    List<String>? variables,
  }) => _dao.update(TemplatesTableCompanion(
        id: Value(template.id),
        name: name != null ? Value(name) : const Value.absent(),
        body: body != null ? Value(body) : const Value.absent(),
        channel: channel != null ? Value(channel) : const Value.absent(),
        mediaUrl: mediaUrl != null ? Value(mediaUrl) : const Value.absent(),
        variables: variables != null ? Value(jsonEncode(variables)) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));

  Future<int> delete(int id) => _dao.delete(id);

  /// Applies variable substitution to template body.
  String apply(String body, Map<String, String> values) {
    var result = body;
    for (final e in values.entries) {
      result = result.replaceAll('{{${e.key}}}', e.value);
    }
    return result;
  }

  List<String> extractVariables(String body) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    return regex.allMatches(body).map((m) => m.group(1)!).toSet().toList();
  }
}
