# YOLO Business mobile — première base fonctionnelle

## Références

- Métier : `C:/Users/User/Documents/DEV/DEV-FREE/yolo-business-web`, parcours connecté `src/components/operations` et `src/components/business`. Les anciens contextes de démonstration et les factures produits masquées ne sont pas utilisés.
- Design uniquement : `C:/Users/User/Documents/DEV/DEV-FREE/YOLO-GENERAL/yolo-mobile`. Noir `#121317`, blanc, gris `#F6F6F6` et bordures `#EDEDED`, Barlow Condensed / Semi Condensed, Geist Mono, Iconsax et navigation flottante arrondie. Aucun accent vert dans le thème.
- Backend existant : projet Supabase `yolo-delivery`, référence `rctklynkqyvxyebasfrp`. Aucune migration ni modification des droits serveur pour ce client.

## Contrats repris du web

| Fonction serveur | Parcours mobile |
| --- | --- |
| `operator_workspace` | Points autorisés et indicateur administrateur |
| `operator_list_deliveries` | 100 derniers envois du point sélectionné |
| `operator_create_batch` | Création multicolis avec `p_request_id` persistant |
| `operator_edit_delivery` | Modification avant attribution, version attendue et identifiant de tentative |
| `operator_set_ready` | Déclarer le colis prêt |
| `operator_release_delivery` | Annuler avant retrait |
| `operator_issue_pickup` | Code temporaire du livreur |
| `operator_confirm_pickup` | Remise physique après validation du code par le livreur |
| `operator_reissue_recipient_code` | Réémission motivée du code destinataire |
| `operator_confirm_location` | Confirmation du repère d’un point de retrait |
| `business_workspace` | Liste d’équipe, invitation, révocation, blocage et retrait d’accès |

Les autorisations restent contrôlées par les fonctions serveur. Les métadonnées utilisateur ne servent qu’au nom affiché. Le client n’écrit jamais directement dans les tables privées et ne contient aucune clé de service.

Les sessions et demandes de création en attente utilisent le stockage sécurisé de l’appareil. Une demande en attente garde son contenu, son point de retrait et son UUID ; après une réponse réseau incertaine, la même demande est reprise. Le changement de point est bloqué jusqu’à sa résolution. Une erreur de validation définitive permet de corriger le formulaire. Les codes destinataires ne sont pas enregistrés dans les brouillons.

Les listes sont actualisées toutes les 15 secondes au premier plan. Une panne de lecture conserve les données et affiche un avertissement. Une réponse tardive d’un autre point ne remplace pas le point courant. Les codes de retrait sont masqués lorsque l’application passe en arrière-plan.

## Périmètre et limites

- Il s’agit d’une première version opérationnelle pour les comptes et points déjà autorisés. L’accès initial se demande via le site Business. Les invitations nominatives s’acceptent sur son parcours web existant ; les liens sont copiés, jamais envoyés automatiquement.
- Le mot de passe oublié utilise la page de récupération web existante. Le retour automatique vers l’app et l’acceptation native des invitations restent à ajouter.
- Les formulaires non envoyés vivent en mémoire. Seules les demandes de création envoyées et non confirmées sont persistées. Pas de création hors ligne différée.
- La recherche cartographique reprend les 12 quartiers pilotes de Douala et Yaoundé du web ; elle n’est pas un moteur de recherche de rues. Une épingle exacte doit être confirmée. Tuiles OpenStreetMap configurables, attribution visible.
- La rémunération du livreur est saisie manuellement, comme sur le web. `cash_to_collect` est toujours zéro. Tarification commerciale, paiement, reversement, incidents/retours et notifications push ne sont pas présentés comme disponibles.
- Les fonctions d’administration centrale des coursiers et du dispatch restent sur le web. L’app vise les entreprises et vendeurs.
- Les tests locaux ne remplacent pas une recette avec un compte commerçant et un livreur sur deux téléphones. Aucun envoi réel ni invitation réelle n’a été créé pendant l’implémentation.
- iOS nécessite macOS/Xcode, l’équipe Apple et la signature de distribution. Les droits Keychain sont préparés. La distribution Play Store nécessite aussi la signature définitive.

## Compatibilité de compilation Windows

Flutter 3.47.7 / Dart 3.13.5. Les implémentations officielles `path_provider_android` 2.2.23 et `path_provider_foundation` 2.5.1 sont fixées dans le projet : elles respectent les contraintes de `path_provider` et utilisent les plugins natifs classiques. Les versions FFI/JNI suivantes provoquaient un blocage du lancement des hooks sur ce poste. Aucun fichier du SDK Flutter n’a été modifié. Réévaluer ces deux versions lors d’une mise à jour du SDK, avec builds et tests sur appareils.

Gradle 9.3.1 est téléchargé depuis le serveur officiel avec contrôle SHA-256. Le NDK r28c (28.2.13676358) a été installé depuis l’archive Android officielle, après vérification SHA-1, car le nouvel outil Android interprétait mal la commande d’installation automatique de Flutter.

## Documentation des bibliothèques vérifiée

- [Initialisation Flutter Supabase](https://supabase.com/docs/reference/dart/initializing)
- [Authentification par mot de passe](https://supabase.com/docs/reference/dart/auth-signinwithpassword)
- [Client Supabase Flutter](https://pub.dev/packages/supabase_flutter)
- [Cartographie Flutter](https://pub.dev/packages/flutter_map)
