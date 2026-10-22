import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../data/business_repository.dart';
import '../data/models.dart';
import 'components.dart';
import 'destination_picker.dart';

class CreateDeliveryPage extends StatefulWidget {
  final BusinessRepository repository;
  final PickupSite site;
  const CreateDeliveryPage({
    super.key,
    required this.repository,
    required this.site,
  });
  @override
  State<CreateDeliveryPage> createState() => _CreateDeliveryPageState();
}

class _CreateDeliveryPageState extends State<CreateDeliveryPage> {
  final reference = TextEditingController();
  final parcels = [ParcelDraft()];
  late final submission = BatchSubmission(widget.repository);
  bool ready = true, busy = false, checking = true;
  Json? pending;
  String? error;
  int step = 0;
  @override
  void initState() {
    super.initState();
    loadPending();
  }

  Future<void> loadPending() async {
    try {
      pending = await widget.repository.readPending();
    } catch (e) {
      error =
          'Impossible de vérifier les demandes en attente. Rouvrez cette page avant de créer une livraison.';
    }
    if (mounted) setState(() => checking = false);
  }

  @override
  void dispose() {
    reference.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final payload =
          pending?['payload'] as Json? ??
          {
            'location_id': widget.site.id,
            'external_reference': reference.text.trim(),
            'parcels': parcels
                .map((p) => p.toJson(ready, DateTime.now()))
                .toList(),
          };
      final result = await submission.submit(payload);
      if (!mounted) return;
      await showProofs(
        context,
        (result['deliveries'] as List? ?? []).map((p) => Json.from(p)).toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      try {
        pending = await widget.repository.readPending();
      } catch (_) {
        /* Keep the form locked if storage is unavailable. */
      }
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void review() {
    if (reference.text.trim().isEmpty) {
      setState(() => error = 'Ajoutez votre référence de commande.');
      return;
    }
    for (var i = 0; i < parcels.length; i++) {
      final message = parcels[i].validate();
      if (message != null) {
        setState(() => error = 'Colis ${i + 1} : $message');
        return;
      }
    }
    setState(() {
      error = null;
      step = 1;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Nouvelle livraison')),
      body: checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                PageHeading(
                  'ENVOYER AVEC YOLO',
                  pending != null
                      ? 'Reprendre la demande.'
                      : step == 0
                      ? 'Votre prochain envoi.'
                      : 'Tout est prêt ?',
                  widget.site.name,
                ),
                if (error != null) Notice(error!),
                if (pending != null) ...[
                  const Notice(
                    'Une demande attend sa confirmation. Vérifiez son résultat avant de créer un nouvel envoi ; aucune livraison en double ne sera créée.',
                  ),
                  Panel(
                    child: Text(
                      'Référence : ${pending!['payload']['external_reference']}\n${(pending!['payload']['parcels'] as List).length} colis',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      busy ? 'Vérification…' : 'Vérifier la demande en attente',
                    ),
                  ),
                ] else if (step == 0) ...[
                  LabeledField(
                    label: 'Référence de commande',
                    child: TextField(
                      controller: reference,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        hintText: 'Ex. CMD-2026-1048',
                      ),
                    ),
                  ),
                  for (var i = 0; i < parcels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ParcelEditor(
                        key: ObjectKey(parcels[i]),
                        parcel: parcels[i],
                        number: i + 1,
                        remove: parcels.length > 1
                            ? () => setState(() => parcels.removeAt(i))
                            : null,
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: parcels.length < 20
                        ? () => setState(() => parcels.add(ParcelDraft()))
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un colis'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Colis prêts pour le retrait'),
                    subtitle: const Text(
                      'Sinon, vous les déclarerez prêts plus tard.',
                    ),
                    value: ready,
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    onChanged: (v) => setState(() => ready = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed:
                        error?.startsWith('Impossible de vérifier') == true
                        ? null
                        : review,
                    child: const Text('Vérifier ma demande'),
                  ),
                ] else ...[
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reference.text,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${parcels.length} colis • ${ready ? 'Prêts au retrait' : 'En préparation'}',
                        ),
                        const Divider(),
                        for (final p in parcels)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              '${p.recipient}\n${p.phone}\n${p.address}\n${p.weight} g • Livreur : ${money(int.parse(p.fee))}',
                            ),
                          ),
                        const Text(
                          'Rémunération du livreur saisie manuellement. Aucun encaissement de marchandises.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      busy ? 'Enregistrement…' : 'Créer la livraison',
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => setState(() => step = 0),
                    child: const Text('Modifier ma demande'),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    ),
  );
}

class ParcelEditor extends StatefulWidget {
  final ParcelDraft parcel;
  final int number;
  final VoidCallback? remove;
  const ParcelEditor({
    super.key,
    required this.parcel,
    required this.number,
    this.remove,
  });
  @override
  State<ParcelEditor> createState() => _ParcelEditorState();
}

class _ParcelEditorState extends State<ParcelEditor> {
  Widget field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    TextInputType? keyboard,
    String? hint,
  }) => LabeledField(
    label: label,
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: keyboard,
      decoration: InputDecoration(hintText: hint ?? label),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final p = widget.parcel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Colis ${widget.number.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            if (widget.remove != null)
              IconButton(
                onPressed: widget.remove,
                tooltip: 'Retirer ce colis',
                icon: const Icon(Iconsax.trash),
              ),
          ],
        ),
        const SizedBox(height: 14),
        field('Nom du destinataire', p.recipient, (v) => p.recipient = v),
        field(
          'Téléphone du destinataire',
          p.phone,
          (v) => p.phone = v,
          keyboard: TextInputType.phone,
        ),
        field('Adresse de livraison', p.address, (v) => p.address = v),
        OutlinedButton.icon(
          icon: Icon(
            p.destination?.confirmed == true ? Icons.check : Iconsax.location,
          ),
          label: Text(
            p.destination?.confirmed == true
                ? 'Destination confirmée • modifier'
                : 'Placer la destination sur la carte',
          ),
          onPressed: () async {
            final result = await Navigator.push<Destination>(
              context,
              MaterialPageRoute(
                builder: (_) => DestinationPicker(initial: p.destination),
              ),
            );
            if (result != null && mounted) {
              setState(() => p.destination = result);
            }
          },
        ),
        const SizedBox(height: 14),
        field('Repère / consignes d’accès', p.landmark, (v) => p.landmark = v),
        field('Description du colis', p.description, (v) => p.description = v),
        Row(
          children: [
            Expanded(
              child: field(
                'Poids (g)',
                p.weight,
                (v) => p.weight = v,
                keyboard: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: field(
                'Livreur (FCFA)',
                p.fee,
                (v) => p.fee = v,
                keyboard: TextInputType.number,
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}

Future<void> showProofs(
  BuildContext context,
  List<Json> proofs,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    title: const Text('Demande enregistrée'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transmettez chaque code uniquement au destinataire concerné. Les codes ne seront plus affichés après fermeture.',
          ),
          const SizedBox(height: 20),
          for (final p in proofs)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['reference']?.toString() ?? p['delivery_id'].toString(),
                  ),
                  if (p['recipient_phone'] != null) Text(p['recipient_phone']),
                  SelectableText(
                    p['recipient_pin']?.toString() ??
                        'Code déjà émis. Réémettez-le depuis le détail si nécessaire.',
                    style: TextStyle(
                      fontFamily: 'Geist Mono',
                      fontSize: p['recipient_pin'] == null ? 12 : 28,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('J’ai conservé les codes'),
      ),
    ],
  ),
);
