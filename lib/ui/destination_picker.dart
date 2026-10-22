import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../data/models.dart';
import 'components.dart';

const areas = <(String, double, double)>[
  ('Akwa, Douala', 4.051, 9.703),
  ('Bonapriso, Douala', 4.025, 9.705),
  ('Bonanjo, Douala', 4.043, 9.689),
  ('Bali, Douala', 4.039, 9.706),
  ('Deido, Douala', 4.074, 9.713),
  ('Bonamoussadi, Douala', 4.099, 9.742),
  ('Makepe, Douala', 4.093, 9.754),
  ('Bepanda, Douala', 4.069, 9.737),
  ('Bastos, Yaoundé', 3.897, 11.51),
  ('Mvan, Yaoundé', 3.817, 11.52),
  ('Mendong, Yaoundé', 3.826, 11.463),
  ('Essos, Yaoundé', 3.881, 11.546),
];

class DestinationPicker extends StatefulWidget {
  final Destination? initial;
  const DestinationPicker({super.key, this.initial});
  @override
  State<DestinationPicker> createState() => _DestinationPickerState();
}

class _DestinationPickerState extends State<DestinationPicker> {
  final map = MapController();
  late LatLng point;
  String area = '';
  bool positioned = false;
  @override
  void initState() {
    super.initState();
    point = LatLng(widget.initial?.lat ?? 4.051, widget.initial?.lng ?? 9.703);
    area = widget.initial?.area ?? '';
    positioned = widget.initial?.confirmed ?? false;
  }

  @override
  void dispose() {
    map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confirmer la destination')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LabeledField(
                label: 'Quartier',
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: 'Sélectionner un quartier',
                  ),
                  isExpanded: true,
                items: areas
                    .map(
                      (a) => DropdownMenuItem(value: a.$1, child: Text(a.$1)),
                    )
                    .toList(),
                onChanged: (value) {
                  final a = areas.firstWhere((a) => a.$1 == value);
                  setState(() {
                    area = a.$1;
                    point = LatLng(a.$2, a.$3);
                    positioned = false;
                  });
                  map.move(point, 15);
                },
              ),
            ),
              const SizedBox(height: 10),
              Text(
                'Touchez la carte à l’adresse exacte. Les quartiers sont des repères indicatifs.',
                style: TextStyle(color: YoloTheme.mutedColor(context)),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: map,
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              onTap: (_, location) => setState(() {
                point = location;
                positioned = true;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.tiles,
                userAgentPackageName: 'com.yolo.business.yolo_business_mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: YoloTheme.ink,
                      size: 44,
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontFamily: 'Geist Mono', fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: positioned
                    ? () => Navigator.pop(
                        context,
                        Destination(
                          point.latitude,
                          point.longitude,
                          area: area,
                          confirmed: true,
                        ),
                      )
                    : null,
                child: const Text('Confirmer ce repère'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
