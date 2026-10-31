import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart' show TimeOfDay;

class CreatedEvent {
  final String eventId;
  final String calendarId;
  const CreatedEvent(this.eventId, this.calendarId);
}

class CalendarProviderInfo {
  final String id;
  final String displayName;
  final String accountName;
  const CalendarProviderInfo({
    required this.id,
    required this.displayName,
    required this.accountName,
  });
}

class CalendarService {
  CalendarService._();
  static final CalendarService _instance = CalendarService._();
  factory CalendarService() => _instance;

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  bool _tzInitialized = false;

  void _ensureTz() {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  DateTime? parseEntryExpiry(String? ablaufStr) {
    if (ablaufStr == null || ablaufStr.isEmpty) return null;
    final parts = ablaufStr.split('.');
    if (parts.length != 3) return null;
    try {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _ensurePermission() async {
    try {
      final has = await _plugin.hasPermissions();
      if (has.data == true) return true;
      final req = await _plugin.requestPermissions();
      return req.data == true;
    } catch (e) {
      debugPrint('Calendar permission error: $e');
      return false;
    }
  }

  Future<List<CalendarProviderInfo>> getAvailableProviders() async {
    final providers = <CalendarProviderInfo>[];
    try {
      if (!await _ensurePermission()) return providers;
      final result = await _plugin.retrieveCalendars();
      final calendars =
          (result.data ?? []).where((c) => c.isReadOnly != true).toList();

      final seen = <String>{};
      for (final cal in calendars) {
        final id = _detectProviderId(cal);
        if (id == null || seen.contains(id)) continue;
        seen.add(id);
        providers.add(CalendarProviderInfo(
          id: id,
          displayName: _displayName(id),
          accountName: cal.accountName ?? '',
        ));
      }

      final hasSpecific = providers.any((p) => p.id != 'system');
      if (hasSpecific) {
        providers.removeWhere((p) => p.id == 'system');
      } else if (providers.isEmpty && calendars.isNotEmpty) {
        // Nur lokale Kalender – prüfen ob einer "samsung" im Namen hat
        final firstCal = calendars.first;
        final firstCalName = (firstCal.name ?? '').toLowerCase();
        final firstAccName = (firstCal.accountName ?? '').toLowerCase();
        final isSamsungLocal = firstCalName.contains('samsung') ||
            firstCalName.contains('galaxy') ||
            firstAccName.contains('samsung') ||
            firstAccName.contains('galaxy');

        providers.add(CalendarProviderInfo(
          id: isSamsungLocal ? 'samsung' : 'system',
          displayName: _displayName(isSamsungLocal ? 'samsung' : 'system'),
          accountName: firstCal.accountName ?? 'Local',
        ));
      }
    } catch (e) {
      debugPrint('getAvailableProviders error: $e');
    }
    return providers;
  }

  String? _detectProviderId(Calendar cal) {
    final type = (cal.accountType ?? '').toLowerCase();
    final accountName = (cal.accountName ?? '').toLowerCase();
    final calName = (cal.name ?? '').toLowerCase();
    final combo = '$type|$accountName|$calName';

    // ── Google ──────────────────────────────────────────────
    if (combo.contains('google') ||
        combo.contains('gmail') ||
        combo.contains('com.google')) {
      return 'google';
    }

    // ── Samsung (breite Erkennung über type, accountName, calName) ──
    if (combo.contains('samsung') ||
        combo.contains('galaxy') ||
        combo.contains('com.samsung') ||
        combo.contains('com.sec') ||
        combo.contains('sec.android') ||
        combo.contains('vnd.sec')) {
      return 'samsung';
    }

    // ── Outlook ────────────────────────────────────────────
    if (combo.contains('outlook') ||
        combo.contains('microsoft') ||
        combo.contains('exchange') ||
        combo.contains('office365') ||
        combo.contains('eas')) {
      return 'outlook';
    }

    // ── System / Lokal ────────────────────────────────────
    if (combo.contains('local') ||
        combo.contains('phone') ||
        combo.contains('aosp') ||
        combo.contains('sim')) {
      // Samsung Kalender heißt lokal typischerweise "My Calendar" / "Mein Kalender"
      if (calName.contains('my calendar') ||
          calName.contains('mein kalender') ||
          calName.contains('samsung') ||
          calName.contains('galaxy')) {
        return 'samsung';
      }
      return 'system';
    }

    return null;
  }

  String _displayName(String id) {
    switch (id) {
      case 'google':
        return 'Google Calendar';
      case 'samsung':
        return 'Samsung Calendar';
      case 'outlook':
        return 'Outlook Calendar';
      case 'system':
        return 'System Calendar';
      default:
        return id;
    }
  }

  // Robuster: Bei system/samsung auch lokale Kalender als Fallback durchsuchen
  Future<Calendar?> _findCalendar(String providerId) async {
    try {
      if (!await _ensurePermission()) return null;
      final result = await _plugin.retrieveCalendars();
      final calendars =
          (result.data ?? []).where((c) => c.isReadOnly != true).toList();

      // Erste Runde: exakter Match
      for (final cal in calendars) {
        if (_detectProviderId(cal) == providerId) return cal;
      }

      // Fallback: system und samsung sind beide "lokal" – wenn einer von
      // beiden gesucht wird und der andere gefunden wurde, nehmen wir den
      if (providerId == 'system' || providerId == 'samsung') {
        for (final cal in calendars) {
          final type = (cal.accountType ?? '').toLowerCase();
          if (type == 'local' ||
              type.contains('phone') ||
              type.contains('aosp') ||
              type.contains('sim') ||
              type.contains('vnd.sec') ||
              type.contains('com.samsung')) {
            return cal;
          }
        }
      }

      if (providerId == 'system' && calendars.isNotEmpty) {
        return calendars.first;
      }
    } catch (e) {
      debugPrint('_findCalendar error: $e');
    }
    return null;
  }

  Future<CreatedEvent?> addEvent({
    required String title,
    required String description,
    required DateTime expiryDate,
    TimeOfDay? startTime,
    required String providerId,
    int reminderMinutes = 60,
  }) async {
    _ensureTz();
    try {
      final calendar = await _findCalendar(providerId);
      if (calendar?.id == null) return null;

      final int hour = startTime?.hour ?? 9;
      final int minute = startTime?.minute ?? 0;
      final start = DateTime(
          expiryDate.year, expiryDate.month, expiryDate.day, hour, minute);
      final end = start.add(const Duration(minutes: 30));

      final event = Event(
        calendar!.id!,
        title: title,
        description: description,
        start: tz.TZDateTime.from(start, tz.local),
        end: tz.TZDateTime.from(end, tz.local),
        reminders: [Reminder(minutes: reminderMinutes)],
        allDay: startTime == null,
      );

      final res = await _plugin.createOrUpdateEvent(event);
      if (res?.isSuccess == true && res?.data != null) {
        return CreatedEvent(res!.data!, calendar.id!);
      }
    } catch (e) {
      debugPrint('addEvent error: $e');
    }
    return null;
  }

  Future<CreatedEvent?> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime expiryDate,
    TimeOfDay? startTime,
    String? calendarId,
    String? providerId,
    int reminderMinutes = 60,
  }) async {
    _ensureTz();
    try {
      if (!await _ensurePermission()) return null;

      final result = await _plugin.retrieveCalendars();
      final List<Calendar> allCals = (result.data ?? <Calendar>[])
          .where((Calendar c) => c.isReadOnly != true && c.id != null)
          .toList();

      final List<Calendar> ordered = <Calendar>[];
      if (calendarId != null && calendarId.isNotEmpty) {
        ordered.addAll(allCals.where((Calendar c) => c.id == calendarId));
      }
      ordered.addAll(
          allCals.where((Calendar c) => _detectProviderId(c) == providerId));
      ordered.addAll(allCals.where((Calendar c) =>
          !ordered.any((Calendar o) => o.id == c.id)));

      final int hour = startTime?.hour ?? 9;
      final int minute = startTime?.minute ?? 0;
      final start = DateTime(
          expiryDate.year, expiryDate.month, expiryDate.day, hour, minute);
      final end = start.add(const Duration(minutes: 30));

      for (final Calendar cal in ordered) {
        if (cal.id == null) continue;

        bool exists = false;
        try {
          final check = await _plugin.retrieveEvents(
            cal.id!,
            RetrieveEventsParams(eventIds: [eventId]),
          );
          exists = check.data?.isNotEmpty == true;
        } catch (e) {
          debugPrint('updateEvent: retrieveEvents fehlgeschlagen für '
              'cal=${cal.id}: $e');
          exists = (calendarId == cal.id);
        }

        if (!exists) continue;

        final event = Event(
          cal.id!,
          eventId: eventId,
          title: title,
          description: description,
          start: tz.TZDateTime.from(start, tz.local),
          end: tz.TZDateTime.from(end, tz.local),
          reminders: [Reminder(minutes: reminderMinutes)],
          allDay: startTime == null,
        );

        final res = await _plugin.createOrUpdateEvent(event);
        if (res?.isSuccess == true && res?.data != null) {
          return CreatedEvent(res!.data!, cal.id!);
        }
      }
    } catch (e) {
      debugPrint('updateEvent error: $e');
    }
    return null;
  }

  Future<bool> deleteEvent({
    required String eventId,
    required String providerId,
  }) async {
    try {
      final calendar = await _findCalendar(providerId);
      if (calendar?.id == null) return false;
      final res = await _plugin.deleteEvent(calendar!.id!, eventId);
      return res.isSuccess == true;
    } catch (e) {
      debugPrint('deleteEvent error: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────
  //  ICS-Methoden (unverändert)
  // ────────────────────────────────────────────────────────────
  String buildIcsContent({
    required String title,
    required String description,
    required DateTime expiryDate,
    required int reminderMinutes,
    String? uid,
  }) {
    final uidVal = (uid == null || uid.isEmpty)
        ? '${DateTime.now().millisecondsSinceEpoch}@garantiemanager'
        : uid;
    final start =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day, 9, 0);
    final end = start.add(const Duration(minutes: 30));

    return 'BEGIN:VCALENDAR\r\n'
        'VERSION:2.0\r\n'
        'PRODID:-//CarlitoTech//Warranty Manager//EN\r\n'
        'CALSCALE:GREGORIAN\r\n'
        'METHOD:PUBLISH\r\n'
        'BEGIN:VEVENT\r\n'
        'UID:$uidVal\r\n'
        'DTSTAMP:${_icsDate(DateTime.now().toUtc())}\r\n'
        'DTSTART:${_icsDate(start)}\r\n'
        'DTEND:${_icsDate(end)}\r\n'
        'SUMMARY:${_escapeIcs(title)}\r\n'
        'DESCRIPTION:${_escapeIcs(description)}\r\n'
        'BEGIN:VALARM\r\n'
        'TRIGGER:-PT${reminderMinutes}M\r\n'
        'ACTION:DISPLAY\r\n'
        'DESCRIPTION:${_escapeIcs(title)}\r\n'
        'END:VALARM\r\n'
        'END:VEVENT\r\n'
        'END:VCALENDAR\r\n';
  }

  String buildIcsForEntries({
    required List<Map<String, String>> entries,
    required int reminderMinutes,
  }) {
    final buffer = StringBuffer();
    buffer.write('BEGIN:VCALENDAR\r\n');
    buffer.write('VERSION:2.0\r\n');
    buffer.write('PRODID:-//CarlitoTech//Warranty Manager//EN\r\n');
    buffer.write('CALSCALE:GREGORIAN\r\n');
    buffer.write('METHOD:PUBLISH\r\n');

    for (final entry in entries) {
      final name = (entry['name'] ?? 'Unbekannt').trim();
      if (name.isEmpty) continue;
      final expiry = parseEntryExpiry(entry['ablaufDatum']);
      if (expiry == null) continue;

      final start = DateTime(expiry.year, expiry.month, expiry.day, 9, 0);
      final end = start.add(const Duration(minutes: 30));
      final uidBase = '${name.hashCode}-${entry['ablaufDatum'] ?? ''}'
          .replaceAll(' ', '')
          .replaceAll('.', '');

      final descParts = <String>[];
      descParts.add('Garantie läuft ab am ${entry['ablaufDatum']}');
      if ((entry['woGekauft'] ?? '').isNotEmpty &&
          entry['woGekauft'] != 'Unbekannt') {
        descParts.add('Gekauft bei: ${entry['woGekauft']}');
      }
      if ((entry['bemerkung'] ?? '').trim().isNotEmpty) {
        descParts.add('Bemerkung: ${entry['bemerkung']}');
      }

      buffer.write('BEGIN:VEVENT\r\n');
      buffer.write('UID:$uidBase@garantiemanager\r\n');
      buffer.write('DTSTAMP:${_icsDate(DateTime.now().toUtc())}\r\n');
      buffer.write('DTSTART:${_icsDate(start)}\r\n');
      buffer.write('DTEND:${_icsDate(end)}\r\n');
      buffer.write('SUMMARY:${_escapeIcs('Garantie: $name')}\r\n');
      buffer.write('DESCRIPTION:${_escapeIcs(descParts.join('\\n'))}\r\n');
      buffer.write('BEGIN:VALARM\r\n');
      buffer.write('TRIGGER:-PT${reminderMinutes}M\r\n');
      buffer.write('ACTION:DISPLAY\r\n');
      buffer.write('DESCRIPTION:${_escapeIcs('Garantie: $name')}\r\n');
      buffer.write('END:VALARM\r\n');
      buffer.write('END:VEVENT\r\n');
    }

    buffer.write('END:VCALENDAR\r\n');
    return buffer.toString();
  }

  String _escapeIcs(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '');

  String _icsDate(DateTime dt) {
    final u = dt.toUtc();
    return '${u.year.toString().padLeft(4, '0')}'
        '${u.month.toString().padLeft(2, '0')}'
        '${u.day.toString().padLeft(2, '0')}'
        'T'
        '${u.hour.toString().padLeft(2, '0')}'
        '${u.minute.toString().padLeft(2, '0')}'
        '${u.second.toString().padLeft(2, '0')}Z';
  }

  Future<void> shareIcsFile({
    required String icsContent,
    required String fileName,
    String? subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(icsContent);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/calendar')],
        subject: subject ?? fileName,
      ),
    );
  }

  // Robuster Test: probiert ALLE beschreibbaren Kalender durch
  Future<bool> testProvider(String providerId) async {
    _ensureTz();
    try {
      if (!await _ensurePermission()) {
        debugPrint('testProvider: keine Berechtigung');
        return false;
      }

      final result = await _plugin.retrieveCalendars();
      final calendars = (result.data ?? [])
          .where((c) => c.isReadOnly != true && c.id != null)
          .toList();

      if (calendars.isEmpty) {
        debugPrint('testProvider: keine beschreibbaren Kalender');
        return false;
      }

      // Erst passende, dann alle anderen probieren
      final matching = calendars
          .where((c) => _detectProviderId(c) == providerId)
          .toList();
      final others = calendars
          .where((c) => _detectProviderId(c) != providerId)
          .toList();
      final ordered = [...matching, ...others];

      for (final cal in ordered) {
        if (cal.id == null) continue;
        try {
          final now = DateTime.now().add(const Duration(minutes: 5));
          final test = Event(
            cal.id!,
            title: 'Warranty Manager Test',
            description: 'Test-Eintrag – kann gelöscht werden.',
            start: tz.TZDateTime.from(now, tz.local),
            end:
                tz.TZDateTime.from(now.add(const Duration(minutes: 10)), tz.local),
          );

          final res = await _plugin.createOrUpdateEvent(test);
          debugPrint('testProvider: cal=${cal.id} (${cal.name}) → '
              'success=${res?.isSuccess}');

          if (res?.isSuccess == true && res?.data != null) {
            await _plugin.deleteEvent(cal.id!, res!.data!);
            return true;
          }
        } catch (e) {
          debugPrint('testProvider: Fehler bei cal=${cal.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('testProvider error: $e');
    }
    return false;
  }
}