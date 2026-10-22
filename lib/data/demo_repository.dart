import 'business_repository.dart';
import 'models.dart';

/// Explicit presentation mode. Never contacts Supabase and never writes a delivery.
class DemoRepository extends BusinessRepository {
  @override
  String get userId => 'demo';
  @override
  Future<Json?> readPending() async => null;
  @override
  Future<void> savePending(Json? pending) async {}
  @override
  Future<dynamic> call(String name, [Json params = const {}]) async {
    if (name == 'operator_workspace') {
      return {
        'is_admin': false,
        'locations': [
          {
            'id': 'demo-site',
            'name': 'Boutique Akwa',
            'address': 'Boulevard de la Liberté, Douala',
            'active': true,
            'lat': 4.051,
            'lng': 9.703,
            'position_confirmed_at': '2026-10-01T10:00:00Z',
          },
          {
            'id': 'demo-site-2',
            'name': 'Dépôt Bonapriso',
            'address': 'Bonapriso, Douala',
            'active': true,
            'lat': 4.025,
            'lng': 9.705,
            'position_confirmed_at': '2026-10-01T10:00:00Z',
          },
        ],
      };
    }
    if (name == 'operator_list_deliveries') {
      final now = DateTime.now();
      return List.generate(
        8,
        (i) => {
          'id': 'demo-$i',
          'reference': 'YL-${1048 - i}',
          'version': 1,
          'status': [
            'picked_up',
            'at_pickup',
            'searching',
            'delivered',
            'delivered',
            'delivered',
            'assigned',
            'cancelled',
          ][i],
          'recipient_name': [
            'Marie N.',
            'Paul M.',
            'Aïcha B.',
            'Sarah K.',
            'Daniel T.',
            'Émilie F.',
            'Christian N.',
            'Alice D.',
          ][i],
          'recipient_phone': '+237600000000',
          'dropoff_address': [
            'Bonamoussadi, Douala',
            'Bonapriso, Douala',
            'Makepe, Douala',
            'Akwa, Douala',
          ][i % 4],
          'dropoff_lat': 4.099,
          'dropoff_lng': 9.742,
          'ready': i != 2,
          'courier_fee': 1500,
          'courier_name': i == 0 || i == 1 ? 'Jean M.' : null,
          'plate': i == 0 ? 'LT 000 AB' : null,
          'created_at': now.subtract(Duration(hours: i * 2)).toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      );
    }
    if (name == 'business_workspace' && params['p_action'] == 'team') {
      return {
        'can_manage': false,
        'is_admin': false,
        'members': [
          {
            'id': 'demo',
            'email': 'responsable@exemple.com',
            'manager': true,
            'blocked': false,
            'admin': false,
          },
          {
            'id': 'demo-2',
            'email': 'preparation@exemple.com',
            'manager': false,
            'blocked': false,
            'admin': false,
          },
        ],
        'invitations': [],
      };
    }
    throw const BusinessError(
      'Aperçu uniquement. Connectez-vous à votre compte pour effectuer cette action.',
    );
  }
}
