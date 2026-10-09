import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'settings_provider.dart'; 

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName =
          await FlutterTimezone.getLocalTimezone().then((info) => info.identifier);
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // KORREKTUR: settings ist jetzt ein benannter Parameter
    await _notificationsPlugin.initialize(settings: settings);

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'garantie_channel_v2',
        'Garantie Erinnerungen',
        description: 'Benachrichtigungen für ablaufende Garantien',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<void> planErinnerung({
    required int id,
    required String titel,
    required String text,
    required DateTime datum,
  }) async {
    final scheduledDate = tz.TZDateTime.from(datum, tz.local);

    try {
      // KORREKTUR: Parameter benannt und veraltetes uiLocalNotificationDateInterpretation entfernt
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: titel,
        body: text,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'garantie_channel_v2',
            'Garantie Erinnerungen',
            channelDescription: 'Benachrichtigungen für ablaufende Garantien',
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Buchen der Benachrichtigung: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    // KORREKTUR: id ist jetzt ein benannter Parameter
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> scheduleNotification({
    required int id,
    required String produktName,
    required String ablaufDatumStr,
    required DateTime benachrichtigungsDatum, 
    required String langCode, 
  }) async {
    try {
      if (benachrichtigungsDatum.isAfter(DateTime.now())) {
        final String titel = '${getText(langCode, 'notif_title')}$produktName';
        final String text = '${getText(langCode, 'notif_body')}$ablaufDatumStr${getText(langCode, 'notif_body_end')}';

        await planErinnerung(
          id: id,
          titel: titel,
          text: text,
          datum: benachrichtigungsDatum,
        );
      } else {
        debugPrint('⚠️ Benachrichtigung liegt in der Vergangenheit und wird ignoriert.');
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Planen der Benachrichtigung: $e');
    }
  }
}