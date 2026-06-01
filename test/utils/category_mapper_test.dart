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

    test('returns unknown category unchanged', () {
      expect(CategoryMapper.normalize('Furniture'), 'Furniture');
    });
  });
}
