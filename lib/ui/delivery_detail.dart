import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/business_repository.dart';
import '../data/models.dart';
import '../data/workspace_controller.dart';
import '../core/theme.dart';
import 'components.dart';
import 'create_delivery.dart';
import 'destination_picker.dart';

class DeliveryDetailPage extends StatefulWidget {
  final String deliveryId;
  final WorkspaceController controller;
  const DeliveryDetailPage({
    super.key,
    required this.deliveryId,
    required this.controller,
  });
  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage>
    with WidgetsBindingObserver {
  bool busy = false;
  String? error;
  Json? challenge;
  Timer? timer;
  final requests = <String, String>{};
  BusinessRepository get repository => widget.controller.repository;
  Delivery? get delivery => widget.controller.deliveries
      .where((d) => d.id == widget.deliveryId)
      .firstOrNull;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (challenge != null && mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => challenge = null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  Future<void> action(
    String name,
    Json params, {
    bool proof = false,
    bool pickup = false,
    bool idempotent = false,
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await repository.call(name, {
        'p_delivery_id': widget.deliveryId,
        ...params,
        if (idempotent)
          'p_request_id': requests.putIfAbsent(name, () => const Uuid().v4()),
      });
      requests.remove(name);
      if (!mounted) return;
      if (pickup) {
        setState(() => challenge = Json.from(result));
      } else if (proof) {
        await showProofs(context, [Json.from(result)]);
      } else {
        challenge = null;
        toast(context, 'Modification enregistrée.');
      }
      await widget.controller.refresh();
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reissue() async {
    final reason = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réémettre le code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vérifiez l’identité du destinataire. Son ancien code sera invalidé.',
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Motif (10 caractères minimum)',
              child: TextField(
                controller: reason,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Expliquez la raison…',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () {
              if (reason.text.trim().length >= 10) Navigator.pop(context, true);
            },
            child: const Text('Réémettre'),
          ),
        ],
      ),
    );
    final value = reason.text.trim();
    reason.dispose();
    if (accepted == true && mounted) {
      await action('operator_reissue_recipient_code', {
        'p_reason': value,
      }, proof: true);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final d = delivery;
        return Scaffold(
          appBar: AppBar(title: Text(d?.reference ?? 'Livraison')),
          body: d == null
              ? const EmptyState(
                  'Livraison indisponible',
                  'Actualisez la liste de vos livraisons.',
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    PageHeading('SUIVI DE LIVRAISON', d.recipient, d.reference),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill(d),
                    ),
                    const SizedBox(height: 24),
                    if (error != null) Notice(error!),
                    if (widget.controller.error != null)
                      Notice(
                        widget.controller.error!,
                        retry: widget.controller.refresh,
                      ),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fact(
                            'POINT DE RETRAIT',
                            widget.controller.site?.name ?? '',
                          ),
                          const Divider(),
                          fact('DESTINATION', d.address),
                          const SizedBox(height: 16),
                          fact('TÉLÉPHONE', d.data['recipient_phone'] ?? ''),
                          const Divider(),
                          fact(
                            'LIVREUR',
                            d.data['courier_name'] ??
                                'En attente d’attribution',
                          ),
                          if (d.data['plate'] != null)
                            Text(
                              '${d.data['vehicle'] ?? ''} • ${d.data['plate']}',
                            ),
                          const SizedBox(height: 16),
                          fact(
                            'PRÉPARATION',
                            d.ready ? 'Prêt pour le retrait' : 'En préparation',
                          ),
                          const SizedBox(height: 16),
                          fact(
                            'RÉMUNÉRATION DU LIVREUR',
                            money((d.data['courier_fee'] as num?) ?? 0),
                          ),
                          if ((d.data['instructions'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const Divider(),
                            fact('CONSIGNES', d.data['instructions']),
                          ],
                          const Divider(),
                          fact('CRÉÉE LE', dateLabel(d.data['created_at'])),
                          const SizedBox(height: 14),
                          fact('MISE À JOUR', dateLabel(d.data['updated_at'])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (challenge != null && d.status == 'at_pickup') ...[
                      Panel(
                        child: Column(
                          children: [
                            const Text('Code à saisir par le livreur attribué'),
                            const SizedBox(height: 12),
                            Text(
                              (DateTime.tryParse(
                                        challenge!['expires_at'] ?? '',
                                      )?.isAfter(DateTime.now()) ??
                                      false)
                                  ? challenge!['pin'].toString()
                                  : 'Expiré',
                              style: const TextStyle(
                                fontFamily: 'Geist Mono',
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              d.acknowledged
                                  ? 'Code validé. Confirmez après remise physique.'
                                  : 'En attente de validation par le livreur.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (d.beforePickup && !d.ready)
                      actionButton(
                        'Déclarer le colis prêt',
                        () => action('operator_set_ready', {
                          'p_ready': true,
                          'p_ready_at': DateTime.now()
                              .toUtc()
                              .toIso8601String(),
                        }),
                      ),
                    if (d.status == 'at_pickup') ...[
                      actionButton(
                        'Afficher le code de retrait',
                        () => action('operator_issue_pickup', {}, pickup: true),
                      ),
                      actionButton(
                        'Confirmer la remise physique',
                        d.acknowledged
                            ? () async {
                                if (await confirmAction(
                                      context,
                                      'Remettre le colis',
                                      'Avez-vous vérifié le livreur attribué et remis physiquement ce colis ?',
                                      'Confirmer la remise',
                                    ) &&
                                    mounted) {
                                  await action(
                                    'operator_confirm_pickup',
                                    {},
                                    idempotent: true,
                                  );
                                }
                              }
                            : null,
                      ),
                      if (!d.acknowledged)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Le livreur doit d’abord valider le code de retrait.',
                            style: TextStyle(color: YoloTheme.mutedColor(context)),
                          ),
                        ),
                    ],
                    if (d.status == 'searching')
                      actionButton('Modifier la livraison', () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditDeliveryPage(
                              delivery: d,
                              repository: repository,
                            ),
                          ),
                        );
                        await widget.controller.refresh();
                      }),
                    if (!d.finished)
                      actionButton('Réémettre le code destinataire', reissue),
                    if (d.beforePickup)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (await confirmAction(
                                      context,
                                      'Annuler cette livraison ?',
                                      'Le livreur ne prendra plus en charge ce colis.',
                                      'Annuler la livraison',
                                    ) &&
                                    mounted) {
                                  await action('operator_release_delivery', {
                                    'p_cancel': true,
                                  }, idempotent: true);
                                }
                              },
                        child: const Text('Annuler la livraison'),
                      ),
                    if (busy) const LinearProgressIndicator(),
                    const SizedBox(height: 24),
                  ],
                ),
        );
      },
    ),
  );
  Widget actionButton(String text, VoidCallback? callback) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton(onPressed: busy ? null : callback, child: Text(text)),
  );
  Widget fact(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          color: YoloTheme.mutedColor(context),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class EditDeliveryPage extends StatefulWidget {
  final Delivery delivery;
  final BusinessRepository repository;
  const EditDeliveryPage({
    super.key,
    required this.delivery,
    required this.repository,
  });
  @override
  State<EditDeliveryPage> createState() => _EditDeliveryPageState();
}

class _EditDeliveryPageState extends State<EditDeliveryPage> {
  late final name = TextEditingController(text: widget.delivery.recipient);
  late final phone = TextEditingController(
    text: widget.delivery.data['recipient_phone'],
  );
  late final address = TextEditingController(text: widget.delivery.address);
  late final instructions = TextEditingController(
    text: widget.delivery.data['instructions'] ?? '',
  );
  late Destination point = Destination(
    (widget.delivery.data['dropoff_lat'] as num).toDouble(),
    (widget.delivery.data['dropoff_lng'] as num).toDouble(),
    confirmed: true,
  );
  bool busy = false;
  String? error;
  String requestId = const Uuid().v4();
  Json? pendingPayload;
  @override
  void dispose() {
    for (final c in [name, phone, address, instructions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (name.text.trim().length < 2 ||
        address.text.trim().length < 3 ||
        !RegExp(
          r'^\+[1-9][0-9]{7,14}$',
        ).hasMatch(phone.text.replaceAll(RegExp(r'\s'), '')) ||
        !point.confirmed) {
      setState(
        () => error = 'Vérifiez le nom, le téléphone, l’adresse et le repère.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final payload = {
      'recipient_name': name.text.trim(),
      'recipient_phone': phone.text.replaceAll(RegExp(r'\s'), ''),
      'dropoff_address': address.text.trim(),
      'dropoff_lat': point.lat,
      'dropoff_lng': point.lng,
      'instructions': instructions.text.trim(),
    };
    if (pendingPayload != null &&
        pendingPayload.toString() != payload.toString()) {
      requestId = const Uuid().v4();
    }
    pendingPayload = payload;
    try {
      final result = await widget.repository.call('operator_edit_delivery', {
        'p_delivery_id': widget.delivery.id,
        'p_expected_version': widget.delivery.data['version'],
        'p_request_id': requestId,
        'p_payload': payload,
      });
      if (!mounted) return;
      if (result['recipient_code_changed'] == true) {
        await showProofs(context, [Json.from(result)]);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Modifier la livraison')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Notice(
            'Modification possible avant attribution d’un livreur. Changer le téléphone invalide le code destinataire précédent.',
          ),
          if (error != null) Notice(error!),
          for (final item in [
            (name, 'Destinataire'),
            (phone, 'Téléphone'),
            (address, 'Adresse'),
            (instructions, 'Consignes'),
          ])
            LabeledField(
              label: item.$2,
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: item.$1,
                enabled: !busy,
                decoration: InputDecoration(hintText: item.$2),
              ),
            ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final next = await Navigator.push<Destination>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DestinationPicker(initial: point),
                      ),
                    );
                    if (next != null && mounted) setState(() => point = next);
                  },
            child: const Text('Modifier le repère sur la carte'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      ),
    ),
  );
}
