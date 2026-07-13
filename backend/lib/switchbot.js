const crypto = require('crypto');

const SB_BASE = 'https://api.switch-bot.com';

function signHeaders(token, secret) {
  const t = Date.now().toString();
  const nonce = crypto.randomUUID();
  const data = token + t + nonce;
  const sign = crypto.createHmac('sha256', secret).update(data).digest('base64');
  return {
    Authorization: token,
    sign,
    t,
    nonce,
    'Content-Type': 'application/json',
  };
}

async function sbFetch(token, secret, path, options = {}) {
  const headers = {
    ...signHeaders(token, secret),
    ...(options.headers ?? {}),
  };
  const res = await fetch(`${SB_BASE}${path}`, { ...options, headers });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body.statusCode && body.statusCode !== 100) {
    const err = new Error(body.message || `SwitchBot API ${res.status}`);
    err.status = res.status;
    err.body = body;
    throw err;
  }
  return body;
}

function mapDevice(item, infrared = false) {
  const type = (item.deviceType ?? item.remoteType ?? 'IR').toLowerCase();
  let profile = 'genericIr';
  if (type.includes('air') || type.includes('ac')) profile = 'aircon';
  else if (type.includes('tv')) profile = 'tv';
  else if (type.includes('light')) profile = 'light';
  else if (type.includes('curtain') || type.includes('blind')) profile = 'curtain';
  else if (type === 'bot') profile = 'bot';
  else if (type.includes('plug')) profile = 'plug';

  return {
    id: item.deviceId,
    provider: 'switchbot',
    nickname: item.deviceName ?? item.remoteName ?? 'Device',
    type: item.deviceType ?? item.remoteType ?? 'IR',
    hubDeviceId: item.hubDeviceId ?? null,
    profile,
    signals: [],
    infrared,
  };
}

async function listAppliances(token, secret) {
  const data = await sbFetch(token, secret, '/v1.1/devices');
  const body = data.body ?? {};
  const physical = (body.deviceList ?? []).map((d) => mapDevice(d, false));
  const ir = (body.infraredRemoteList ?? []).map((d) => mapDevice(d, true));
  return [...physical, ...ir];
}

async function sendCommand(token, secret, deviceId, command, parameter = 'default', commandType = 'command') {
  return sbFetch(token, secret, `/v1.1/devices/${deviceId}/commands`, {
    method: 'POST',
    body: JSON.stringify({
      command,
      parameter,
      commandType,
    }),
  });
}

module.exports = {
  listAppliances,
  sendCommand,
};
