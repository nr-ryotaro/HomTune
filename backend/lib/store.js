/**
 * In-memory store for dev. Replace with encrypted DB in production.
 */

const remoTokens = new Map();
const switchbotCreds = new Map();
const monthlyUsage = new Map();

const PRO_MONTHLY_LIMIT = 300;

function monthKey() {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

function usageKey(userId) {
  return `${userId}:${monthKey()}`;
}

function getUsage(userId) {
  return monthlyUsage.get(usageKey(userId)) ?? 0;
}

function incrementUsage(userId) {
  const key = usageKey(userId);
  const next = (monthlyUsage.get(key) ?? 0) + 1;
  monthlyUsage.set(key, next);
  return next;
}

function remainingQuota(userId) {
  return Math.max(0, PRO_MONTHLY_LIMIT - getUsage(userId));
}

module.exports = {
  PRO_MONTHLY_LIMIT,
  remoTokens,
  switchbotCreds,
  getUsage,
  incrementUsage,
  remainingQuota,
};
