/// 資産市場価値の更新モード（L0〜L2）
enum MarketRefreshMode {
  /// L0: 端末内の帳簿・数式・カタログブレンド（全プラン無制限）
  local,

  /// L1: Pro 相場参照DB（月間クォータ、キャッシュ30日）
  proReference,

  /// L2: Pro Gemini 中古相場推定（AIクレジット消費）
  proAi,
}
