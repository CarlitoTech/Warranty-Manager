import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'settings_provider.dart';
import 'notification_template_helper.dart';

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
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: titel,
        body: text,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'garantie_channel_v2',
            'Garantie Erinnerungen',
            channelDescription:
                'Benachrichtigungen für ablaufende Garantien',
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      //
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// Lädt die Benutzer-Vorlage aus den SharedPreferences (leer = Legacy-Format).
  Future<List<Map<String, String>>> _loadTemplate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('notif_template');
      if (raw == null || raw.isEmpty) return <Map<String, String>>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, String>>[];
      return decoded
          .whereType<Map>()
          .map((m) => m.map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
          .toList();
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String produktName,
    required String ablaufDatumStr,
    required DateTime benachrichtigungsDatum,
    required String langCode,
    /// Optional: kompletter Geräte-Datensatz, damit alle Bausteine
    /// (Kaufdatum, Preis, Händler, Dauer) gefüllt werden können.
    Map<String, String>? gerat,
  }) async {
    try {
      if (!benachrichtigungsDatum.isAfter(DateTime.now())) return;

      final prefs = await SharedPreferences.getInstance();
      final currencySymbol = prefs.getString('currency_symbol') ?? '€';
      final template = await _loadTemplate();

      final String titel =
          '${getText(langCode, 'notif_title')}$produktName';

      final String text = NotificationTemplateHelper.buildBody(
        langCode: langCode,
        template: template,
        produktName: produktName,
        ablaufDatumStr: ablaufDatumStr,
        gerat: gerat,
        currencySymbol: currencySymbol,
        referenceDate: benachrichtigungsDatum,
      );

      await planErinnerung(
        id: id,
        titel: titel,
        text: text,
        datum: benachrichtigungsDatum,
      );
    } catch (e) {
      //
    }
  }
}