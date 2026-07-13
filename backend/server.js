/**
 * HomTune API proxy — remote control (dev / MVP)
 * Run: cd backend && npm start
 */

const http = require('http');
const { URL } = require('url');
const store = require('./lib/store');
const remo = require('./lib/remo');
const switchbot = require('./lib/switchbot');

const PORT = process.env.PORT || 8787;

function json(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function getUserId(req) {
  return req.headers['x-homtune-user-id'] || 'dev-user';
}

function isPro(req) {
  return String(req.headers['x-homtune-pro'] ?? '').toLowerCase() === 'true';
}

function requirePro(req, res) {
  if (!isPro(req)) {
    json(res, 402, { success: false, message: 'Proプランが必要です' });
    return false;
  }
  return true;
}

function checkQuota(req, res) {
  const userId = getUserId(req);
  if (store.remainingQuota(userId) <= 0) {
    json(res, 429, {
      success: false,
      message: '今月のリモコン操作上限に達しました',
      remainingMonthlyQuota: 0,
    });
    return false;
  }
  return true;
}

async function executeCommand(userId, body) {
  const { provider, externalApplianceId, type, signalId, hubDeviceId, parameters } = body;

  if (provider === 'remo') {
    const token = store.remoTokens.get(userId);
    if (!token) throw Object.assign(new Error('Remo未連携'), { status: 401 });

    switch (type) {
      case 'sendSignal':
        if (!signalId) throw new Error('signalId required');
        await remo.sendSignal(token, signalId);
        break;
      case 'powerOn':
        await remo.sendAirconSettings(token, externalApplianceId, {
          operation_mode: 'cool',
          temperature: (parameters?.temperature ?? 26).toString(),
          air_volume: 'auto',
          air_direction: 'auto',
          button: 'power-on',
        });
        break;
      case 'powerOff':
        await remo.sendAirconSettings(token, externalApplianceId, {
          operation_mode: 'cool',
          temperature: '26',
          air_volume: 'auto',
          air_direction: 'auto',
          button: 'power-off',
        });
        break;
      case 'tempUp':
        await remo.sendAirconSettings(token, externalApplianceId, {
          operation_mode: parameters?.operation_mode ?? 'cool',
          temperature: 'up',
          air_volume: 'auto',
          air_direction: 'auto',
          button: '',
        });
        break;
      case 'tempDown':
        await remo.sendAirconSettings(token, externalApplianceId, {
          operation_mode: parameters?.operation_mode ?? 'cool',
          temperature: 'down',
          air_volume: 'auto',
          air_direction: 'auto',
          button: '',
        });
        break;
      case 'volumeUp':
        await remo.sendTvCommand(token, externalApplianceId, 'vol-up');
        break;
      case 'volumeDown':
        await remo.sendTvCommand(token, externalApplianceId, 'vol-down');
        break;
      case 'channelUp':
        await remo.sendTvCommand(token, externalApplianceId, 'ch-up');
        break;
      case 'channelDown':
        await remo.sendTvCommand(token, externalApplianceId, 'ch-down');
        break;
      case 'tvMute':
        await remo.sendTvCommand(token, externalApplianceId, 'vol-mute');
        break;
      case 'tvInput':
      case 'tvApp':
      case 'airconTimer':
      case 'airconSwing':
      case 'airconEco':
        if (!signalId) throw new Error('signalId required');
        await remo.sendSignal(token, signalId);
        break;
      case 'airconCool':
      case 'airconWarm':
      case 'airconDry':
      case 'airconFan':
      case 'airconAuto': {
        const modeMap = {
          airconCool: 'cool',
          airconWarm: 'warm',
          airconDry: 'dry',
          airconFan: 'blow',
          airconAuto: 'auto',
        };
        await remo.sendAirconSettings(token, externalApplianceId, {
          operation_mode: modeMap[type],
          temperature: (parameters?.temperature ?? 26).toString(),
          air_volume: parameters?.air_volume ?? 'auto',
          air_direction: parameters?.air_direction ?? 'auto',
          button: '',
        });
        break;
      }
      default:
        throw new Error(`Unknown command type: ${type}`);
    }
    return;
  }

  if (provider === 'switchbot') {
    const creds = store.switchbotCreds.get(userId);
    if (!creds) throw Object.assign(new Error('SwitchBot未連携'), { status: 401 });
    const deviceId = externalApplianceId;

    switch (type) {
      case 'botPress':
        await switchbot.sendCommand(creds.token, creds.secret, deviceId, 'press');
        break;
      case 'powerOn':
        await switchbot.sendCommand(creds.token, creds.secret, deviceId, 'turnOn');
        break;
      case 'powerOff':
        await switchbot.sendCommand(creds.token, creds.secret, deviceId, 'turnOff');
        break;
      case 'curtainOpen':
        await switchbot.sendCommand(creds.token, creds.secret, deviceId, 'turnOn');
        break;
      case 'curtainClose':
        await switchbot.sendCommand(creds.token, creds.secret, deviceId, 'turnOff');
        break;
      case 'sendSignal':
        await switchbot.sendCommand(
          creds.token,
          creds.secret,
          deviceId,
          parameters?.buttonName ?? signalId ?? 'power',
          'default',
          'customize',
        );
        break;
      case 'tempUp':
      case 'tempDown':
      case 'volumeUp':
      case 'volumeDown':
        await switchbot.sendCommand(
          creds.token,
          creds.secret,
          deviceId,
          type === 'tempUp' ? 'tempUp' : type === 'tempDown' ? 'tempDown' : type === 'volumeUp' ? 'volumeAdd' : 'volumeSub',
          'default',
          'command',
        );
        break;
      default:
        throw new Error(`Unknown command type: ${type}`);
    }
    return;
  }

  throw new Error(`Unknown provider: ${provider}`);
}

async function handle(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const path = url.pathname;
  const userId = getUserId(req);

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,X-HomTune-User-Id,X-HomTune-Pro');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  try {
    if (path === '/health' && req.method === 'GET') {
      return json(res, 200, { ok: true, service: 'homtune-api-proxy' });
    }

    if (path === '/v1/integrations/remo/link' && req.method === 'POST') {
      if (!requirePro(req, res)) return;
      const body = await readBody(req);
      if (!body.token?.trim()) {
        return json(res, 400, { success: false, message: 'token required' });
      }
      store.remoTokens.set(userId, body.token.trim());
      return json(res, 200, { success: true, linked: true });
    }

    if (path === '/v1/integrations/remo/link' && req.method === 'DELETE') {
      store.remoTokens.delete(userId);
      return json(res, 200, { success: true, linked: false });
    }

    if (path === '/v1/integrations/remo/status' && req.method === 'GET') {
      return json(res, 200, {
        linked: store.remoTokens.has(userId),
        provider: 'remo',
        remainingMonthlyQuota: store.remainingQuota(userId),
        monthlyLimit: store.PRO_MONTHLY_LIMIT,
      });
    }

    if (path === '/v1/integrations/remo/appliances' && req.method === 'GET') {
      if (!requirePro(req, res)) return;
      const token = store.remoTokens.get(userId);
      if (!token) return json(res, 401, { success: false, message: 'Remo未連携' });
      const appliances = await remo.listAppliances(token);
      return json(res, 200, { success: true, appliances });
    }

    if (path === '/v1/integrations/switchbot/link' && req.method === 'POST') {
      if (!requirePro(req, res)) return;
      const body = await readBody(req);
      if (!body.token?.trim() || !body.secret?.trim()) {
        return json(res, 400, { success: false, message: 'token and secret required' });
      }
      store.switchbotCreds.set(userId, {
        token: body.token.trim(),
        secret: body.secret.trim(),
      });
      return json(res, 200, { success: true, linked: true });
    }

    if (path === '/v1/integrations/switchbot/link' && req.method === 'DELETE') {
      store.switchbotCreds.delete(userId);
      return json(res, 200, { success: true, linked: false });
    }

    if (path === '/v1/integrations/switchbot/status' && req.method === 'GET') {
      return json(res, 200, {
        linked: store.switchbotCreds.has(userId),
        provider: 'switchbot',
        remainingMonthlyQuota: store.remainingQuota(userId),
        monthlyLimit: store.PRO_MONTHLY_LIMIT,
      });
    }

    if (path === '/v1/integrations/switchbot/appliances' && req.method === 'GET') {
      if (!requirePro(req, res)) return;
      const creds = store.switchbotCreds.get(userId);
      if (!creds) return json(res, 401, { success: false, message: 'SwitchBot未連携' });
      const appliances = await switchbot.listAppliances(creds.token, creds.secret);
      return json(res, 200, { success: true, appliances });
    }

    if (path === '/v1/remote/command' && req.method === 'POST') {
      if (!requirePro(req, res)) return;
      if (!checkQuota(req, res)) return;
      const body = await readBody(req);
      await executeCommand(userId, body);
      const used = store.incrementUsage(userId);
      return json(res, 200, {
        success: true,
        message: '操作を送信しました',
        remainingMonthlyQuota: store.PRO_MONTHLY_LIMIT - used,
      });
    }

    json(res, 404, { success: false, message: 'Not found' });
  } catch (e) {
    console.error(e);
    json(res, e.status || 500, {
      success: false,
      message: e.message || 'Internal error',
    });
  }
}

const server = http.createServer((req, res) => {
  handle(req, res).catch((e) => {
    console.error(e);
    json(res, 500, { success: false, message: 'Internal error' });
  });
});

server.listen(PORT, () => {
  console.log(`HomTune API proxy listening on http://localhost:${PORT}`);
});
