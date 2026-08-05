/**
 * CORS Proxy Worker for CTRIM apps (community + worship).
 * Proxies Google Drive image URLs so Flutter web can load them.
 *
 * Deployment:
 * 1. https://workers.cloudflare.com/ → worker `ctrim-image-proxy`
 * 2. Paste this file → Deploy
 * 3. If the worker URL changes, update:
 *    - ctrim_app: lib/utility/network_image_helper.dart
 *    - ctrim_worship: lib/utility/image_url_helper.dart
 *
 * Safety:
 * - Browser callers must come from an allowlisted Origin (or Referer).
 * - Upstream `url=` may only be https:// on allowlisted Drive-related hosts.
 * Origin checks stop other websites from using this from a browser; the host
 * allowlist stops open-proxy abuse via curl/scripts.
 *
 * Google Drive responses often include Cross-Origin-Resource-Policy: same-site
 * (and related headers). Those must be stripped or browsers block the image.
 */

addEventListener('fetch', (event) => {
  event.respondWith(handleRequest(event.request))
})

/** App origins allowed to receive CORS responses / call this worker from a browser. */
const ALLOWED_ORIGINS = new Set([
  'https://ctrim.app',
  'https://www.ctrim.app',
  // Worship web (same image proxy)
  'https://ctrimworship.web.app',
  'https://ctrimworship.firebaseapp.com',
  // Local Flutter web debug
  'http://localhost:7357', // ctrim_app
  'http://127.0.0.1:7357',
  'http://localhost:7358', // ctrim_worship
  'http://127.0.0.1:7358',
  // Add future Hosting / custom domains here as needed
])

/**
 * Hostnames we will fetch on behalf of the client.
 * Keep in sync with NetworkImageHelper / worship image_url_helper Drive patterns.
 */
const ALLOWED_TARGET_HOST_SUFFIXES = [
  'drive.google.com',
  'drive.usercontent.google.com',
  'googleusercontent.com', // lh3.googleusercontent.com, etc.
]

const HEADERS_TO_STRIP = [
  'cross-origin-resource-policy',
  'cross-origin-embedder-policy',
  'cross-origin-opener-policy',
  'content-security-policy',
  'x-content-security-policy',
  'x-frame-options',
  'set-cookie',
]

function isAllowedOrigin(origin) {
  return Boolean(origin) && ALLOWED_ORIGINS.has(origin)
}

function originFromReferer(referer) {
  if (!referer) return null
  try {
    const u = new URL(referer)
    return u.origin
  } catch {
    return null
  }
}

/** Resolve browser caller origin from Origin or Referer. */
function resolveCallerOrigin(request) {
  const origin = request.headers.get('Origin')
  if (origin) return origin
  return originFromReferer(request.headers.get('Referer'))
}

function isBrowserCallerAllowed(request) {
  const caller = resolveCallerOrigin(request)
  // No Origin/Referer: typically non-browser (curl). Host allowlist still applies.
  if (!caller) return true
  return isAllowedOrigin(caller)
}

function isAllowedTargetUrl(raw) {
  let u
  try {
    u = new URL(raw)
  } catch {
    return false
  }
  if (u.protocol !== 'https:') return false
  // Block obvious SSRF tricks
  if (u.username || u.password) return false

  const host = u.hostname.toLowerCase()
  if (host === 'localhost' || host.endsWith('.localhost')) return false
  if (host === '127.0.0.1' || host === '::1' || host.endsWith('.local')) return false
  // Literal IPs — do not proxy
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(host) || host.includes(':')) return false

  return ALLOWED_TARGET_HOST_SUFFIXES.some(
    (suffix) => host === suffix || host.endsWith(`.${suffix}`),
  )
}

function corsHeaders(request) {
  const caller = resolveCallerOrigin(request)
  const allowOrigin = isAllowedOrigin(caller) ? caller : null
  const requested = request.headers.get('Access-Control-Request-Headers')

  const headers = {
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    'Access-Control-Allow-Headers': requested || '*',
    'Access-Control-Max-Age': '86400',
    'Cross-Origin-Resource-Policy': 'cross-origin',
    Vary: 'Origin',
  }

  // Never use *. Only echo an allowlisted origin so other sites cannot read responses.
  if (allowOrigin) {
    headers['Access-Control-Allow-Origin'] = allowOrigin
  }

  return headers
}

function stripUnsafeHeaders(headers) {
  for (const name of HEADERS_TO_STRIP) {
    headers.delete(name)
  }
  for (const name of [...headers.keys()]) {
    if (name.toLowerCase().startsWith('access-control-')) {
      headers.delete(name)
    }
  }
}

function forbid(request, message, status = 403) {
  return new Response(message, {
    status,
    headers: {
      'Content-Type': 'text/plain',
      ...corsHeaders(request),
    },
  })
}

async function handleRequest(request) {
  if (request.method === 'OPTIONS') {
    const caller = resolveCallerOrigin(request)
    if (caller && !isAllowedOrigin(caller)) {
      return forbid(request, 'Origin not allowed')
    }
    return new Response(null, { status: 204, headers: corsHeaders(request) })
  }

  if (request.method !== 'GET' && request.method !== 'HEAD') {
    return new Response('Method not allowed', {
      status: 405,
      headers: { 'Content-Type': 'text/plain', ...corsHeaders(request) },
    })
  }

  if (!isBrowserCallerAllowed(request)) {
    return forbid(request, 'Origin not allowed')
  }

  const url = new URL(request.url)
  const targetUrl = url.searchParams.get('url')

  if (!targetUrl) {
    return new Response(
      'Missing url parameter. Usage: ?url=https://drive.google.com/...',
      {
        status: 400,
        headers: { 'Content-Type': 'text/plain', ...corsHeaders(request) },
      },
    )
  }

  if (!isAllowedTargetUrl(targetUrl)) {
    return forbid(
      request,
      'Target host not allowed. Only Google Drive / googleusercontent HTTPS URLs are proxied.',
    )
  }

  try {
    const response = await fetch(targetUrl, {
      method: 'GET',
      redirect: 'follow',
      headers: {
        'User-Agent': 'CTRIM-Image-Proxy/1.0',
      },
    })

    // After redirects, ensure we did not land on a disallowed host
    if (response.url && !isAllowedTargetUrl(response.url)) {
      return forbid(request, 'Redirect target host not allowed')
    }

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
