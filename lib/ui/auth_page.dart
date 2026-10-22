import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../data/business_repository.dart';
import 'components.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback? onDemo;
  final bool recovery;
  final VoidCallback? onRecovered;
  const AuthPage({
    super.key,
    this.onDemo,
    this.recovery = false,
    this.onRecovered,
  });
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  bool reset = false, visible = false, busy = false;
  String? error, notice;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (!AppConfig.configured || AppConfig.demo) {
      setState(
        () => error =
            'La connexion réelle est disponible avec la configuration Supabase de YOLO Business.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (widget.recovery) {
        await auth.updateUser(UserAttributes(password: password.text));
        password.clear();
        confirmation.clear();
        widget.onRecovered?.call();
      } else if (reset) {
        await auth.resetPasswordForEmail(
          email.text.trim(),
          redirectTo: '${AppConfig.businessUrl}/connexion?reset=1',
        );
        if (mounted) {
          setState(
            () => notice =
                'Si un compte correspond à cette adresse, vous recevrez un lien pour choisir un nouveau mot de passe sur le site YOLO Business. Revenez ensuite vous connecter ici.',
          );
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
        password.clear();
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(28),
            children: [
              const Align(alignment: Alignment.centerLeft, child: Brand()),
              const SizedBox(height: 52),
              Container(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  radius: 29,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  child: const Icon(Iconsax.box, size: 28),
                ),
              ),
              PageHeading(
                'YOLO VOUS ACCOMPAGNE',
                widget.recovery
                    ? 'Un nouveau départ.'
                    : reset
                    ? 'Mot de passe oublié ?'
                    : 'Votre business.\nPartout avec vous.',
                widget.recovery
                    ? 'Choisissez votre nouveau mot de passe.'
                    : reset
                    ? 'Retrouvez l’accès à votre espace.'
                    : 'Connectez-vous pour retrouver vos livraisons et votre équipe.',
              ),
              if (error != null) Notice(error!),
              if (notice != null) Notice(notice!),
              Form(
                key: form,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      if (!widget.recovery)
                        LabeledField(
                          label: 'Adresse e-mail',
                          child: TextFormField(
                            controller: email,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            autocorrect: false,
                            decoration: const InputDecoration(
                              hintText: 'vous@entreprise.com',
                            ),
                            validator: (v) =>
                                RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(v?.trim() ?? '')
                                ? null
                                : 'Saisissez une adresse e-mail valide.',
                          ),
                        ),
                      if (!reset || widget.recovery) ...[
                        LabeledField(
                          label: widget.recovery
                              ? 'Nouveau mot de passe'
                              : 'Mot de passe',
                          child: TextFormField(
                            controller: password,
                            enabled: !busy,
                            obscureText: !visible,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: [
                              widget.recovery
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              hintText: '••••••••••••',
                              suffixIcon: IconButton(
                                tooltip: visible
                                    ? 'Masquer le mot de passe'
                                    : 'Afficher le mot de passe',
                                onPressed: () =>
                                    setState(() => visible = !visible),
                                icon: Icon(
                                  visible ? Iconsax.eye_slash : Iconsax.eye,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                (v?.length ?? 0) < (widget.recovery ? 12 : 1)
                                ? widget.recovery
                                      ? '12 caractères minimum.'
                                      : 'Saisissez votre mot de passe.'
                                : null,
                          ),
                        ),
                      ],
                      if (widget.recovery) ...[
                        LabeledField(
                          label: 'Confirmer le mot de passe',
                          child: TextFormField(
                            controller: confirmation,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: '••••••••••••',
                            ),
                            validator: (v) => v != password.text
                                ? 'Les mots de passe doivent correspondre.'
                                : null,
                          ),
                        ),
                      ],
                      if (!reset && !widget.recovery)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(() {
                                    reset = true;
                                    error = null;
                                    notice = null;
                                    password.clear();
                                  }),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: Text(
                          busy
                              ? 'Veuillez patienter…'
                              : widget.recovery
                              ? 'Enregistrer mon mot de passe'
                              : reset
                              ? 'Recevoir le lien'
                              : 'Se connecter',
                        ),
                      ),
                      if (reset)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  reset = false;
                                  error = null;
                                  notice = null;
                                }),
                          child: const Text('Revenir à la connexion'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.onDemo != null)
                TextButton(
                  onPressed: widget.onDemo,
                  child: const Text('Explorer l’aperçu de l’application'),
                ),
              if (!widget.recovery)
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('${AppConfig.businessUrl}/contact'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Nouveau chez YOLO ? Demander un accès'),
                ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'VOS LIVRAISONS. EN TOUTE SIMPLICITÉ.',
                  style: TextStyle(
                    fontFamily: 'Geist Mono',
                    fontSize: 9,
                    letterSpacing: 1,
                    color: YoloTheme.mutedColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
