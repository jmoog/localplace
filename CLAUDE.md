# CLAUDE.md — Annuaire local-place.fr

## Le projet en une phrase

Annuaire SEO d'artisans couvreurs (auto-hébergé, avis natifs), démarrant en
modèle fermé avec les clients LocalPlace, conçu pour s'ouvrir progressivement
(multi-métiers, géographie élargie, inscription payante) sans refonte.

## Contexte business

- Propriétaire : Joseph, agence LocalPlace (sites + SEO pour artisans, IDF).
- L'annuaire vit sur l'apex `local-place.fr` (l'agence migrera sur un
  sous-domaine si besoin).
- Un embryon WordPress existe déjà et ranke sur des requêtes comparatives
  type « meilleur couvreur 45 », « meilleur couvreur Malesherbes » →
  **migration avec préservation d'URLs**, pas un lancement from scratch.
- Positionnement éditorial : intention **comparative** (« meilleur couvreur
  + ville »), complémentaire et non cannibale des sites clients qui visent
  le transactionnel (« couvreur + ville »).
- Synergie LocalPlace : fiches → lien vers sites clients ; sites clients →
  badge « avis vérifiés » avec lien retour.

## Périmètre au lancement (verrous évolutifs, RIEN en dur)

| Axe | Lancement | Ouverture future | Mécanisme |
|---|---|---|---|
| Métier | Couvreur uniquement | Paysagistes, etc. | table `metiers`, flag `actif` |
| Géographie | IDF (75/77/78/91/92/93/94/95) + limitrophes (60, 45, 27, 28, 89, 02, 10) | France | table `departements`, flag `actif` |
| Comptes | Fermé : Joseph crée fiches et comptes | Inscription libre + revendication | `statut_revendication`, rôles users |
| Monétisation | Gratuit / inclus contrat agence | Freemium + Stripe | tables `plans`, `abonnements` (dormantes) |

## Stack technique

- **Astro 6 hybride** : pages publiques prerendered (statique), espace
  admin/client + API en SSR (`export const prerender = false`).
- **PostgreSQL** sur Coolify (Hetzner CCX13, `coolify.local-place.fr`),
  reverse proxy Traefik.
- **Email transactionnel** : Brevo (pattern route API type `contact.ts`,
  cf. TG Couverture).
- Adapter : `@astrojs/node` (standalone). Déploiement : Coolify.
- Dév : Mac Apple Silicon, zsh, GitHub via SSH.
- Plus tard : app mobile React Native + Expo, cliente de l'API Astro.
  Toute la logique métier vit dans l'API, jamais dans l'app.

## Architecture d'URL (figée — le SEO en dépend)

```
/                              Accueil
/couvreur/                     Page pilier métier
/couvreur/{departement}/       ex. /couvreur/essonne/
/couvreur/{ville}/             ex. /couvreur/malesherbes/ — LA page qui
                               chasse « meilleur couvreur {ville} »
/entreprise/{slug}/            Fiche entreprise
/referencer-mon-entreprise/    Formulaire de demande (pas d'inscription
                               libre-service au lancement)
/avis/{entreprise-slug}/       Dépôt d'avis (ou intégré à la fiche)
```

Les prestations (réparation, zinguerie, démoussage…) sont du contenu DANS
les pages ville et les fiches, PAS un niveau d'URL — sauf combos à fort
volume validés en GSC plus tard.

## Règles SEO non négociables

1. **Anti-doorway** : une page `/couvreur/{ville}/` n'est générée et
   indexable que si la ville contient ≥ 1 fiche active. Les villes sans
   fiche n'existent pas. Pas de génération depuis la liste exhaustive des
   communes.
2. **Pages ville = mini-classement assumé** : fiches triées avec notes
   visibles (matche l'intention « meilleur couvreur »).
3. **Schema.org sur chaque fiche** : `RoofingContractor` +
   `AggregateRating` + `Review`. Avis réellement collectés sur le site
   (jamais importés de Google) — condition des étoiles SERP.
4. **Migration** : toute URL WordPress qui a des impressions GSC est
   conservée à l'identique ou redirigée en 301 vers son équivalent exact.
   Jamais de 301 vers la home. Les avis existants migrent avec leurs
   dates d'origine.
5. **Transparence DGCCRF** : si un futur plan payant influence le
   classement, mention obligatoire sur les pages de classement (prévoir
   l'emplacement dans le template dès maintenant).
6. `noindex` global tant que la recette n'est pas validée. Sitemap +
   robots.txt à la bascule.

## Conventions éditoriales (héritées des skills LocalPlace)

- Voix « je »/« nous » authentique, factuel et concret. Pas de contenu IA
  de masse : les villes partagent une structure, jamais un texte.
- Mots bannis : « crucial », « durabilité », « en outre », « en tant
  que », « travail soigné », « intervention soignée », « artisan de
  confiance », « méthode rigoureuse ». Jamais de phrase commençant par
  « Chaque ».
- Sujets interdits dans le contenu : climat/météo, architecture locale /
  patrimoine bâti, sécurité.
- Pas de promesse (« nous nous engageons ») ; pas de superlatif
  auto-attribué dans les fiches (le « meilleur » émerge du classement par
  avis, il n'est pas affirmé).
- Inline SVG, jamais d'emojis dans le contenu.
- Skills à utiliser : `seo-balises` (title/meta/H1), `seo-intentions`
  (cartographie et anti-cannibalisation), `internal-linking-audit`
  (maillage avant bascule), `seo-couvreur` (rédaction pages).

## Anti-spam formulaires

Reprendre le système multi-couches rodé sur neves-couvreur : honeypot +
time-trap + content scoring. S'applique au dépôt d'avis ET au formulaire
de demande de référencement.

## Modération

Tout avis arrive en `statut_moderation = 'en_attente'`. Validation
manuelle par Joseph. Idem pour les demandes de référencement (vérif SIRET
via API INSEE possible, gratuite).

## Base de données

Schéma complet dans `db/schema.sql`. Seed dans `db/seed.sql`.
Principes : référentiel départements France entière pré-rempli (seuls les
`actif = true` génèrent des pages), villes insérées au fil des besoins,
slugs uniques et stables (le SEO en dépend), tables de monétisation
présentes mais dormantes.

## Feuille de route

- [ ] **Phase 0 — Inventaire** : export GSC (Pages + Requêtes, 16 mois),
      crawl du WP, récupération des avis existants → cartographie de
      migration
- [ ] **Phase 1 — Infra** : service PostgreSQL sur Coolify, backups
- [ ] **Phase 2 — Init** : projet Astro, Git, .env, ce CLAUDE.md
- [ ] **Phase 3 — Base** : schema.sql, seed (départements, métier
      couvreur, clients réels), migration des avis WP
- [ ] **Phase 4 — Pages publiques** : layout, fiches, pages villes
      (classement), départements, pilier, accueil, 301, sitemap
- [ ] **Phase 5 — Avis & formulaires** : dépôt d'avis + anti-spam,
      formulaire de demande, modération
- [ ] **Phase 6 — Bascule** : recette, retrait noindex, DNS, GSC
- [ ] **Phase 7+** : espace client web → API → app React Native →
      inscription payante Stripe (déclencheur : demande entrante réelle)

## Préférences de travail

- Instructions pas à pas, fichiers complets (jamais de diffs partiels).
- Pattern de duplication : TG Couverture est le template maître des sites
  clients, mais l'annuaire est un projet à part entière (pas un dérivé).
