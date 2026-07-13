const REMO_BASE = 'https://api.nature.global';

async function remoFetch(token, path, options = {}) {
  const res = await fetch(`${REMO_BASE}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
  });
  const text = await res.text();
  let body;
  try {
    body = text ? JSON.parse(text) : {};
  } catch {
    body = { raw: text };
  }
  if (!res.ok) {
    const err = new Error(body.message || `Remo API ${res.status}`);
    err.status = res.status;
    err.body = body;
    throw err;
  }
  return body;
}

function mapAppliance(item) {
  const type = item.type ?? item.model?.type ?? '';
  const model = item.model?.id ?? item.model ?? '';
  let profile = 'genericIr';
  const t = String(type).toUpperCase();
  if (t.includes('AC') || String(model).toUpperCase().includes('AC')) {
    profile = 'aircon';
  } else if (t.includes('TV')) {
    profile = 'tv';
  } else if (t.includes('LIGHT')) {
    profile = 'light';
  }

  const signals = (item.signals ?? []).map((s) => ({
    id: s.id,
    name: s.name,
    image: s.image,
  }));

  return {
    id: item.id,
    provider: 'remo',
    nickname: item.nickname ?? item.name ?? 'Appliance',
    type: String(type),
    model: String(model),
    profile,
    signals,
  };
}

async function listAppliances(token) {
  const data = await remoFetch(token, '/1/appliances');
  const list = Array.isArray(data) ? data : [];
  return list.map(mapAppliance);
}

async function sendSignal(token, signalId) {
  return remoFetch(token, `/1/signals/${signalId}/send`, { method: 'POST', body: '{}' });
}

async function sendAirconSettings(token, applianceId, settings) {
  return remoFetch(token, `/1/appliances/${applianceId}/aircon_settings`, {
    method: 'POST',
    body: JSON.stringify(settings),
  });
}

async function sendTvCommand(token, applianceId, button) {
  return remoFetch(token, `/1/appliances/${applianceId}/tv`, {
    method: 'POST',
    body: JSON.stringify({ button }),
  });
}

function findSignalByName(signals, names) {
  for (const name of names) {
    const hit = signals.find(
      (s) => s.name?.toLowerCase() === name.toLowerCase(),
    );
    if (hit) return hit.id;
  }
  return null;
}

module.exports = {
  listAppliances,
  sendSignal,
  sendAirconSettings,
  sendTvCommand,
  findSignalByName,
};
