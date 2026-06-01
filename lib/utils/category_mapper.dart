/// Maps app/device category labels to category-defaults.json keys (Japanese).
class CategoryMapper {
  static const Map<String, String> _toDefaultsKey = {
    'TV': 'テレビ',
    'Speaker': 'オーディオ',
    'Record Player': 'オーディオ',
    'Smart Speaker': 'オーディオ',
    'Humidifier': '加湿器',
    'Refrigerator': '冷蔵庫',
    'Oven': '電子レンジ',
    'Coffee Maker': '電子レンジ',
    'Rice Cooker': '電子レンジ',
    'Air Conditioner': 'エアコン',
    'AC': 'エアコン',
    'エアコン': 'エアコン',
    'PC': 'PC',
    'Computer': 'PC',
    'Vacuum': '掃除機',
    'Microwave': '電子レンジ',
    'Washer': '洗濯機',
    'Dishwasher': '食洗機',
    'Phone': 'スマートフォン',
    'Smartphone': 'スマートフォン',
    'Dehumidifier': '除湿機',
    'Air Purifier': '空気清浄機',
  };

  /// Returns the key used in category-defaults.json, or [category] if unknown.
  static String normalize(String category) {
    return _toDefaultsKey[category] ?? category;
  }
}
