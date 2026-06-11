# Cartographie de migration WordPress → Astro

Crawl complet du WordPress effectué le 2026-06-11 (sitemaps + toutes les
pages). 17 URLs inventoriées. Règle directrice (CLAUDE.md, règle SEO n°4) :
toute URL avec des impressions GSC est conservée à l'identique ou redirigée
en 301 vers son équivalent exact. Jamais de 301 vers la home.

## 1. Inventaire des URLs

### Pages comparatives (le cœur du SEO actuel)

| URL WP | Title actuel | Contenu |
|---|---|---|
| `/meilleur-couvreur-loiret-45/` | Meilleurs couvreurs du 45 - Bien notés près de chez vous | 2 fiches listées (Robert couverture, Top Toitures) — ranke sur « meilleur couvreur 45 » et « meilleur couvreur Malesherbes » |
| `/5-meilleurs-couvreur-dans-lessonne/` | Meilleurs couvreurs du 91 - Bien notés près de chez vous | 1 fiche listée (ROBERT Jean-Jacques) |
| `/meilleurs-vendeurs-pneus-occasion-91/` | Les 5 meilleurs Vendeurs de pneus dans l'Essonne 91 | 1 fiche listée (Le docteur des Pneus) — hors métier couvreur |

### Fiches artisans (`/artisan/{slug}/`)

| URL WP | Entreprise | Métier / Dépt | Avis | État |
|---|---|---|---|---|
| `/artisan/top-toitures/` | Top Toitures (Jean Paul ROBERT, EI) | Couvreur, façadier / 45 Malesherbes | **4 avis 5,0** | Complète (services, horaires, SIRET partiel, lien top-toitures.fr) |
| `/artisan/robert-jean-jacques/` | M. ROBERT, SAS, SIREN 850 110 057 | Charpentier, couvreur, façadier / 91 St-Germain-lès-Arpajon | **4 avis 5,0** | Complète (lien robert-couvreur91.fr) |
| `/artisan/robert-couverture/` | ROBERT BRANDON, EI | Couvreur / 45 Escrennes | 0 avis | Complète (lien couvreur45.fr) |
| `/artisan/lj-couverture/` | LJ COUVERTURE, SAS, SIREN 903 567 972 | Charpentier, couvreur, façadier / 78 Chevreuse | 0 avis | Complète (lien lj-couvreur.fr) |
| `/artisan/le-docteur-des-pneus/` | Tony Bernard POPELIER, EI, SIREN 483 419 115 | Vente pneus occasion / 91 Boissy-sous-St-Yon | **3 avis 5,0** | Complète (lien doc-pneus.fr) — hors métier couvreur |
| `/artisan/argaillot-et-fils/` | Argaillot et fils | Couvreur, façadier / **17 Charente-Maritime** | 0 avis | Partielle (pas d'horaires ni description) — hors zone géographique |
| `/artisan/toits-de-france/` | (titre vide) | — / 78 ? | 0 avis | **Squelette de test** : title vide, pas de contact, zone d'intervention polluée (« testo », « la teste », villes du 17…) |
| `/artisan/` | Archive WP des fiches | — | — | Liste brute auto-générée |

### Pages utilitaires

| URL WP | Rôle |
|---|---|
| `/` | Accueil |
| `/inscription/` | Formulaire d'inscription |
| `/assistance/` | Aide / contact |
| `/offres-et-services/` | Offres (page agence) |
| `/plan/` | Plan du site |
| `/fiche-prototype/` | Prototype de fiche (page de travail) |

## 2. Avis à migrer (11 au total, avec leurs dates d'origine)

### Top Toitures — 4 avis, 5,0/5

| Date | Titre | Auteur |
|---|---|---|
| 2025-08-30 | Très satisfait | Cusin |
| 2025-08-30 | Devis rapide et bien placé | Mousse |
| 2025-08-18 | Traitement charpente | Huang |
| 2025-08-18 | Rénovation de ma toitures | Therese |

### ROBERT Jean-Jacques — 4 avis, 5,0/5

| Date | Titre | Auteur |
|---|---|---|
| 2025-08-20 | Démoussage et réparations : service client parfait | Françoise à Palaiseau |
| 2025-08-18 | Réfection complète : travail de pro, délais respectés | Philippe, Sainte-Geneviève-des-Bois |
| 2025-08-15 | Intervention rapide et efficace pour des infiltrations | Marie-Claire, Le Lardy |
| 2025-07-29 | Réfection complète : travail de pro, délais respectés | Sylvie Corbeil-Essonnes |

### Le docteur des Pneus — 3 avis, 5,0/5

| Date | Titre | Auteur |
|---|---|---|
| 2025-09-06 | efficace et professionnel | de Medeiros |
| 2025-08-21 | Depannage pneu | Cindy |
| 2025-08-20 | Notre dernier espoir! | Lena Devaye |

Le texte intégral des avis est sur les pages WP — à extraire en base lors
de la Phase 3 (`statut_moderation = 'valide'`, dates d'origine conservées).

## 3. Plan de redirections 301

### Acté (équivalents exacts dans la nouvelle architecture)

| URL WP | → Nouvelle URL | Note |
|---|---|---|
| `/` | `/` | Conservée |
| `/meilleur-couvreur-loiret-45/` | `/couvreur/loiret/` | Page départementale 45 — porte les requêtes « meilleur couvreur 45 » / « Malesherbes » |
| `/5-meilleurs-couvreur-dans-lessonne/` | `/couvreur/essonne/` | Page départementale 91 |
| `/artisan/top-toitures/` | `/entreprise/top-toitures/` | Slug conservé |
| `/artisan/robert-jean-jacques/` | `/entreprise/robert-jean-jacques/` | Slug conservé |
| `/artisan/robert-couverture/` | `/entreprise/robert-couverture/` | Slug conservé |
| `/artisan/lj-couverture/` | `/entreprise/lj-couverture/` | Slug conservé |
| `/artisan/` | `/couvreur/` | Page pilier = équivalent fonctionnel de l'archive |
| `/inscription/` | `/referencer-mon-entreprise/` | Même intention |

### Tranché le 2026-06-11 (décisions Joseph)

| URL WP | Décision |
|---|---|
| `/meilleurs-vendeurs-pneus-occasion-91/` | **2e métier activé dès le lancement** (vente de pneus d'occasion). 301 vers la future page classement du métier — proposition d'URL : `/pneus-occasion/essonne/` (pattern `/{metier}/{departement}/`, slug à valider) |
| `/artisan/le-docteur-des-pneus/` | 301 → `/entreprise/le-docteur-des-pneus/` (slug conservé, 3 avis migrés) |
| `/artisan/argaillot-et-fils/` | **410** — hors zone, ne migre pas |
| `/artisan/toits-de-france/` | **410** — fiche de test (vérifier l'absence d'impressions GSC avant) |

### Reste à trancher (pages utilitaires, faible enjeu)

| URL WP | Options |
|---|---|
| `/assistance/` | Page équivalente à créer, ou 410 |
| `/offres-et-services/` | Page agence — suivra l'agence sur son futur sous-domaine ? 301 externe ou 410 |
| `/plan/` | 410 (remplacé par sitemap.xml à la bascule) |
| `/fiche-prototype/` | 410 (page de travail) |

## 4. Constats utiles pour la suite

- Le WP est entièrement en `index, follow` : la bascule devra inverser
  proprement (301 actives + retrait du noindex Astro le même jour).
- Les fiches WP pointent déjà vers les sites clients (top-toitures.fr,
  robert-couvreur91.fr, couvreur45.fr, lj-couvreur.fr, doc-pneus.fr,
  entreprise-argaillot.fr) — synergie LocalPlace déjà en place, à
  reproduire.
- Les pages WP n'ont pas de balisage Schema.org visible dans le HTML —
  l'ajout de `RoofingContractor` + `AggregateRating` + `Review` sera un
  gain net.
- Données structurées disponibles sur les fiches WP à récupérer en base :
  SIREN/SIRET, adresses, téléphones, emails, horaires, zones
  d'intervention (listes de communes), services, galeries photos.
- À confirmer avec l'export GSC (Pages, 16 mois) : qu'aucune URL avec
  impressions ne manque à cet inventaire (le sitemap ne montre que les
  pages publiées).
