import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../core/constants/colors.dart';
import '../core/theme.dart';
import '../data/business_repository.dart';
import '../data/models.dart';
import '../data/workspace_controller.dart';
import 'components.dart';
import 'create_delivery.dart';
import 'delivery_detail.dart';
import 'destination_picker.dart';
import 'team_page.dart';
import 'account_page.dart';

class WorkspacePage extends StatefulWidget {
  final BusinessRepository repository;
  final String email;
  final VoidCallback? exitDemo;
  const WorkspacePage({
    super.key,
    required this.repository,
    required this.email,
    this.exitDemo,
  });
  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage>
    with WidgetsBindingObserver {
  late final controller = WorkspaceController(widget.repository);
  int tab = 0;
  String query = '', filter = 'all';
  bool siteBusy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.refresh();
      controller.resume();
    } else {
      controller.pause();
    }
  }

  void openDelivery(Delivery d) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          DeliveryDetailPage(deliveryId: d.id, controller: controller),
    ),
  );
  Future<void> create() async {
    if (controller.site == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDeliveryPage(
          repository: widget.repository,
          site: controller.site!,
        ),
      ),
    );
    try {
      await controller.checkPending();
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
    await controller.refresh();
  }

  Future<void> chooseSite() async {
    if (controller.pending) {
      toast(
        context,
        'Reprenez la demande en attente avant de changer de point.',
      );
      return;
    }
    final result = await showModalBottomSheet<PickupSite>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Choisir un point de retrait',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            for (final s in controller.sites)
              ListTile(
                leading: const Icon(Iconsax.shop),
                title: Text(s.name),
                subtitle: Text(s.address),
                trailing: s.id == controller.site?.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (result != null && mounted) await controller.selectSite(result);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Brand(),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.loading ? null : controller.refresh,
            icon: const Icon(Iconsax.refresh, size: 21),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Mon espace',
              onPressed: () => setState(() => tab = 3),
              icon: const Icon(Iconsax.profile_circle, size: 25),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: RefreshIndicator(
            onRefresh: controller.initialize,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 130),
              children: [
                if (AppConfig.demo)
                  const Notice(
                    'APERÇU • Données fictives, aucune opération réelle.',
                  ),
                if (controller.site != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: chooseSite,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Iconsax.location, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.site!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                if (controller.error != null)
                  Notice(controller.error!, retry: controller.initialize),
                if (controller.pending)
                  Notice(
                    'Une demande attend sa confirmation. Touchez « Nouvelle livraison » pour la reprendre.',
                  ),
                if (controller.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.sites.isEmpty && tab != 3) ...[
                  const EmptyState(
                    'Votre espace vous attend.',
                    'Aucun point de retrait ne vous est encore attribué. Demandez à votre responsable de vous inviter.',
                    icon: Iconsax.shop,
                  ),
                  TextButton(
                    onPressed: () => setState(() => tab = 3),
                    child: const Text('Accéder à mon compte'),
                  ),
                ] else
                  ...switch (tab) {
                    0 => dashboard(),
                    1 => deliveries(),
                    2 => sites(),
                    _ => account(),
                  },
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Theme.of(context).cardColor.withValues(alpha: .92),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        nav(0, Iconsax.home, 'Accueil'),
                        nav(1, Iconsax.box, 'Livraisons'),
                        nav(2, Iconsax.shop, 'Points'),
                        nav(3, Iconsax.profile_circle, 'Mon espace'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget nav(int index, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : YoloTheme.ink;
    final inactiveColor = isDark ? AppColors.darkMuted : YoloTheme.muted;
    return Expanded(
      child: Semantics(
        selected: tab == index,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => tab = index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: tab == index ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        tab == index ? FontWeight.w700 : FontWeight.w400,
                    color: tab == index ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  List<Widget> dashboard() {
    final active = controller.deliveries.where((d) => !d.finished).length;
    final done = controller.deliveries
        .where((d) => d.status == 'delivered')
        .length;
    return [
      const PageHeading(
        'VOTRE ESPACE ENTREPRISE',
        'Vos colis.\nToujours en mouvement.',
        'L’essentiel de votre activité, à portée de main.',
      ),
      Panel(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceHighest
            : YoloTheme.ink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.truck_fast, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'ON S’OCCUPE DU TRAJET.',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Un colis à envoyer ?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Préparez votre envoi. YOLO prend le relais.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: YoloTheme.ink,
              ),
              onPressed: controller.site?.active == true || controller.pending
                  ? create
                  : null,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Nouvelle livraison'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(child: stat('En cours', active, Iconsax.truck)),
          const SizedBox(width: 12),
          Expanded(child: stat('Livrées', done, Iconsax.box_tick)),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        'Sur les ${controller.deliveries.length} dernières livraisons chargées (100 maximum).',
        style: TextStyle(fontSize: 12, color: YoloTheme.mutedColor(context)),
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          Text(
            'Dernières livraisons',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => tab = 1),
            child: const Text('Tout voir →'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (controller.deliveries.isEmpty)
        const EmptyState(
          'Votre première livraison ?',
          'Créez un envoi pour suivre son parcours ici.',
        ),
      for (final d in controller.deliveries.take(3))
        DeliveryCard(d, onTap: () => openDelivery(d)),
      if (controller.updatedAt != null)
        Text(
          'Actualisé à ${dateLabel(controller.updatedAt!.toIso8601String())}',
          style: TextStyle(color: YoloTheme.mutedColor(context), fontSize: 12),
        ),
    ];
  }

  Widget stat(String label, int value, IconData icon) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 16),
        Text('$value', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: YoloTheme.mutedColor(context))),
      ],
    ),
  );
  List<Widget> deliveries() {
    final rows = controller.deliveries
        .where(
          (d) =>
              (filter == 'all' ||
                  filter == 'active' && !d.finished ||
                  d.status == filter) &&
              '${d.reference} ${d.recipient} ${d.address}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return [
      const PageHeading(
        'GARDER LE FIL',
        'Vos livraisons.',
        'De votre point de retrait à leur destination.',
      ),
      FilledButton.icon(
        onPressed: controller.site?.active == true || controller.pending
            ? create
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle livraison'),
      ),
      const SizedBox(height: 20),
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(
          hintText: 'Référence, destinataire, adresse…',
          prefixIcon: Icon(Iconsax.search_normal, size: 20),
        ),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in [
              ('all', 'Toutes'),
              ('active', 'En cours'),
              ('delivered', 'Livrées'),
              ('cancelled', 'Annulées'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    item.$2,
                    style: TextStyle(
                      color: filter == item.$1
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.ink
                              : Colors.white)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : YoloTheme.ink),
                    ),
                  ),
                  showCheckmark: false,
                  selected: filter == item.$1,
                  onSelected: (_) => setState(() => filter = item.$1),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text(
        '${rows.length} livraison(s)',
        style: TextStyle(color: YoloTheme.mutedColor(context)),
      ),
      const SizedBox(height: 12),
      if (rows.isEmpty)
        const EmptyState(
          'Aucune livraison ici.',
          'Essayez une autre recherche ou créez votre premier envoi.',
        ),
      for (final d in rows) DeliveryCard(d, onTap: () => openDelivery(d)),
    ];
  }

  List<Widget> sites() => [
    const PageHeading(
      'VOS ADRESSES DE DÉPART',
      'Points de retrait.',
      'Les lieux où vos colis commencent leur trajet.',
    ),
    for (final site in controller.sites)
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.shop, size: 28),
                  const Spacer(),
                  Text(
                    site.active ? 'ACTIF' : 'INACTIF',
                    style: const TextStyle(
                      fontFamily: 'Geist Mono',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(site.name, style: Theme.of(context).textTheme.titleLarge),
              Text(site.address),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: controller.pending && site.id != controller.site?.id
                    ? null
                    : () async {
                        await controller.selectSite(site);
                        if (mounted) setState(() => tab = 1);
                      },
                child: const Text('Voir les livraisons'),
              ),
              if (!site.confirmed)
                TextButton(
                  onPressed: siteBusy ? null : () => confirmSite(site),
                  child: const Text('Confirmer le repère de retrait'),
                ),
            ],
          ),
        ),
      ),
  ];
  Future<void> confirmSite(PickupSite site) async {
    final point = await Navigator.push<Destination>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DestinationPicker(initial: Destination(site.lat, site.lng)),
      ),
    );
    if (point == null || !mounted) return;
    setState(() => siteBusy = true);
    try {
      await widget.repository.call('operator_confirm_location', {
        'p_location_id': site.id,
        'p_lat': point.lat,
        'p_lng': point.lng,
      });
      await controller.initialize();
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => siteBusy = false);
    }
  }

  List<Widget> account() => [
    const PageHeading(
      'BIENVENUE CHEZ VOUS',
      'Mon espace.',
      'Votre entreprise, votre équipe et votre compte.',
    ),
    Panel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            child: const Icon(Iconsax.user),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compte YOLO Business',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                Text(widget.email),
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Iconsax.user_edit),
      title: const Text('Mon compte'),
      subtitle: const Text('Profil et sécurité'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      ),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Iconsax.people),
      title: const Text('Mon équipe'),
      subtitle: Text(controller.site?.name ?? 'Sélectionnez un point'),
      trailing: const Icon(Icons.chevron_right),
      onTap: controller.site == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamPage(
                  repository: widget.repository,
                  site: controller.site!,
                ),
              ),
            ),
    ),
    const Divider(),
    const Notice(
      'Les accès à vos points de retrait et à vos livraisons sont gérés par votre responsable YOLO.',
    ),
    OutlinedButton.icon(
      onPressed: () async {
        if (AppConfig.demo) {
          widget.exitDemo?.call();
          return;
        }
        if (!await confirmAction(
          context,
          'Se déconnecter ?',
          'Vos demandes en attente resteront disponibles à votre prochaine connexion.',
          'Se déconnecter',
        )) {
          return;
        }
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (e) {
          if (mounted) toast(context, friendlyError(e));
        }
      },
      icon: const Icon(Iconsax.logout),
      label: Text(AppConfig.demo ? 'Revenir à la connexion' : 'Se déconnecter'),
    ),
    const SizedBox(height: 28),
    Center(
      child: Text(
        'YOLO BUSINESS • VERSION 0.1.0',
        style: TextStyle(
          fontFamily: 'Geist Mono',
          fontSize: 10,
          color: YoloTheme.mutedColor(context),
        ),
      ),
    ),
  ];
}
