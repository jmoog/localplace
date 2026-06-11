// @ts-check
import { defineConfig, envField } from 'astro/config';
import node from '@astrojs/node';

// https://docs.astro.build/en/reference/configuration-reference/
export default defineConfig({
  site: 'https://local-place.fr',

  // Hybride : tout est prerendered (statique) par défaut.
  // Les routes SSR (admin, API) déclarent `export const prerender = false`.
  output: 'static',

  // L'architecture d'URL est figée avec slash final (cf. CLAUDE.md).
  trailingSlash: 'always',

  adapter: node({
    mode: 'standalone',
  }),

  // Variables d'environnement typées et validées (astro:env).
  // Les secrets sont lus au runtime, jamais inlinés dans le build.
  env: {
    schema: {
      DATABASE_URL: envField.string({
        context: 'server',
        access: 'secret',
      }),
      BREVO_API_KEY: envField.string({
        context: 'server',
        access: 'secret',
        optional: true,
      }),
    },
  },
});
