# NotifCraft

> **Mise à jour importante** : `codemagic.yaml` a été corrigé pour retrouver `project.yml`
> tout seul, même s'il n'est pas exactement à la racine du dépôt GitHub (cas fréquent quand
> on glisse un dossier entier lors de l'upload). Si tu avais déjà un dépôt GitHub créé avant
> cette version, remplace juste le fichier `codemagic.yaml` par celui-ci (voir étape 4 ci-dessous)
> — pas besoin de tout re-uploader.

App iOS pour créer des notifications locales personnalisées : titre, message, image, et fréquence
configurable (une fois, rafale en secondes, toutes les X minutes/heures, chaque jour, chaque semaine).

## Ce qu'il y a dans ce dossier

- `project.yml` → décrit le projet. **XcodeGen** le transforme en vrai projet Xcode
  (`NotifCraft.xcodeproj`) automatiquement, pas besoin de le créer à la main.
- `Sources/` → tout le code Swift/SwiftUI de l'app.
- `Resources/` → icône de l'app (couleur de marque 4EAE32) et couleur d'accent.
- `codemagic.yaml` → configuration prête à l'emploi pour compiler un `.ipa` dans le cloud,
  sans Mac.

## Obtenir le fichier .ipa — deux chemins possibles

Il y a deux workflows prêts dans `codemagic.yaml`. Choisis selon ta situation.

### Chemin A — `notifcraft-ipa-unsigned` (recommandé si tu n'as pas de compte Apple Developer)

Compile un `.ipa` **sans aucune signature**, donc **sans compte Apple Developer payant**.
Ce fichier ne s'installe pas tout seul sur un iPhone — il doit être signé au moment de
l'installation par un outil gratuit :

- **[Sideloadly](https://sideloadly.io)** (Windows ou Mac) — tu glisses le `.ipa`, tu te
  connectes avec un simple **Apple ID gratuit**, il installe l'app sur ton iPhone branché en
  USB. L'app expire au bout de 7 jours, il suffit de relancer Sideloadly pour la réinstaller.
- **[AltStore](https://altstore.io)** — fonctionne sur le même principe, avec un
  renouvellement automatique en arrière-plan tant que ton iPhone reste sur le même Wi-Fi
  que ton ordinateur de temps en temps.

Aucun des deux ne coûte rien. C'est le chemin le plus rapide pour tester l'app.

### Chemin B — `notifcraft-ipa` (si tu as ou veux un compte Apple Developer)

Produit un `.ipa` déjà signé, valable 1 an, installable directement sans repasser par un
outil tiers. Nécessite un **compte Apple Developer Program (99 $/an)** — obligatoire pour
cette voie, c'est une règle Apple, pas une limite de Codemagic.

### 1. Mettre le code sur GitHub

1. Crée un compte gratuit sur [github.com](https://github.com) si tu n'en as pas.
2. Crée un nouveau dépôt (bouton vert "New").
3. Mets tout le contenu de ce dossier dedans (glisser-déposer sur l'interface web GitHub
   fonctionne très bien pour un premier envoi).

### 2. Connecter Codemagic

1. Crée un compte sur [codemagic.io](https://codemagic.io) (gratuit, 500 minutes de build/mois).
2. "Add application" → sélectionne ton dépôt GitHub.
3. Codemagic détecte le fichier `codemagic.yaml` automatiquement, avec ses deux workflows.
4. **Seulement si tu choisis le Chemin B** : dans Team settings > Integrations, connecte ton
   compte Apple Developer (clé API App Store Connect) et nomme-la `appstore_credentials`.
   Pour le Chemin A, cette étape ne sert à rien, tu peux la sauter entièrement.

### 3. Lancer le build

1. Dans Codemagic, ouvre le workflow **`notifcraft-ipa-unsigned`** (Chemin A) ou
   **`notifcraft-ipa`** (Chemin B).
2. Clique sur "Start new build".
3. Attends 5 à 15 minutes.
4. Le fichier `.ipa` apparaît dans l'onglet "Artifacts" → télécharge-le.

### 4. Installer le .ipa sur ton iPhone

- **Chemin A (non signé)** → passe par Sideloadly ou AltStore (voir ci-dessus), qui signent
  et installent en une seule étape avec un Apple ID gratuit.
- **Chemin B (signé)** → utilise [Diawi](https://www.diawi.com) (gratuit) : tu déposes le
  `.ipa`, il te donne un lien à ouvrir depuis Safari sur ton iPhone, installation directe.

## Fonctionnalités incluses

- Créer, modifier, dupliquer, supprimer des notifications
- Choix libre du titre, du message et d'une image (galerie photo)
- Fréquences : une fois, rafale en secondes, toutes les X minutes, toutes les X heures,
  chaque jour, chaque semaine
- Date de début et date de fin optionnelle
- Activation/désactivation individuelle de chaque notification
- Bouton "Envoyer un aperçu maintenant" pour tester sans attendre
- Compteur de notifications programmées (avec explication de la limite iOS de 64)
- Réinitialisation du badge de l'app

## Une limite iOS à connaître (pas contournable)

Apple plafonne à **64 notifications programmées en même temps par app**, et interdit toute
répétition à moins de 60 secondes d'intervalle. NotifCraft gère ça intelligemment :

- "Chaque jour", "chaque semaine", "toutes les X minutes/heures" utilisent un seul
  déclencheur répétitif natif → un seul emplacement consommé, peu importe le nombre de
  répétitions dans le temps.
- Le mode "rafale en secondes" programme une série de notifications individuelles
  espacées de X secondes, dans la limite disponible. Une fois la rafale épuisée, il faut
  rouvrir l'app pour qu'elle en reprogramme une nouvelle — c'est l'app elle-même qui gère
  ce renouvellement à chaque ouverture.
