import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;
String money(num value) =>
    '${NumberFormat.decimalPattern('fr').format(value)} FCFA';
String dateLabel(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null
      ? 'Non renseignée'
      : DateFormat('dd MMM, HH:mm', 'fr').format(date.toLocal());
}

class PickupSite {
  final Json data;
  const PickupSite(this.data);
  String get id => data['id'] as String;
  String get name => data['name'] as String? ?? 'Point de retrait';
  String get address => data['address'] as String? ?? '';
  bool get active => data['active'] == true;
  bool get confirmed => data['position_confirmed_at'] != null;
  double get lat => (data['lat'] as num?)?.toDouble() ?? 4.051;
  double get lng => (data['lng'] as num?)?.toDouble() ?? 9.703;
}

class Delivery {
  final Json data;
  const Delivery(this.data);
  static const labels = {
    'searching': 'Recherche du livreur',
    'assigned': 'Livreur en route',
    'at_pickup': 'Au point de retrait',
    'picked_up': 'En livraison',
    'at_dropoff': 'Chez le destinataire',
    'delivered': 'Livrée',
    'cancelled': 'Annulée',
  };
  String get id => data['id'] as String;
  String get reference => data['reference'] as String? ?? 'Livraison';
  String get status => data['status'] as String? ?? '';
  String get label => labels[status] ?? 'Statut à vérifier';
  String get recipient => data['recipient_name'] as String? ?? '';
  String get address => data['dropoff_address'] as String? ?? '';
  bool get finished => ['delivered', 'cancelled'].contains(status);
  bool get beforePickup =>
      ['searching', 'assigned', 'at_pickup'].contains(status);
  bool get ready => data['ready'] == true;
  bool get acknowledged => data['pickup_acknowledged_at'] != null;
}

class Destination {
  final double lat, lng;
  final String area;
  final bool confirmed;
  const Destination(
    this.lat,
    this.lng, {
    this.area = '',
    this.confirmed = false,
  });
}

class ParcelDraft {
  String recipient = '',
      phone = '+237',
      address = '',
      landmark = '',
      description = '',
      weight = '1000',
      fee = '';
  Destination? destination;
  String? validate() {
    if (recipient.trim().length < 2) {
      return 'Renseignez le nom du destinataire.';
    }
    if (!RegExp(
      r'^\+[1-9][0-9]{7,14}$',
    ).hasMatch(phone.replaceAll(RegExp(r'\s'), ''))) {
      return 'Utilisez un téléphone international, par exemple +237…';
    }
    if (address.trim().length < 3) return 'Renseignez une adresse précise.';
    if (destination?.confirmed != true) {
      return 'Confirmez la destination sur la carte.';
    }
    if (int.tryParse(weight) == null || int.parse(weight) <= 0) {
      return 'Le poids doit être un entier positif en grammes.';
    }
    if (int.tryParse(fee) == null || int.parse(fee) < 0) {
      return 'La rémunération du livreur doit être un montant entier positif ou nul.';
    }
    return null;
  }

  Json toJson(bool ready, DateTime now) {
    final error = validate();
    if (error != null) throw FormatException(error);
    return {
      'recipient_name': recipient.trim(),
      'recipient_phone': phone.replaceAll(RegExp(r'\s'), ''),
      'dropoff_address': address.trim(),
      'dropoff_area': destination!.area,
      'dropoff_lat': destination!.lat,
      'dropoff_lng': destination!.lng,
      'description': description.trim(),
      'weight_grams': int.parse(weight),
      'courier_fee': int.parse(fee),
      'cash_to_collect': 0,
      'ready': ready,
      'ready_at': ready
          ? now.toUtc().toIso8601String()
          : '2099-01-01T00:00:00Z',
      'destination_metadata': {
        'method': 'map_pin',
        'confirmed': true,
        'provider': 'yolo-area-catalog-v1',
        'search_query': destination!.area,
        'landmark': landmark.trim(),
      },
    };
  }
}
