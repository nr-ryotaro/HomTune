import 'package:flutter/material.dart';
import '../models/appliance_presentation.dart';
import '../services/appliance_template_service.dart';
import '../widgets/device_detail_content.dart';
import '../models/device.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  AppliancePresentation? _presentation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPresentation();
  }

  Future<void> _loadPresentation() async {
    final p = await ApplianceTemplateService.instance
        .resolvePresentation(widget.device);
    if (!mounted) return;
    setState(() {
      _presentation = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _presentation?.title ??
        (widget.device.category.isNotEmpty
            ? widget.device.category
            : widget.device.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFAFAF8),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DeviceDetailContent(
              device: widget.device,
              presentation: _presentation,
            ),
    );
  }
}
