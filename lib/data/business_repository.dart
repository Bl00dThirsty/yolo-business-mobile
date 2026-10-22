import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

abstract class BusinessRepository {
  String get userId;
  Future<dynamic> call(String name, [Json params = const {}]);
  Future<Json?> readPending();
  Future<void> savePending(Json? pending);
  Future<Json> workspace() async => Json.from(await call('operator_workspace'));
  Future<List<Delivery>> deliveries(String siteId) async =>
      (await call('operator_list_deliveries', {'p_location_id': siteId})
              as List)
          .map((row) => Delivery(Json.from(row)))
          .toList();
  Future<Json> team(String siteId) async =>
      Json.from(await business(siteId, 'team'));
  Future<dynamic> business(
    String siteId,
    String action, [
    Json payload = const {},
  ]) => call('business_workspace', {
    'p_location_id': siteId,
    'p_action': action,
    'p_payload': payload,
  });
}

class SupabaseBusinessRepository extends BusinessRepository {
  final SupabaseClient client;
  final String _userId;
  final FlutterSecureStorage storage;
  SupabaseBusinessRepository(
    this.client, {
    this.storage = const FlutterSecureStorage(),
  }) : _userId = client.auth.currentUser!.id;
  @override
  String get userId => _userId;
  void _checkSession() {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Votre session a changé. Reconnectez-vous.');
    }
  }

  @override
  Future<dynamic> call(String name, [Json params = const {}]) async {
    _checkSession();
    final result = await client.rpc(name, params: params);
    if (result is Map && result['error'] != null) {
      throw BusinessError(result['error'].toString());
    }
    return result;
  }

  String get _pendingKey => 'yolo.business.pending.$userId';
  @override
  Future<Json?> readPending() async {
    _checkSession();
    final value = await storage.read(key: _pendingKey);
    return value == null ? null : Json.from(jsonDecode(value));
  }

  @override
  Future<void> savePending(Json? pending) async {
    _checkSession();
    if (pending == null) {
      await storage.delete(key: _pendingKey);
    } else {
      await storage.write(key: _pendingKey, value: jsonEncode(pending));
    }
  }
}

class BusinessError implements Exception {
  final String message;
  const BusinessError(this.message);
  @override
  String toString() => message;
}

String friendlyError(Object e) {
  if (e is BusinessError) return e.message;
  if (e is FormatException) return e.message;
  if (e is AuthException) {
    return e.statusCode == '429'
        ? 'Trop de tentatives. Patientez quelques minutes.'
        : 'Vérifiez vos identifiants et votre connexion.';
  }
  if (e is PostgrestException) {
    if (e.code == 'P0001') return e.message;
    if (e.code == '42501') {
      return 'Vous ne disposez pas des droits nécessaires pour cette action.';
    }
    if (e.code == 'PGRST202') {
      return 'Ce service doit être activé par l’équipe YOLO.';
    }
  }
  return 'Connexion interrompue. Vérifiez votre réseau puis réessayez.';
}

/// Persist before sending; retry after timeout keeps the same payload and ID.
class BatchSubmission {
  final BusinessRepository repository;
  bool _busy = false;
  BatchSubmission(this.repository);
  Future<Json> submit(Json payload) async {
    if (_busy) throw const BusinessError('Une demande est déjà en cours.');
    _busy = true;
    try {
      final pending =
          await repository.readPending() ??
          {'key': const Uuid().v4(), 'payload': payload};
      final parcels = (pending['payload']['parcels'] as List);
      if (parcels.any((p) => (p['cash_to_collect'] ?? 0) != 0)) {
        throw const BusinessError(
          'Cette demande comporte un encaissement de produit. Contactez YOLO avant de la reprendre.',
        );
      }
      await repository.savePending(pending);
      dynamic result;
      try {
        result = await repository.call('operator_create_batch', {
          'p_payload': pending['payload'],
          'p_request_id': pending['key'],
        });
      } on PostgrestException catch (e) {
        final code = e.code ?? '';
        if (code == 'P0001' || code.startsWith('22') || code.startsWith('23')) {
          await repository.savePending(null);
        }
        rethrow;
      }
      await repository.savePending(null);
      return Json.from(result);
    } finally {
      _busy = false;
    }
  }
}
