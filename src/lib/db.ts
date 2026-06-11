import postgres from 'postgres';
import { DATABASE_URL } from 'astro:env/server';

/**
 * Client PostgreSQL partagé (postgres.js).
 *
 * - Utilisé au build pour les pages prerendered (villes, fiches…)
 *   et au runtime pour les routes SSR (admin, API, app mobile plus tard).
 * - DATABASE_URL est validée par astro:env (cf. astro.config.mjs),
 *   lue au runtime, jamais inlinée dans le build.
 *
 * Usage :
 *   import sql from '../lib/db';
 *   const villes = await sql`select * from v_villes_indexables`;
 */
const sql = postgres(DATABASE_URL, {
  // Petit pool : l'essentiel du site est statique, le SSR est minoritaire.
  max: 10,
  // Les NOTICE PostgreSQL ne polluent pas les logs.
  onnotice: () => {},
});

export default sql;
