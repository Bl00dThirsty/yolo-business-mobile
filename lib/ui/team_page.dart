import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../data/business_repository.dart';
import '../data/models.dart';
import 'components.dart';

class TeamPage extends StatefulWidget {
  final BusinessRepository repository;
  final PickupSite site;
  const TeamPage({super.key, required this.repository, required this.site});
  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  Json? team;
  String? error, link;
  bool busy = false;
  final email = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await widget.repository.team(widget.site.id);
      if (mounted) {
        setState(() {
          team = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    }
  }

  Future<void> act(String action, Json payload) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository.business(
        widget.site.id,
        action,
        payload,
      );
      if (!mounted) return;
      if (result['token'] != null) {
        link =
            '${AppConfig.businessUrl}/invitation#token=${Uri.encodeComponent(result['token'])}';
        email.clear();
      }
      toast(
        context,
        action == 'invite'
            ? 'Invitation créée. Copiez le lien pour le transmettre.'
            : 'Modification enregistrée.',
      );
      await load();
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Votre équipe')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageHeading(
            'TRAVAILLER ENSEMBLE',
            'Les bonnes personnes.',
            widget.site.name,
          ),
          if (error != null) Notice(error!, retry: load),
          if (team == null && error == null)
            const Center(child: CircularProgressIndicator()),
          if (team != null) ...[
            if (team!['can_manage'] == true) ...[
              LabeledField(
                label: 'E-mail du collaborateur',
                child: TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'collaborateur@entreprise.com',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () {
                        if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(email.text.trim())) {
                          setState(
                            () =>
                                error = 'Saisissez une adresse e-mail valide.',
                          );
                          return;
                        }
                        act('invite', {'email': email.text.trim()});
                      },
                icon: const Icon(Iconsax.user_add, size: 20),
                label: const Text('Créer une invitation'),
              ),
              const SizedBox(height: 10),
              Text(
                'Valable 7 jours, pour cette adresse vérifiée uniquement. Aucun e-mail n’est envoyé automatiquement.',
                style: TextStyle(color: YoloTheme.mutedColor(context)),
              ),
              const SizedBox(height: 24),
            ],
            if (link != null) ...[
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lien d’invitation'),
                    const SizedBox(height: 10),
                    SelectableText(link!),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: link!));
                        if (context.mounted) toast(context, 'Lien copié.');
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copier le lien'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Collaborateurs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final member in team!['members'] as List)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  child: const Icon(Iconsax.user),
                ),
                title: Text(member['email'] ?? ''),
                subtitle: Text(
                  member['blocked'] == true
                      ? 'Accès bloqué'
                      : member['admin'] == true
                      ? 'Administrateur YOLO'
                      : member['manager'] == true
                      ? 'Responsable'
                      : 'Opérateur',
                ),
                trailing:
                    team!['can_manage'] == true &&
                        member['id'] != widget.repository.userId &&
                        member['admin'] != true &&
                        (member['manager'] != true || team!['is_admin'] == true)
                    ? PopupMenuButton<String>(
                        enabled: !busy,
                        onSelected: (action) async {
                          final block = member['blocked'] != true;
                          if (await confirmAction(
                                context,
                                action == 'member_remove'
                                    ? 'Retirer cet accès ?'
                                    : block
                                    ? 'Bloquer cet accès ?'
                                    : 'Rétablir cet accès ?',
                                member['email'] ?? '',
                                'Confirmer',
                              ) &&
                              mounted) {
                            await act(action, {
                              'id': member['id'],
                              if (action == 'member_block') 'blocked': block,
                            });
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'member_block',
                            child: Text(
                              member['blocked'] == true
                                  ? 'Rétablir l’accès'
                                  : 'Bloquer l’accès',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'member_remove',
                            child: Text('Retirer de l’équipe'),
                          ),
                        ],
                      )
                    : null,
              ),
            const Divider(),
            Text('Invitations', style: Theme.of(context).textTheme.titleLarge),
            if ((team!['invitations'] as List).isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aucune invitation en attente.'),
              ),
            for (final invite in team!['invitations'] as List)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(invite['email']),
                subtitle: Text(
                  invite['accepted_at'] != null
                      ? 'Acceptée'
                      : invite['revoked_at'] != null
                      ? 'Révoquée'
                      : 'Expire le ${dateLabel(invite['expires_at'])}',
                ),
                trailing:
                    team!['can_manage'] == true &&
                        invite['accepted_at'] == null &&
                        invite['revoked_at'] == null
                    ? IconButton(
                        tooltip: 'Révoquer l’invitation',
                        onPressed: busy
                            ? null
                            : () async {
                                if (await confirmAction(
                                      context,
                                      'Révoquer l’invitation ?',
                                      invite['email'],
                                      'Révoquer',
                                    ) &&
                                    mounted) {
                                  await act('invite_revoke', {
                                    'id': invite['id'],
                                  });
                                }
                              },
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
          ],
        ],
      ),
    ),
  );
}
