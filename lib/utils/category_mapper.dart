/// Maps app/device category labels to category-defaults.json keys (Japanese).
class CategoryMapper {
  static const Map<String, String> _toDefaultsKey = {
    'TV': 'テレビ',
    'テレビ': 'テレビ',
    'Speaker': 'オーディオ',
    'Record Player': 'オーディオ',
    'Smart Speaker': 'オーディオ',
    'オーディオ': 'オーディオ',
    'Humidifier': '加湿器',
    '加湿器': '加湿器',
    'Refrigerator': '冷蔵庫',
    '冷蔵庫': '冷蔵庫',
    'Oven': 'コンロ',
    'コンロ': 'コンロ',
    'Coffee Maker': 'その他',
    'Rice Cooker': '炊飯器',
    '炊飯器': '炊飯器',
    'Furniture': 'その他',
    'Lighting': 'その他',
    'Air Conditioner': 'エアコン',
    'AC': 'エアコン',
    'エアコン': 'エアコン',
    'PC': 'PC',
    'Computer': 'PC',
    'Vacuum': '掃除機',
    '掃除機': '掃除機',
    'Microwave': '電子レンジ',
    '電子レンジ': '電子レンジ',
    'Washer': '洗濯機',
    'Dishwasher': '食洗機',
    '食洗機': '食洗機',
    'Phone': 'スマートフォン',
    'Smartphone': 'スマートフォン',
    'Dehumidifier': '除湿機',
    '除湿機': '除湿機',
    'Air Purifier': '空気清浄機',
    '空気清浄機': '空気清浄機',
    'その他': 'その他',
  };

  /// Returns the key used in category-defaults.json, or [category] if unknown.
  static String normalize(String category) {
    return _toDefaultsKey[category] ?? category;
  }
}
