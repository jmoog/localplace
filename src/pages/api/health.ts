import type { APIRoute } from 'astro';

// Route SSR : rendue à la demande, jamais prerendered.
export const prerender = false;

/**
 * GET /api/health/
 * Vérifie que le serveur SSR répond. Servira de cible de healthcheck
 * pour Coolify une fois déployé.
 */
export const GET: APIRoute = async () => {
  return new Response(
    JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    },
  );
};
