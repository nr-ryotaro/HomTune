import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/appliance_archetype.dart';
import 'package:homtune/services/appliance_template_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('living room has air conditioner archetype', () async {
    final list = await ApplianceTemplateService.instance
        .getArchetypesForRoom('living-room');
    expect(list.any((a) => a.id == 'living_ac'), isTrue);
  });

  test('buildTasksForArchetype includes electrical care item', () async {
    final tasks = await ApplianceTemplateService.instance
        .buildTasksForArchetype('living_ac', 'dev-test');
    expect(tasks.any((t) => t.taskId == 'living_ac_electrical'), isTrue);
    expect(tasks.any((t) => t.taskId == 'living_ac_seasonal'), isFalse);
  });

  test('getUnregisteredSuggestions filters registered category', () async {
    final unregistered = await ApplianceTemplateService.instance
        .getUnregisteredSuggestions(
      selected: [
        const SelectedArchetypeRef(
          archetypeId: 'living_ac',
          roomId: 'living-room',
        ),
      ],
      registeredCategories: ['エアコン'],
      registeredNames: [],
    );
    expect(unregistered, isEmpty);
  });
}
