const { test } = require('node:test');
const assert = require('node:assert/strict');

const aiQuota = require('../lib/ai_quota');
const aiGenerate = require('../lib/ai_generate');

test('validateRequest rejects empty contents', () => {
  const result = aiGenerate.validateRequest({
    feature: 'chat',
    contents: [],
  });
  assert.equal(result.ok, false);
});

test('validateRequest accepts chat payload', () => {
  const result = aiGenerate.validateRequest({
    feature: 'chat',
    contents: [{ role: 'user', text: 'hello' }],
    requestedCredits: 2,
  });
  assert.equal(result.ok, true);
  assert.equal(result.value.feature, 'chat');
});

test('quota blocks free marketValuation', () => {
  aiQuota.resetForTest();
  const result = aiQuota.tryConsume('u1', false, 'marketValuation');
  assert.equal(result.ok, false);
  assert.equal(result.code, 'forbidden_feature');
});

test('quota consumes chat credits and refunds', () => {
  aiQuota.resetForTest();
  const first = aiQuota.tryConsume('u2', false, 'chat', 2);
  assert.equal(first.ok, true);
  assert.equal(first.creditsCharged, 2);
  assert.equal(first.remainingCredits, 38);
  aiQuota.refund('u2', 2);
  assert.equal(aiQuota.remaining('u2', false), 40);
});

test('quota exceeds free monthly limit', () => {
  aiQuota.resetForTest();
  for (let i = 0; i < 20; i++) {
    const r = aiQuota.tryConsume('u3', false, 'chat', 2);
    assert.equal(r.ok, true);
  }
  const blocked = aiQuota.tryConsume('u3', false, 'chat', 2);
  assert.equal(blocked.ok, false);
  assert.equal(blocked.code, 'quota_exceeded');
});

test('generate returns mock text without API key', async () => {
  const prevMock = process.env.HOMTUNE_AI_MOCK;
  const prevKey = process.env.GEMINI_API_KEY;
  process.env.HOMTUNE_AI_MOCK = 'true';
  delete process.env.GEMINI_API_KEY;
  try {
    const result = await aiGenerate.generate({
      feature: 'connectionTest',
      contents: [{ role: 'user', text: 'ok' }],
    });
    assert.equal(result.mocked, true);
    assert.equal(result.text, 'ok');
  } finally {
    if (prevMock == null) delete process.env.HOMTUNE_AI_MOCK;
    else process.env.HOMTUNE_AI_MOCK = prevMock;
    if (prevKey == null) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = prevKey;
  }
});
