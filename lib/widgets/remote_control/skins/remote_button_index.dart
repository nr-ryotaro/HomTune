import '../../../models/remote_ui_template.dart';

/// レイアウト内ボタンを ID で引くヘルパー
class RemoteButtonIndex {
  final Map<String, RemoteUiButtonDef> _byId;

  RemoteButtonIndex(RemoteUiResolvedLayout layout)
      : _byId = {
          for (final g in layout.groups)
            for (final b in g.buttons) b.id: b,
          for (final b in layout.pinnedButtons) b.id: b,
        };

  RemoteUiButtonDef? operator [](String id) => _byId[id];

  List<RemoteUiButtonDef> byIds(List<String> ids) =>
      ids.map((id) => _byId[id]).whereType<RemoteUiButtonDef>().toList();

  List<RemoteUiButtonDef> extras({required Set<String> excludeIds}) =>
      _byId.values.where((b) => !excludeIds.contains(b.id)).toList();
}
