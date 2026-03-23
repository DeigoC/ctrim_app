/**
 * CORS Proxy Worker for CTRIM App
 * Deploy this to Cloudflare Workers to handle CORS for image requests
 * 
 * Deployment Instructions:
 * 1. Go to https://workers.cloudflare.com/
 * 2. Sign up/login (free tier: 100,000 requests/day)
 * 3. Click "Create a Service"
 * 4. Name it: ctrim-image-proxy (or your preferred name)
 * 5. Click "Quick Edit" and paste this code
 * 6. Click "Save and Deploy"
 * 7. Copy your worker URL (e.g., https://ctrim-image-proxy.your-subdomain.workers.dev)
 * 8. Update lib/utility/network_image_helper.dart with your worker URL
 */

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

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
      headers: { 'Content-Type': 'text/plain' }
    })
  }

  // Validate target URL format
  let targetUrlParsed
  try {
    targetUrlParsed = new URL(targetUrl)
  } catch (e) {
    return new Response('Invalid url parameter', { 
      status: 400,
      headers: { 'Content-Type': 'text/plain' }
    })
  }

  // Optional: Restrict to specific domains (uncomment to enable)
  // const allowedDomains = ['example.com', 'images.example.com']
  // if (!allowedDomains.some(domain => targetUrlParsed.hostname.endsWith(domain))) {
  //   return new Response('Domain not allowed', { status: 403 })
  // }

  try {
    // Fetch the target resource
    const response = await fetch(targetUrl, {
      headers: {
        'User-Agent': 'CTRIM-Image-Proxy/1.0'
      }
    })

    // Create a new response with CORS headers
    const newResponse = new Response(response.body, response)
    
    // Set CORS headers
    newResponse.headers.set('Access-Control-Allow-Origin', '*')
    newResponse.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
    newResponse.headers.set('Access-Control-Allow-Headers', 'Content-Type')
    
    // Cache for 1 hour (adjust as needed)
    newResponse.headers.set('Cache-Control', 'public, max-age=3600')
    
    return newResponse
  } catch (error) {
    return new Response(`Failed to fetch resource: ${error.message}`, { 
      status: 502,
      headers: { 
        'Content-Type': 'text/plain',
        'Access-Control-Allow-Origin': '*'
      }
    })
  }
}

function handleOptions(request) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  }
  
  return new Response(null, {
    status: 204,
    headers: headers
  })
}
