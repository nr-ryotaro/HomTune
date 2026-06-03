import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/utils/category_mapper.dart';

void main() {
  group('CategoryMapper', () {
    test('maps English device categories to JSON keys', () {
      expect(CategoryMapper.normalize('TV'), 'テレビ');
      expect(CategoryMapper.normalize('Speaker'), 'オーディオ');
      expect(CategoryMapper.normalize('Humidifier'), '加湿器');
      expect(CategoryMapper.normalize('Refrigerator'), '冷蔵庫');
    });

    test('returns original key when already Japanese', () {
      expect(CategoryMapper.normalize('エアコン'), 'エアコン');
    });

    test('maps furniture and lighting to その他', () {
      expect(CategoryMapper.normalize('Furniture'), 'その他');
      expect(CategoryMapper.normalize('Lighting'), 'その他');
      expect(CategoryMapper.normalize('Rice Cooker'), '炊飯器');
      expect(CategoryMapper.normalize('Oven'), 'コンロ');
    });
  });
}
