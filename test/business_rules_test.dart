import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yolo_business_mobile/data/models.dart';
import 'package:yolo_business_mobile/data/business_repository.dart';
import 'package:yolo_business_mobile/data/workspace_controller.dart';

class FakeRepository extends BusinessRepository {
  Json? pending;
  final calls = <(String, Json)>[];
  Future<dynamic> Function(String, Json)? response;
  @override
  String get userId => 'user-1';
  @override
  Future<Json?> readPending() async => pending;
  @override
  Future<void> savePending(Json? value) async {
    pending = value;
  }

  @override
  Future<dynamic> call(String name, [Json params = const {}]) async {
    calls.add((name, params));
    return response == null ? {'deliveries': []} : response!(name, params);
  }
}

ParcelDraft validParcel() => ParcelDraft()
  ..recipient = 'Client Test'
  ..phone = '+237 699 000 111'
  ..address = 'Bonapriso, Douala'
  ..fee = '1500'
  ..destination = const Destination(4.025, 9.705, confirmed: true);

void main() {
  test(
    'Transport only: no product collection and normalized recipient phone',
    () {
      final payload = validParcel().toJson(true, DateTime.utc(2026, 10, 21));
      expect(payload['cash_to_collect'], 0);
      expect(payload['courier_fee'], 1500);
      expect(payload['recipient_phone'], '+237699000111');
      expect(payload['destination_metadata']['confirmed'], true);
    },
  );
  test(
    'Destination must be explicitly confirmed; decimal fees and nonpositive weights rejected',
    () {
      final draft = validParcel()..destination = const Destination(4.02, 9.7);
      expect(draft.validate(), contains('Confirmez'));
      draft.destination = const Destination(4.02, 9.7, confirmed: true);
      draft.fee = '12.5';
      expect(draft.validate(), contains('entier'));
      draft.fee = '0';
      draft.weight = '0';
      expect(draft.validate(), contains('poids'));
    },
  );
  test('Not-ready parcels do not become immediately dispatchable', () {
    final payload = validParcel().toJson(false, DateTime.utc(2026));
    expect(payload['ready'], false);
    expect(payload['ready_at'], '2099-01-01T00:00:00Z');
  });
  test(
    'Network failure retains the exact request identity and payload across restart',
    () async {
      final repo = FakeRepository();
      repo.response = (_, _) async => throw TimeoutException('lost response');
      final payload = {
        'location_id': 'site-a',
        'external_reference': 'CMD-1',
        'parcels': [validParcel().toJson(true, DateTime.utc(2026))],
      };
      await expectLater(
        BatchSubmission(repo).submit(payload),
        throwsA(isA<TimeoutException>()),
      );
      final first = repo.calls.single.$2;
      expect(repo.pending, isNotNull);
      repo.response = (_, _) async => {'deliveries': []};
      await BatchSubmission(repo).submit({'location_id': 'other-site'});
      expect(repo.calls.last.$2, equals(first));
      expect(repo.pending, isNull);
    },
  );
  test('Definitive server validation failure unlocks correction', () async {
    final repo = FakeRepository()
      ..response = (_, _) async =>
          throw const PostgrestException(message: 'Invalid', code: 'P0001');
    await expectLater(
      BatchSubmission(repo).submit({'parcels': []}),
      throwsA(isA<PostgrestException>()),
    );
    expect(repo.pending, isNull);
  });
  test(
    'Concurrent submission is rejected before second network call',
    () async {
      final wait = Completer<Json>();
      final repo = FakeRepository()..response = (_, _) => wait.future;
      final service = BatchSubmission(repo);
      final first = service.submit({'parcels': []});
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        service.submit({'parcels': []}),
        throwsA(isA<BusinessError>()),
      );
      wait.complete({'deliveries': []});
      await first;
      expect(repo.calls.length, 1);
    },
  );
  test('Legacy pending product collections are blocked before RPC', () async {
    final repo = FakeRepository()
      ..pending = {
        'key': 'old',
        'payload': {
          'parcels': [
            {'cash_to_collect': 5000},
          ],
        },
      };
    await expectLater(
      BatchSubmission(repo).submit({}),
      throwsA(isA<BusinessError>()),
    );
    expect(repo.calls, isEmpty);
    expect(repo.pending, isNotNull);
  });
  test(
    'Changing pickup site discards late deliveries from the previous site',
    () async {
      final repo = FakeRepository();
      final a = Completer<List<Json>>(), b = Completer<List<Json>>();
      repo.response = (_, p) => p['p_location_id'] == 'a' ? a.future : b.future;
      final controller = WorkspaceController(repo);
      final first = controller.selectSite(const PickupSite({'id': 'a'}));
      final second = controller.selectSite(const PickupSite({'id': 'b'}));
      b.complete([
        {'id': 'b-delivery'},
      ]);
      await second;
      a.complete([
        {'id': 'a-delivery'},
      ]);
      await first;
      expect(controller.deliveries.single.id, 'b-delivery');
      controller.dispose();
    },
  );
  test(
    'Pending submission keeps its original pickup site until resolved',
    () async {
      final repo = FakeRepository()
        ..pending = {
          'payload': {'location_id': 'a'},
        }
        ..response = (name, _) async => name == 'operator_workspace'
            ? {
                'locations': [
                  {'id': 'a'},
                  {'id': 'b'},
                ],
              }
            : <Json>[];
      final controller = WorkspaceController(repo)
        ..site = const PickupSite({'id': 'b'});
      await controller.initialize();
      expect(controller.site?.id, 'a');
      await controller.selectSite(const PickupSite({'id': 'b'}));
      expect(controller.site?.id, 'a');
      repo.pending = null;
      await controller.checkPending();
      await controller.selectSite(const PickupSite({'id': 'b'}));
      expect(controller.site?.id, 'b');
      controller.dispose();
    },
  );
  test('Refresh failure preserves data and marks it stale', () async {
    final repo = FakeRepository()
      ..response = (_, _) async => [
        {'id': 'd'},
      ];
    final controller = WorkspaceController(repo);
    await controller.selectSite(const PickupSite({'id': 'a'}));
    final previous = controller.updatedAt;
    repo.response = (_, _) async => throw TimeoutException('offline');
    await controller.refresh();
    expect(controller.deliveries.single.id, 'd');
    expect(controller.updatedAt, previous);
    expect(controller.error, contains('anciennes'));
    controller.dispose();
  });
  test(
    'Status gates keep physical handover separate from delivery completion',
    () {
      expect(
        const Delivery({'id': '1', 'status': 'picked_up'}).beforePickup,
        false,
      );
      expect(
        const Delivery({'id': '1', 'status': 'at_pickup'}).acknowledged,
        false,
      );
      expect(const Delivery({'id': '1', 'status': 'delivered'}).finished, true);
    },
  );
}
