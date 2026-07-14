/**
 * In-memory monthly AI credit quota (MVP).
 * Aligns with Flutter AiUsagePolicy defaults until Postgres/Redis exists.
 */

const FREE_MONTHLY_CREDITS = 40;
const PRO_MONTHLY_CREDITS = 120;

const FEATURE_CREDITS = {
  connectionTest: 0,
  chat: 2,
  scanner: 3,
  roomImage: 2,
  maintenance: 2,
  marketValuation: 2,
};

const CREDIT_COST_USD = {
  chat: 0.01,
  scanner: 0.02,
  roomImage: 0.012,
  maintenance: 0.015,
  marketValuation: 0.01,
  connectionTest: 0,
};

/** @type {Map<string, number>} */
const monthlyCreditsUsed = new Map();

function monthKey() {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

function usageKey(userId) {
  return `${userId}:${monthKey()}`;
}

function creditLimit(isPro) {
  return isPro ? PRO_MONTHLY_CREDITS : FREE_MONTHLY_CREDITS;
}

function getUsed(userId) {
  return monthlyCreditsUsed.get(usageKey(userId)) ?? 0;
}

function remaining(userId, isPro) {
  return Math.max(0, creditLimit(isPro) - getUsed(userId));
}

function resolveCredits(feature, requestedCredits) {
  if (feature === 'chat') {
    const raw =
      requestedCredits == null ? FEATURE_CREDITS.chat : Number(requestedCredits);
    if (!Number.isFinite(raw)) return FEATURE_CREDITS.chat;
    return Math.min(4, Math.max(1, Math.round(raw)));
  }
  return FEATURE_CREDITS[feature] ?? null;
}

function estimatedCostUsd(feature, creditsCharged) {
  const unit = CREDIT_COST_USD[feature] ?? 0.01;
  const base = FEATURE_CREDITS[feature] || 1;
  return Number(((unit * creditsCharged) / base).toFixed(4));
}

/**
 * @returns {{ ok: true, creditsCharged: number, remainingCredits: number, creditLimit: number, estimatedCostUsd: number } | { ok: false, code: string, message: string, remainingCredits: number, creditLimit: number }}
 */
function tryConsume(userId, isPro, feature, requestedCredits) {
  if (!(feature in FEATURE_CREDITS)) {
    return {
      ok: false,
      code: 'bad_request',
      message: `Unknown feature: ${feature}`,
      remainingCredits: remaining(userId, isPro),
      creditLimit: creditLimit(isPro),
    };
  }

  if (feature === 'marketValuation' && !isPro) {
    return {
      ok: false,
      code: 'forbidden_feature',
      message: 'AI相場推定は Pro プラン専用です',
      remainingCredits: remaining(userId, isPro),
      creditLimit: creditLimit(isPro),
    };
  }

  const creditsCharged = resolveCredits(feature, requestedCredits);
  if (creditsCharged == null) {
    return {
      ok: false,
      code: 'bad_request',
      message: `Unknown feature: ${feature}`,
      remainingCredits: remaining(userId, isPro),
      creditLimit: creditLimit(isPro),
    };
  }

  const limit = creditLimit(isPro);
  const used = getUsed(userId);
  if (used + creditsCharged > limit) {
    return {
      ok: false,
      code: 'quota_exceeded',
      message: '今月のAIクレジット上限に達しました',
      remainingCredits: Math.max(0, limit - used),
      creditLimit: limit,
    };
  }

  monthlyCreditsUsed.set(usageKey(userId), used + creditsCharged);
  return {
    ok: true,
    creditsCharged,
    remainingCredits: limit - used - creditsCharged,
    creditLimit: limit,
    estimatedCostUsd: estimatedCostUsd(feature, creditsCharged),
  };
}

function refund(userId, credits) {
  if (!credits || credits <= 0) return;
  const key = usageKey(userId);
  const used = monthlyCreditsUsed.get(key) ?? 0;
  monthlyCreditsUsed.set(key, Math.max(0, used - credits));
}

function resetForTest() {
  monthlyCreditsUsed.clear();
}

module.exports = {
  FREE_MONTHLY_CREDITS,
  PRO_MONTHLY_CREDITS,
  FEATURE_CREDITS,
  tryConsume,
  refund,
  remaining,
  creditLimit,
  resolveCredits,
  resetForTest,
};
