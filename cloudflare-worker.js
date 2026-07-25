/**
 * CORS Proxy Worker for CTRIM App
 * Deploy this to Cloudflare Workers to handle CORS for image requests
 *
 * Deployment Instructions:
 * 1. Go to https://workers.cloudflare.com/
 * 2. Open the existing worker (ctrim-image-proxy) or create a new one
 * 3. Click "Edit code" and paste this file
 * 4. Click "Deploy"
 * 5. If the worker URL changed, update:
 *    - lib/utility/network_image_helper.dart (ctrim_app)
 *    - lib/utility/image_url_helper.dart (ctrim_worship)
 *
 * Important: Google Drive responses include Cross-Origin-Resource-Policy:
 * same-site (and related COOP/COEP/CSP) plus their own Access-Control-* headers.
 * If those are forwarded, browsers block Image.network / fetch from your app
 * origin with ClientException: Load failed — even when status is 200.
 */

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

const HEADERS_TO_STRIP = [
  'cross-origin-resource-policy',
  'cross-origin-embedder-policy',
  'cross-origin-opener-policy',
  'content-security-policy',
  'x-content-security-policy',
  'x-frame-options',
  'set-cookie',
]

function corsHeaders(request) {
  const requested = request.headers.get('Access-Control-Request-Headers')
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    // Echo requested headers so Flutter web preflights (custom UA, etc.) succeed
    'Access-Control-Allow-Headers': requested || '*',
    'Access-Control-Max-Age': '86400',
    'Cross-Origin-Resource-Policy': 'cross-origin',
  }
}

function stripUnsafeHeaders(headers) {
  for (const name of HEADERS_TO_STRIP) {
    headers.delete(name)
  }
  // Never forward upstream CORS headers — they conflict with our proxy policy
  for (const name of [...headers.keys()]) {
    if (name.toLowerCase().startsWith('access-control-')) {
      headers.delete(name)
    }
  }
}

async function handleRequest(request) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(request) })
  }

  if (request.method !== 'GET' && request.method !== 'HEAD') {
    return new Response('Method not allowed', {
      status: 405,
      headers: { 'Content-Type': 'text/plain', ...corsHeaders(request) },
    })
  }

  const url = new URL(request.url)
  const targetUrl = url.searchParams.get('url')

  if (!targetUrl) {
    return new Response('Missing url parameter. Usage: ?url=https://example.com/image.jpg', {
      status: 400,
      headers: { 'Content-Type': 'text/plain', ...corsHeaders(request) },
    })
  }

  try {
    // Always GET upstream; browsers sending HEAD still get headers-only below
    const response = await fetch(targetUrl, {
      method: 'GET',
      redirect: 'follow',
      headers: {
        'User-Agent': 'CTRIM-Image-Proxy/1.0',
      },
    })

    const headers = new Headers(response.headers)
    stripUnsafeHeaders(headers)
    for (const [key, value] of Object.entries(corsHeaders(request))) {
      headers.set(key, value)
    }
    headers.set('Cache-Control', 'public, max-age=3600')

    return new Response(request.method === 'HEAD' ? null : response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    })
  } catch (error) {
    return new Response(`Failed to fetch resource: ${error.message}`, {
      status: 502,
      headers: {
        'Content-Type': 'text/plain',
        ...corsHeaders(request),
      },
    })
  }
}
