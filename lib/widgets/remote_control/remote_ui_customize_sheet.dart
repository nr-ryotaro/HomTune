import 'package:flutter/material.dart';

import '../../models/remote_ui_template.dart';
import '../../services/remote_control/remote_ui_preferences_service.dart';

/// ボタンの表示/非表示・ピン留めをカスタマイズ
class RemoteUiCustomizeSheet extends StatefulWidget {
  final String deviceId;
  final RemoteUiTemplate template;
  final RemoteUiUserPreferences initialPrefs;

  const RemoteUiCustomizeSheet({
    super.key,
    required this.deviceId,
    required this.template,
    required this.initialPrefs,
  });

  static Future<RemoteUiUserPreferences?> show(
    BuildContext context, {
    required String deviceId,
    required RemoteUiTemplate template,
    required RemoteUiUserPreferences initialPrefs,
  }) {
    return showModalBottomSheet<RemoteUiUserPreferences>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RemoteUiCustomizeSheet(
        deviceId: deviceId,
        template: template,
        initialPrefs: initialPrefs,
      ),
    );
  }

  @override
  State<RemoteUiCustomizeSheet> createState() => _RemoteUiCustomizeSheetState();
}

class _RemoteUiCustomizeSheetState extends State<RemoteUiCustomizeSheet> {
  late Set<String> _hidden;
  late List<String> _pinned;

  @override
  void initState() {
    super.initState();
    _hidden = Set<String>.from(widget.initialPrefs.hiddenButtonIds);
    _pinned = List<String>.from(widget.initialPrefs.pinnedButtonIds);
    if (_pinned.isEmpty) {
      _pinned = widget.template.allButtons
          .where((b) => b.pinByDefault)
          .map((b) => b.id)
          .toList();
    }
  }

  Future<void> _save() async {
    final prefs = RemoteUiUserPreferences(
      hiddenButtonIds: _hidden,
      pinnedButtonIds: _pinned,
    );
    await RemoteUiPreferencesService.instance.save(widget.deviceId, prefs);
    if (mounted) Navigator.of(context).pop(prefs);
  }

  void _toggleHidden(String id) {
    setState(() {
      if (_hidden.contains(id)) {
        _hidden.remove(id);
      } else {
        _hidden.add(id);
        _pinned.remove(id);
      }
    });
  }

  void _togglePinned(String id) {
    if (_hidden.contains(id)) return;
    setState(() {
      if (_pinned.contains(id)) {
        _pinned.remove(id);
      } else {
        _pinned.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttons = widget.template.allButtons;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'リモコンをカスタマイズ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              widget.template.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            const Text(
              '目のアイコンで表示切替、星で「よく使う」に追加できます。',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: buttons.length,
                itemBuilder: (context, index) {
                  final btn = buttons[index];
                  if (!btn.customizable) {
                    return ListTile(
                      dense: true,
                      leading: Icon(btn.icon, size: 20),
                      title: Text(btn.label, style: const TextStyle(fontSize: 14)),
                      subtitle: const Text('固定ボタン', style: TextStyle(fontSize: 11)),
                    );
                  }
                  final hidden = _hidden.contains(btn.id);
                  final pinned = _pinned.contains(btn.id);
                  return ListTile(
                    dense: true,
                    leading: Icon(btn.icon, size: 20),
                    title: Text(
                      btn.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: hidden ? const Color(0xFF94A3B8) : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            pinned ? Icons.star : Icons.star_border,
                            color: hidden
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFF59E0B),
                          ),
                          onPressed: hidden ? null : () => _togglePinned(btn.id),
                        ),
                        IconButton(
                          icon: Icon(
                            hidden ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => _toggleHidden(btn.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
