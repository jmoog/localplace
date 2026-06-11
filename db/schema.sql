-- =====================================================================
-- Annuaire local-place.fr — Schéma PostgreSQL
-- Modèle fermé au lancement, conçu pour l'ouverture progressive :
-- multi-métiers, géographie élargie, revendication de fiche, freemium.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- Référentiels
-- ---------------------------------------------------------------------

CREATE TABLE metiers (
    id          SERIAL PRIMARY KEY,
    slug        TEXT NOT NULL UNIQUE,          -- 'couvreur'
    nom         TEXT NOT NULL,                 -- 'Couvreur'
    nom_pluriel TEXT NOT NULL,                 -- 'Couvreurs'
    actif       BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE departements (
    id     SERIAL PRIMARY KEY,
    code   TEXT NOT NULL UNIQUE,               -- '91', '2A'…
    slug   TEXT NOT NULL UNIQUE,               -- 'essonne'
    nom    TEXT NOT NULL,                      -- 'Essonne'
    region TEXT,
    actif  BOOLEAN NOT NULL DEFAULT false      -- seuls les actifs génèrent des pages
);

CREATE TABLE villes (
    id             SERIAL PRIMARY KEY,
    slug           TEXT NOT NULL UNIQUE,       -- 'malesherbes' (stable, le SEO en dépend)
    nom            TEXT NOT NULL,              -- 'Malesherbes'
    code_postal    TEXT NOT NULL,
    code_insee     TEXT UNIQUE,
    departement_id INTEGER NOT NULL REFERENCES departements(id),
    lat            NUMERIC(9,6),
    lng            NUMERIC(9,6),
    population     INTEGER
);

CREATE INDEX idx_villes_departement ON villes(departement_id);

CREATE TABLE prestations (
    id        SERIAL PRIMARY KEY,
    slug      TEXT NOT NULL,                   -- 'reparation-toiture'
    nom       TEXT NOT NULL,                   -- 'Réparation de toiture'
    metier_id INTEGER NOT NULL REFERENCES metiers(id),
    UNIQUE (metier_id, slug)
);

-- ---------------------------------------------------------------------
-- Entreprises
-- ---------------------------------------------------------------------

CREATE TYPE statut_revendication AS ENUM (
    'geree_agence',      -- modèle fermé : fiche gérée par LocalPlace
    'non_revendiquee',   -- futur modèle ouvert : fiche pré-remplie
    'en_attente',        -- revendication en cours de vérification
    'revendiquee'        -- gérée par son propriétaire
);

CREATE TABLE entreprises (
    id                   SERIAL PRIMARY KEY,
    slug                 TEXT NOT NULL UNIQUE,  -- 'tg-couverture' (stable)
    nom                  TEXT NOT NULL,
    siret                TEXT UNIQUE,
    metier_id            INTEGER NOT NULL REFERENCES metiers(id),
    ville_id             INTEGER NOT NULL REFERENCES villes(id),
    adresse              TEXT,
    code_postal          TEXT,
    tel                  TEXT,
    email                TEXT,
    site_url             TEXT,                  -- lien vers le site client (synergie LocalPlace)
    description          TEXT,                  -- contenu rédigé, jamais généré en masse
    annee_creation       INTEGER,
    garantie_decennale   BOOLEAN NOT NULL DEFAULT false,
    statut_revendication statut_revendication NOT NULL DEFAULT 'geree_agence',
    actif                BOOLEAN NOT NULL DEFAULT true,
    stripe_customer_id   TEXT,                  -- dormant (monétisation future)
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_entreprises_ville  ON entreprises(ville_id);
CREATE INDEX idx_entreprises_metier ON entreprises(metier_id);

CREATE TABLE entreprise_prestations (
    entreprise_id INTEGER NOT NULL REFERENCES entreprises(id) ON DELETE CASCADE,
    prestation_id INTEGER NOT NULL REFERENCES prestations(id) ON DELETE CASCADE,
    PRIMARY KEY (entreprise_id, prestation_id)
);

-- Zones d'intervention au-delà de la ville siège (nourrit les pages villes)
CREATE TABLE entreprise_zones (
    entreprise_id INTEGER NOT NULL REFERENCES entreprises(id) ON DELETE CASCADE,
    ville_id      INTEGER NOT NULL REFERENCES villes(id) ON DELETE CASCADE,
    PRIMARY KEY (entreprise_id, ville_id)
);

-- ---------------------------------------------------------------------
-- Avis (auto-hébergés — condition des étoiles SERP)
-- ---------------------------------------------------------------------

CREATE TYPE statut_moderation AS ENUM ('en_attente', 'publie', 'rejete');

CREATE TABLE avis (
    id                SERIAL PRIMARY KEY,
    entreprise_id     INTEGER NOT NULL REFERENCES entreprises(id) ON DELETE CASCADE,
    auteur_nom        TEXT NOT NULL,
    auteur_email      TEXT,                     -- jamais affiché (RGPD : vérification uniquement)
    auteur_ville      TEXT,
    note              SMALLINT NOT NULL CHECK (note BETWEEN 1 AND 5),
    titre             TEXT,
    commentaire       TEXT NOT NULL,
    prestation_id     INTEGER REFERENCES prestations(id),
    statut            statut_moderation NOT NULL DEFAULT 'en_attente',
    source            TEXT NOT NULL DEFAULT 'site',  -- 'site' | 'migration_wp'
    date_experience   DATE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),  -- conserver la date d'origine en migration
    ip_hash           TEXT,                     -- anti-abus, jamais l'IP en clair
    spam_score        SMALLINT                  -- sortie du scoring anti-spam
);

CREATE INDEX idx_avis_entreprise        ON avis(entreprise_id);
CREATE INDEX idx_avis_entreprise_statut ON avis(entreprise_id, statut);

CREATE TABLE reponses_avis (
    id         SERIAL PRIMARY KEY,
    avis_id    INTEGER NOT NULL UNIQUE REFERENCES avis(id) ON DELETE CASCADE,
    user_id    INTEGER NOT NULL,               -- FK ajoutée après création de users
    contenu    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Utilisateurs (admin = Joseph, owner = client — cœur de la future app)
-- ---------------------------------------------------------------------

CREATE TYPE user_role AS ENUM ('admin', 'owner');

CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,               -- argon2id
    role          user_role NOT NULL DEFAULT 'owner',
    entreprise_id INTEGER REFERENCES entreprises(id),  -- NULL pour les admins
    actif         BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE reponses_avis
    ADD CONSTRAINT fk_reponses_user FOREIGN KEY (user_id) REFERENCES users(id);

-- Sessions (auth espace client / API app mobile)
CREATE TABLE sessions (
    id         TEXT PRIMARY KEY,               -- token aléatoire (hashé côté app si besoin)
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sessions_user ON sessions(user_id);

-- ---------------------------------------------------------------------
-- Tunnel d'acquisition (formulaire de demande, pas d'inscription libre)
-- ---------------------------------------------------------------------

CREATE TYPE statut_demande AS ENUM ('nouvelle', 'contactee', 'acceptee', 'refusee');

CREATE TABLE demandes_inscription (
    id          SERIAL PRIMARY KEY,
    nom_entreprise TEXT NOT NULL,
    siret       TEXT,
    nom_contact TEXT,
    tel         TEXT,
    email       TEXT NOT NULL,
    ville       TEXT,
    message     TEXT,
    statut      statut_demande NOT NULL DEFAULT 'nouvelle',
    spam_score  SMALLINT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Monétisation (DORMANT — aucune logique au lancement)
-- ---------------------------------------------------------------------

CREATE TABLE plans (
    id            SERIAL PRIMARY KEY,
    slug          TEXT NOT NULL UNIQUE,        -- 'fondateur', 'gratuit', 'premium'
    nom           TEXT NOT NULL,
    prix_mensuel  NUMERIC(8,2) NOT NULL DEFAULT 0,
    features      JSONB NOT NULL DEFAULT '{}',
    actif         BOOLEAN NOT NULL DEFAULT false
);

CREATE TYPE statut_abonnement AS ENUM ('actif', 'suspendu', 'resilie');

CREATE TABLE abonnements (
    id                     SERIAL PRIMARY KEY,
    entreprise_id          INTEGER NOT NULL REFERENCES entreprises(id),
    plan_id                INTEGER NOT NULL REFERENCES plans(id),
    stripe_subscription_id TEXT UNIQUE,
    statut                 statut_abonnement NOT NULL DEFAULT 'actif',
    date_debut             DATE NOT NULL DEFAULT CURRENT_DATE,
    date_fin               DATE
);

CREATE INDEX idx_abonnements_entreprise ON abonnements(entreprise_id);

-- ---------------------------------------------------------------------
-- Migration WordPress (traçabilité des 301)
-- ---------------------------------------------------------------------

CREATE TABLE redirections (
    id         SERIAL PRIMARY KEY,
    ancienne_url TEXT NOT NULL UNIQUE,         -- chemin WP, ex. '/meilleur-couvreur-malesherbes/'
    nouvelle_url TEXT NOT NULL,                -- ex. '/couvreur/malesherbes/'
    code       SMALLINT NOT NULL DEFAULT 301 CHECK (code IN (301, 410)),
    note       TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Vues utilitaires
-- ---------------------------------------------------------------------

-- Note moyenne et volume par entreprise (alimente AggregateRating + classements)
CREATE VIEW v_entreprises_notes AS
SELECT
    e.id AS entreprise_id,
    COUNT(a.id) FILTER (WHERE a.statut = 'publie')        AS nb_avis,
    ROUND(AVG(a.note) FILTER (WHERE a.statut = 'publie'), 1) AS note_moyenne
FROM entreprises e
LEFT JOIN avis a ON a.entreprise_id = e.id
GROUP BY e.id;

-- Villes indexables (règle anti-doorway : ≥ 1 fiche active, siège OU zone)
CREATE VIEW v_villes_indexables AS
SELECT DISTINCT v.*
FROM villes v
JOIN departements d ON d.id = v.departement_id AND d.actif = true
WHERE EXISTS (
    SELECT 1 FROM entreprises e
    WHERE e.actif = true AND e.ville_id = v.id
)
OR EXISTS (
    SELECT 1 FROM entreprise_zones ez
    JOIN entreprises e ON e.id = ez.entreprise_id AND e.actif = true
    WHERE ez.ville_id = v.id
);

COMMIT;
