import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/ai_routing_service.dart';
import '../services/ai_usage_service.dart';
import '../services/appliance_template_service.dart';
import '../services/chat_service.dart';
import '../services/config_service.dart';
import '../services/device_service.dart';
import '../services/manual_link_resolver.dart';
import '../services/notification_service.dart';

/// アプリ全体の Provider 一覧。
List<SingleChildWidget> buildAppProviders({
  required ConfigService configService,
  required NotificationService notificationService,
  required ManualLinkResolver manualLinkResolver,
}) {
  return [
    ChangeNotifierProvider<ConfigService>.value(value: configService),
    Provider<NotificationService>.value(value: notificationService),
    Provider<ApplianceTemplateService>.value(
      value: ApplianceTemplateService.instance,
    ),
    Provider<AiUsageService>.value(value: AiUsageService.instance),
    Provider<AiRoutingService>.value(value: AiRoutingService.instance),
    Provider<ManualLinkResolver>.value(value: manualLinkResolver),
    ProxyProvider<ConfigService, ChatService>(
      update: (_, config, previous) {
        previous?.dispose();
        return ChatService(config);
      },
      dispose: (_, service) => service.dispose(),
    ),
    ChangeNotifierProvider<DeviceService>(
      create: (ctx) => DeviceService(
        notificationService: ctx.read<NotificationService>(),
        manualLinkResolver: ctx.read<ManualLinkResolver>(),
        applianceTemplateService: ctx.read<ApplianceTemplateService>(),
      ),
    ),
  ];
}
