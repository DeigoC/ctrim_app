/**
 * CORS Proxy Worker for CTRIM App
 * Deploy this to Cloudflare Workers to handle CORS for image requests
 *
 * Deployment Instructions:
 * 1. Go to https://workers.cloudflare.com/
 * 2. Open the existing worker (ctrim-image-proxy) or create a new one
 * 3. Click "Quick Edit" / Edit code and paste this file
 * 4. Click "Save and Deploy"
 * 5. If the worker URL changed, update:
 *    - lib/utility/network_image_helper.dart (ctrim_app)
 *    - lib/utility/image_url_helper.dart (ctrim_worship)
 *
 * Important: Google Drive responses include Cross-Origin-Resource-Policy:
 * same-site (and related COOP/COEP/CSP). If those are forwarded, browsers
 * block Image.network / fetch from localhost or your app origin with
 * ClientException: Load failed — even when the proxy returns 200 + image bytes.
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

async function handleRequest(request) {
  // Handle CORS preflight requests
  if (request.method === 'OPTIONS') {
    return handleOptions(request)
  }

  const url = new URL(request.url)
  const targetUrl = url.searchParams.get('url')

  // Validate target URL exists
  if (!targetUrl) {
    return new Response('Missing url parameter. Usage: ?url=https://example.com/image.jpg', {
      status: 400,
      headers: { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' },
    })
  }

  // Validate target URL format
  let targetUrlParsed
  try {
    targetUrlParsed = new URL(targetUrl)
  } catch (e) {
    return new Response('Invalid url parameter', {
      status: 400,
      headers: { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' },
    })
  }

  // Optional: Restrict to specific domains (uncomment to enable)
  // const allowedDomains = ['example.com', 'images.example.com']
  // if (!allowedDomains.some(domain => targetUrlParsed.hostname.endsWith(domain))) {
  //   return new Response('Domain not allowed', { status: 403 })
  // }

  try {
    const response = await fetch(targetUrl, {
      headers: {
        'User-Agent': 'CTRIM-Image-Proxy/1.0',
      },
    })

    const headers = new Headers(response.headers)
    for (const name of HEADERS_TO_STRIP) {
      headers.delete(name)
    }

    // Allow any app origin to read proxied media in the browser
    headers.set('Access-Control-Allow-Origin', '*')
    headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
    headers.set('Access-Control-Allow-Headers', 'Content-Type')
    headers.set('Cross-Origin-Resource-Policy', 'cross-origin')
    headers.set('Cache-Control', 'public, max-age=3600')

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    })
  } catch (error) {
    return new Response(`Failed to fetch resource: ${error.message}`, {
      status: 502,
      headers: {
        'Content-Type': 'text/plain',
        'Access-Control-Allow-Origin': '*',
        'Cross-Origin-Resource-Policy': 'cross-origin',
      },
    })
  }
}

function handleOptions(request) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
    'Cross-Origin-Resource-Policy': 'cross-origin',
  }

  return new Response(null, {
    status: 204,
    headers: headers,
  })
}
