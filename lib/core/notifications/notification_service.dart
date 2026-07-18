import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> showCampaignCompleted({
    required String campaignName,
    required int sent,
    required int failed,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Campanha concluída',
      '$campaignName — $sent enviados, $failed falhas',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'campaigns',
          'Campanhas',
          channelDescription: 'Notificações de campanhas de disparo',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showDispatchProgress({
    required String campaignName,
    required int current,
    required int total,
  }) async {
    await _plugin.show(
      1,
      'Disparando: $campaignName',
      '$current de $total mensagens enviadas',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'dispatch_progress',
          'Progresso de Disparo',
          channelDescription: 'Progresso em tempo real do disparo',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: total,
          progress: current,
          ongoing: true,
        ),
      ),
    );
  }
}
