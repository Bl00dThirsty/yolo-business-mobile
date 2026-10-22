import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../data/business_repository.dart';
import 'components.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final name = TextEditingController(
    text: AppConfig.demo
        ? 'Compte de démonstration'
        : Supabase
                  .instance
                  .client
                  .auth
                  .currentUser
                  ?.userMetadata?['display_name'] ??
              '',
  );
  final password = TextEditingController(),
      confirmation = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> save(bool changePassword) async {
    if (busy) return;
    if (AppConfig.demo) {
      toast(context, 'Aperçu : aucune modification de compte.');
      return;
    }
    if (changePassword &&
        (password.text.length < 12 || password.text != confirmation.text)) {
      setState(
        () => error =
            'Utilisez au moins 12 caractères et confirmez le même mot de passe.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        changePassword
            ? UserAttributes(password: password.text)
            : UserAttributes(data: {'display_name': name.text.trim()}),
      );
      if (mounted) {
        password.clear();
        confirmation.clear();
        toast(context, 'Modification enregistrée.');
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon compte')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeading(
          'VOTRE PROFIL',
          'À votre image.',
          'Gérez vos informations et votre mot de passe.',
        ),
        if (error != null) Notice(error!),
        LabeledField(
          label: 'Nom affiché',
          child: TextField(
            controller: name,
            maxLength: 80,
            decoration: const InputDecoration(hintText: 'Votre nom complet'),
          ),
        ),
        OutlinedButton(
          onPressed: busy ? null : () => save(false),
          child: const Text('Enregistrer mon nom'),
        ),
        const Divider(),
        Text('Sécurité', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Nouveau mot de passe',
          child: TextField(
            controller: password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: '12 caractères minimum',
              helperText: '12 caractères minimum',
            ),
          ),
        ),
        LabeledField(
          label: 'Confirmer le mot de passe',
          child: TextField(
            controller: confirmation,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Répétez le mot de passe',
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : () => save(true),
          child: Text(busy ? 'Enregistrement…' : 'Changer mon mot de passe'),
        ),
      ],
    ),
  );
}
