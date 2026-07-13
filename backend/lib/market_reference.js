const fs = require('fs');
const path = require('path');

let catalog = null;

function loadCatalog() {
  if (catalog) return catalog;
  const jsonPath = path.join(
    __dirname,
    '../../assets/data/market-reference-prices.json',
  );
  const raw = fs.readFileSync(jsonPath, 'utf8');
  catalog = JSON.parse(raw);
  return catalog;
}

function normalizeKey(value) {
  return String(value ?? '')
    .trim()
    .toUpperCase()
    .replace(/\s+/g, '');
}

/**
 * L1 相場参照（サーバー配信 — アプリ同梱 JSON と同一ソース）
 * 原価 $0、Pro 月次クォータはクライアント側で管理
 */
function lookup(manufacturer, modelNumber) {
  const data = loadCatalog();
  const mfg = normalizeKey(manufacturer);
  const model = normalizeKey(modelNumber);
  const entry = (data.entries || []).find(
    (e) =>
      normalizeKey(e.manufacturer) === mfg &&
      normalizeKey(e.modelNumber) === model,
  );
  if (!entry) return null;
  return {
    manufacturer: entry.manufacturer,
    modelNumber: entry.modelNumber,
    referenceMarketYen: entry.referenceMarketYen,
    referenceAsOf: entry.referenceAsOf,
    monthlyDecayRateDefault: data.monthlyDecayRateDefault ?? 0.012,
  };
}

function catalogMeta() {
  const data = loadCatalog();
  return {
    entryCount: (data.entries || []).length,
    monthlyDecayRateDefault: data.monthlyDecayRateDefault ?? 0.012,
    source: 'bundled-json',
    updatedAt: data.updatedAt ?? null,
  };
}

module.exports = { lookup, catalogMeta, loadCatalog };
