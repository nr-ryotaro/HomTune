/**
 * Gemini text generate via official REST API (no npm deps).
 * Mock mode: HOMTUNE_AI_MOCK=true or missing GEMINI_API_KEY.
 */

const DEFAULT_MODEL =
  process.env.HOMTUNE_DEFAULT_AI_MODEL || 'gemini-2.5-flash-lite';

const ALLOWED_FEATURES = new Set([
  'chat',
  'scanner',
  'roomImage',
  'maintenance',
  'marketValuation',
  'connectionTest',
]);

function isMockEnabled() {
  if (String(process.env.HOMTUNE_AI_MOCK || '').toLowerCase() === 'true') {
    return true;
  }
  return !String(process.env.GEMINI_API_KEY || '').trim();
}

function validateRequest(body) {
  if (!body || typeof body !== 'object') {
    return { ok: false, message: 'JSON body required' };
  }
  const feature = String(body.feature || '').trim();
  if (!ALLOWED_FEATURES.has(feature)) {
    return {
      ok: false,
      message: `feature must be one of: ${[...ALLOWED_FEATURES].join(', ')}`,
    };
  }

  const contents = Array.isArray(body.contents) ? body.contents : null;
  if (!contents || contents.length === 0) {
    return { ok: false, message: 'contents must be a non-empty array' };
  }
  for (const item of contents) {
    if (!item || typeof item !== 'object') {
      return { ok: false, message: 'contents entries must be objects' };
    }
    const role = String(item.role || 'user');
    if (role !== 'user' && role !== 'model') {
      return { ok: false, message: 'contents.role must be user|model' };
    }
    if (typeof item.text !== 'string' || !item.text.trim()) {
      return { ok: false, message: 'contents.text must be a non-empty string' };
    }
  }

  const responseFormat = String(body.responseFormat || 'text');
  if (responseFormat !== 'text' && responseFormat !== 'json') {
    return { ok: false, message: 'responseFormat must be text|json' };
  }

  const model =
    typeof body.model === 'string' && body.model.trim()
      ? body.model.trim()
      : DEFAULT_MODEL;

  return {
    ok: true,
    value: {
      feature,
      model,
      systemInstruction:
        typeof body.systemInstruction === 'string'
          ? body.systemInstruction
          : '',
      contents: contents.map((c) => ({
        role: String(c.role || 'user'),
        text: String(c.text),
      })),
      responseFormat,
      requestedCredits: body.requestedCredits,
      clientRequestId:
        typeof body.clientRequestId === 'string' ? body.clientRequestId : null,
    },
  };
}

function mockText(feature, responseFormat) {
  if (feature === 'connectionTest') return 'ok';
  if (responseFormat === 'json') {
    if (feature === 'marketValuation') {
      return JSON.stringify({ usedPriceYen: 50000 });
    }
    if (feature === 'scanner') {
      return JSON.stringify({
        manufacturer: 'MockBrand',
        modelNumber: 'MOCK-001',
        category: 'その他',
      });
    }
    if (feature === 'roomImage') {
      return JSON.stringify({
        palette: ['#F5F0E8', '#2F3E46', '#84A98C'],
        accent: '#84A98C',
        headline: 'Mock Room',
        motifs: ['window', 'plant'],
      });
    }
    return JSON.stringify({ ok: true });
  }
  return `[mock:${feature}] HomTune AI proxy is running in mock mode.`;
}

async function callGeminiRest({
  apiKey,
  model,
  systemInstruction,
  contents,
  fetchImpl,
}) {
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(
    model,
  )}:generateContent?key=${encodeURIComponent(apiKey)}`;

  const payload = {
    contents: contents.map((c) => ({
      role: c.role === 'model' ? 'model' : 'user',
      parts: [{ text: c.text }],
    })),
  };
  if (systemInstruction && systemInstruction.trim()) {
    payload.systemInstruction = {
      parts: [{ text: systemInstruction }],
    };
  }

  const res = await fetchImpl(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const raw = await res.text();
  let decoded;
  try {
    decoded = JSON.parse(raw);
  } catch {
    const err = new Error(`Gemini upstream returned non-JSON (${res.status})`);
    err.status = 502;
    err.code = 'upstream_error';
    throw err;
  }

  if (!res.ok) {
    const msg =
      decoded?.error?.message || `Gemini upstream error (${res.status})`;
    const err = new Error(msg);
    err.status = 502;
    err.code = 'upstream_error';
    throw err;
  }

  const parts = decoded?.candidates?.[0]?.content?.parts;
  const text = Array.isArray(parts)
    ? parts.map((p) => p?.text || '').join('')
    : '';
  if (!text.trim()) {
    const err = new Error('Gemini returned empty content');
    err.status = 502;
    err.code = 'upstream_error';
    throw err;
  }
  return text;
}

/**
 * @param {object} body
 * @param {{ fetchImpl?: typeof fetch }} [options]
 */
async function generate(body, options = {}) {
  const validated = validateRequest(body);
  if (!validated.ok) {
    const err = new Error(validated.message);
    err.status = 400;
    err.code = 'bad_request';
    throw err;
  }

  const req = validated.value;
  const apiKey = String(process.env.GEMINI_API_KEY || '').trim();
  const fetchImpl = options.fetchImpl || fetch;

  if (isMockEnabled()) {
    return {
      text: mockText(req.feature, req.responseFormat),
      modelId: req.model,
      feature: req.feature,
      mocked: true,
    };
  }

  if (!apiKey) {
    const err = new Error('GEMINI_API_KEY is not configured on the server');
    err.status = 503;
    err.code = 'upstream_unconfigured';
    throw err;
  }

  const text = await callGeminiRest({
    apiKey,
    model: req.model,
    systemInstruction: req.systemInstruction,
    contents: req.contents,
    fetchImpl,
  });
  return {
    text,
    modelId: req.model,
    feature: req.feature,
    mocked: false,
  };
}

module.exports = {
  DEFAULT_MODEL,
  ALLOWED_FEATURES,
  validateRequest,
  isMockEnabled,
  generate,
  mockText,
  callGeminiRest,
};
