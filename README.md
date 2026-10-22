# YOLO Business mobile

Application Flutter Android/iOS pour les entreprises et vendeurs de YOLO.
Logique métier : YOLO Business web. Design : YOLO E-Commerce, en noir, blanc et gris.

## Essayer

La configuration publique du Supabase existant est dans `config/local.json` (ignorée par Git).

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=config/local.json
```

Pour un téléphone Android connecté, remplacer `chrome` par son identifiant donné par `flutter devices`.
Le même e-mail et mot de passe que YOLO Business web donnent accès aux mêmes points autorisés.

Aperçu autonome avec données fictives, sans connexion ni écriture Supabase :

```powershell
flutter run -d chrome --dart-define=DEMO=true
```

Le script `scripts/run.ps1 -Mode live -Device chrome` (ou `-Mode demo`) prépare la même commande.

## Parcours implémentés

- Connexion, session persistante sécurisée, récupération du mot de passe via le web, profil et changement du mot de passe.
- Tableau de bord, sélection du point, liste avec recherche/filtres, détails et actualisation au premier plan.
- Création multicolis, repère cartographique confirmé, récapitulatif et reprise des demandes sans doublons.
- Modification avant attribution, colis prêt, code de retrait, confirmation de remise physique, annulation et réémission du code destinataire.
- Points de retrait, équipe, invitations par lien, révocation et gestion des accès selon les autorisations serveur.

## Vérifier et compiler

```powershell
flutter analyze
flutter test --reporter expanded
flutter build apk --debug --dart-define-from-file=config/local.json
flutter build web --dart-define-from-file=config/local.json --no-tree-shake-icons
```

Les tests couvrent les règles de transport, les réponses réseau incertaines, les appels concurrents, le changement de point, les lectures en échec et le rendu mobile. Ils génèrent des captures dans `artifacts/`.

L’aperçu compilé se régénère avec `flutter build web --dart-define=DEMO=true --output=build/preview --no-wasm-dry-run --no-tree-shake-icons`, puis `node scripts/preview-server.mjs` le sert à l’adresse `http://127.0.0.1:5174`. Le maintien de la police Iconsax complète évite une erreur de sous-ensemble de police du SDK actuel.

Pour iOS : ouvrir `ios/Runner.xcworkspace` sur macOS, configurer l’équipe Apple, puis compiler avec les mêmes paramètres Supabase. Ne pas diffuser la signature Android de développement sur le Play Store.

## Organisation

- `lib/core` : thème neutre et configuration.
- `lib/data` : modèles, appels aux services Business, stockage et état du point courant.
- `lib/ui` : écrans et composants partagés.
- `config/example.json` : modèle de configuration pour un autre poste.
- `docs/IMPLEMENTATION.md` : correspondance avec le web, règles de sécurité et fonctionnalités restantes.

Les versions des dépendances sont fixées et `pubspec.lock` doit être conservé. Aucune clé secrète/service_role ne doit être utilisée dans une application mobile.
