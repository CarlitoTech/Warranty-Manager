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

/// Ergebnis von [CalendarService.testProvider]. Enthält zusätzlich zum
/// reinen Erfolg/Misserfolg eine für den Nutzer lesbare Diagnose, damit man
/// NICHT mehr auf logcat angewiesen ist, um zu sehen, woran ein Schreibtest
/// auf einem bestimmten Gerät (z.B. One UI 9) tatsächlich scheitert.
class CalendarTestResult {
  final bool success;
  final String details;
  const CalendarTestResult(this.success, this.details);
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
      if (req.data == true) return true;

      // Manche One UI 9 Geräte melden nach dem Systemdialog kurzzeitig noch
      // "false", obwohl der Nutzer die Berechtigung erteilt hat (der Content
      // Provider braucht einen Moment, bis er bereit ist). Wir prüfen daher
      // nochmal nach einer kurzen Pause, bevor wir endgültig "nein" sagen.
      await Future.delayed(const Duration(milliseconds: 300));
      final recheck = await _plugin.hasPermissions();
      return recheck.data == true;
    } catch (e) {
      debugPrint('Calendar permission error: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────
  //  retrieveCalendars mit Retry
  //  Auf Samsung One UI 9 (und vereinzelt anderen Android-15/16-Geräten)
  //  liefert der Calendar-ContentProvider direkt nach Berechtigungserteilung
  //  manchmal eine leere Liste zurück, obwohl Kalender vorhanden sind – der
  //  Provider ist dann noch nicht vollständig initialisiert. Wir versuchen
  //  es deshalb mehrfach mit kurzer Pause, bevor wir "keine Kalender"
  //  akzeptieren.
  // ────────────────────────────────────────────────────────────
  Future<List<Calendar>> _retrieveWritableCalendars() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final result = await _plugin.retrieveCalendars();
        final calendars = (result.data ?? <Calendar>[])
            .where((c) => c.isReadOnly != true)
            .toList();
        if (calendars.isNotEmpty) return calendars;
        debugPrint(
            'retrieveCalendars: Versuch $attempt lieferte keine Kalender');
      } catch (e) {
        debugPrint('retrieveCalendars: Fehler bei Versuch $attempt: $e');
      }
      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
    return const <Calendar>[];
  }

  // ────────────────────────────────────────────────────────────
  //  Provider-Erkennung – robust für One UI 9 / alle Android-Versionen
  //
  //  Samsung registriert Calendar auf verschiedenen Android-/One UI-Versionen
  //  sehr unterschiedlich:
  //    • accountType: "com.samsung.android.calendar", "com.sec.android.account",
  //                   "com.osp.app.signin", "vnd.sec.contact.phone", "LOCAL"
  //    • accountName: oft "Samsung Account", Telefon-Nr., E-Mail oder "Local"
  //    • calName:     "Mein Kalender", "My Calendar", "Samsung Calendar"
  //  => Wir prüfen ALLE Felder und nehmen auch den Package-Namen (accountType
  //     enthält bei neueren One UI das Package).
  // ────────────────────────────────────────────────────────────
  String? _detectProviderId(Calendar cal) {
    final type = (cal.accountType ?? '').toLowerCase().trim();
    final accountName = (cal.accountName ?? '').toLowerCase().trim();
    final calName = (cal.name ?? '').toLowerCase().trim();
    final combo = '$type|$accountName|$calName';

    // ── Google ──────────────────────────────────────────────────────────────
    if (type.contains('google') ||
        type.contains('gmail') ||
        type.contains('com.google') ||
        accountName.contains('@gmail.com') ||
        accountName.contains('@google') ||
        accountName.contains('google') ||
        calName.contains('google')) {
      return 'google';
    }

    // ── Outlook / Microsoft ──────────────────────────────────────────────────
    if (combo.contains('outlook') ||
        combo.contains('microsoft') ||
        combo.contains('office365') ||
        combo.contains('hotmail') ||
        combo.contains('live.com') ||
        combo.contains('exchange') ||
        type.contains('eas') ||
        accountName.endsWith('@hotmail.com') ||
        accountName.endsWith('@outlook.com') ||
        accountName.endsWith('@live.com')) {
      return 'outlook';
    }

    // ── Samsung ─────────────────────────────────────────────────────────────
    // One UI ≤ 6: accountType enthält "samsung", "com.sec", "vnd.sec", "com.samsung"
    // One UI 7+:  accountType ist "com.osp.app.signin" oder "LOCAL"
    //             aber accountName oder calName verrät es trotzdem
    if (type.contains('samsung') ||
        type.contains('com.sec') ||
        type.contains('sec.android') ||
        type.contains('vnd.sec') ||
        type.contains('com.samsung') ||
        type.contains('osp.app.signin') || // One UI 9 Samsung Account
        type.contains('knox') || // Samsung Knox-Container-Kalender
        accountName.contains('samsung') ||
        accountName.contains('galaxy') ||
        accountName.contains('@samsung.com') ||
        calName.contains('samsung') ||
        calName.contains('galaxy') ||
        // One UI 9 benennt den Standardkalender je nach Sprache z.B.
        // "Mein Kalender", "My Calendar", "Kalender", "Calendrier" usw.
        // Wir prüfen per contains() statt exakter Gleichheit, da Samsung
        // je nach Firmware-Version Zusätze anhängt (z.B. "Mein Kalender 1").
        calName.contains('my calendar') ||
        calName.contains('mein kalender') ||
        calName.contains('mon calendrier') || // Französisch
        calName.contains('mi calendario') || // Spanisch
        calName.contains('il mio calendario') || // Italienisch
        calName.contains('meu calendário') || // Portugiesisch
        calName.contains('mijn agenda')) { // Niederländisch
      return 'samsung';
    }

    // ── Allgemein lokal / AOSP ───────────────────────────────────────────────
    if (type == 'local' ||
        type.isEmpty ||
        type.contains('phone') ||
        type.contains('aosp') ||
        type.contains('sim') ||
        calName.contains('phone') ||
        calName.contains('local') ||
        calName.contains('gerät') || // "Gerätekalender" o.ä.
        calName.contains('kalender') || // generischer lokaler Kalendername
        calName.contains('calendar') ||
        calName.contains('calendrier') ||
        calName.contains('calendario') ||
        calName.contains('agenda')) {
      return 'system';
    }

    // ── Letzter Ausweg: wenn accountType leer oder unbekannt ist,
    //    und accountName wie eine E-Mail aussieht → Google oder sonstiges
    if (accountName.contains('@')) {
      if (accountName.contains('gmail') || accountName.contains('google')) {
        return 'google';
      }
      if (accountName.contains('outlook') ||
          accountName.contains('hotmail') ||
          accountName.contains('live.com') ||
          accountName.contains('microsoft')) {
        return 'outlook';
      }
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

  // ────────────────────────────────────────────────────────────
  //  getAvailableProviders
  //  Gibt die erkannten Kalender-Anbieter zurück (de-dupliziert).
  //  Fallback-Logik sorgt dafür, dass auf jedem Gerät mindestens
  //  ein Anbieter erscheint, wenn ein beschreibbarer Kalender existiert.
  // ────────────────────────────────────────────────────────────
  Future<List<CalendarProviderInfo>> getAvailableProviders() async {
    final providers = <CalendarProviderInfo>[];
    try {
      if (!await _ensurePermission()) return providers;
      final List<Calendar> calendars = await _retrieveWritableCalendars();

      debugPrint('CalendarService: ${calendars.length} beschreibbare Kalender gefunden');
      for (final cal in calendars) {
        debugPrint('  → id=${cal.id} | name="${cal.name}" | '
            'accountType="${cal.accountType}" | accountName="${cal.accountName}"');
      }

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

      // Wenn nur "system" erkannt wurde, aber eigentlich Samsung-Kalender
      // vorhanden sind (was wir anhand des Kalendernamens vermuten), upgraden.
      if (providers.length == 1 &&
          providers.first.id == 'system' &&
          calendars.isNotEmpty) {
        final firstCal = calendars.first;
        final firstCalName = (firstCal.name ?? '').toLowerCase();
        final firstAccName = (firstCal.accountName ?? '').toLowerCase();
        final firstType = (firstCal.accountType ?? '').toLowerCase();

        final isSamsungDevice = firstCalName.contains('my calendar') ||
            firstCalName.contains('mein kalender') ||
            firstCalName.contains('mon calendrier') ||
            firstCalName.contains('mi calendario') ||
            firstCalName.contains('il mio calendario') ||
            firstCalName.contains('meu calendário') ||
            firstCalName.contains('mijn agenda') ||
            firstCalName.contains('samsung') ||
            firstCalName.contains('galaxy') ||
            firstAccName.contains('samsung') ||
            firstAccName.contains('galaxy') ||
            firstType.contains('osp') ||
            firstType.contains('sec') ||
            firstType.contains('knox') ||
            firstType.isEmpty; // One UI 9: lokaler Kalender ohne accountType

        if (isSamsungDevice) {
          providers.clear();
          providers.add(CalendarProviderInfo(
            id: 'samsung',
            displayName: _displayName('samsung'),
            accountName: firstCal.accountName ?? 'Samsung',
          ));
        }
      }

      // Fallback: Wenn gar nichts erkannt wurde, aber Kalender da sind
      if (providers.isEmpty && calendars.isNotEmpty) {
        // Alle Kalender nochmal ohne Einschränkung durchsuchen –
        // ersten verfügbaren als "system" eintragen
        providers.add(CalendarProviderInfo(
          id: 'system',
          displayName: _displayName('system'),
          accountName: calendars.first.accountName ?? 'Lokal',
        ));
      }

      // "system" entfernen, wenn spezifischere Provider vorhanden sind
      final hasSpecific = providers.any((p) => p.id != 'system');
      if (hasSpecific) {
        providers.removeWhere((p) => p.id == 'system');
      }

      debugPrint('CalendarService: Erkannte Provider: ${providers.map((p) => p.id).join(', ')}');
    } catch (e) {
      debugPrint('getAvailableProviders error: $e');
    }
    return providers;
  }

  // ────────────────────────────────────────────────────────────
  //  _findBestCalendars
  //  Gibt eine geordnete Liste beschreibbarer Kalender zurück,
  //  die zum gesuchten Provider passen. Robuster Fallback:
  //  bei Samsung/system werden ALLE lokalen Kalender geprüft.
  // ────────────────────────────────────────────────────────────
  Future<List<Calendar>> _findBestCalendars(String providerId) async {
    final ordered = <Calendar>[];
    try {
      if (!await _ensurePermission()) return ordered;
      final List<Calendar> calendars = (await _retrieveWritableCalendars())
          .where((c) => c.id != null)
          .toList();

      // 1. Exakter Treffer
      for (final cal in calendars) {
        if (_detectProviderId(cal) == providerId) {
          ordered.add(cal);
        }
      }

      // 2. Samsung ↔ system Fallback (beide sind "lokal")
      if (ordered.isEmpty &&
          (providerId == 'system' || providerId == 'samsung')) {
        for (final cal in calendars) {
          final det = _detectProviderId(cal);
          if (det == 'samsung' || det == 'system' || det == null) {
            ordered.add(cal);
          }
        }
      }

      // 3. Genereller Fallback: irgendeinen beschreibbaren Kalender nehmen
      if (ordered.isEmpty && calendars.isNotEmpty) {
        ordered.addAll(calendars);
      }
    } catch (e) {
      debugPrint('_findBestCalendars error: $e');
    }
    return ordered;
  }

  // ────────────────────────────────────────────────────────────
  //  addEvent
  // ────────────────────────────────────────────────────────────
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
      final calendars = await _findBestCalendars(providerId);

      for (final calendar in calendars) {
        if (calendar.id == null) continue;
        try {
          final int hour = startTime?.hour ?? 9;
          final int minute = startTime?.minute ?? 0;
          final start = DateTime(
              expiryDate.year, expiryDate.month, expiryDate.day, hour, minute);
          final end = start.add(const Duration(minutes: 30));

          final event = Event(
            calendar.id!,
            title: title,
            description: description,
            start: tz.TZDateTime.from(start, tz.local),
            end: tz.TZDateTime.from(end, tz.local),
            reminders: [Reminder(minutes: reminderMinutes)],
            allDay: startTime == null,
          );

          final res = await _plugin.createOrUpdateEvent(event);
          if (res?.isSuccess == true && res?.data != null) {
            debugPrint('addEvent: Erfolg in Kalender ${calendar.id} (${calendar.name})');
            return CreatedEvent(res!.data!, calendar.id!);
          }
          final addErrors = res?.errors
                  .map((e) => '${e.errorCode}: ${e.errorMessage}')
                  .join(' | ') ??
              '';
          debugPrint('addEvent: Fehlgeschlagen in Kalender ${calendar.id}: '
              'isSuccess=${res?.isSuccess}, errors=$addErrors');
        } catch (e) {
          debugPrint('addEvent: Fehler bei Kalender ${calendar.id}: $e');
          // nächsten Kalender versuchen
        }
      }
    } catch (e) {
      debugPrint('addEvent error: $e');
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────
  //  updateEvent
  //  One UI 9 Bug-Workaround: retrieveEvents mit eventIds schlägt
  //  auf manchen Samsung-Geräten fehl. Wir versuchen daher:
  //    1. Kalender mit der gespeicherten calendarId direkt
  //    2. Alle passenden Kalender per ID-Suche
  //    3. Fallback: createOrUpdate ohne vorherigen Existenz-Check
  // ────────────────────────────────────────────────────────────
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

      final List<Calendar> allCals = (await _retrieveWritableCalendars())
          .where((Calendar c) => c.id != null)
          .toList();

      // Reihenfolge: zuerst der bekannte Kalender, dann passende, dann alle
      final List<Calendar> ordered = <Calendar>[];
      if (calendarId != null && calendarId.isNotEmpty) {
        ordered.addAll(allCals.where((c) => c.id == calendarId));
      }
      if (providerId != null) {
        for (final c in allCals) {
          if (!ordered.any((o) => o.id == c.id) &&
              (_detectProviderId(c) == providerId ||
               ((providerId == 'samsung' || providerId == 'system') &&
                (_detectProviderId(c) == 'samsung' || _detectProviderId(c) == 'system' || _detectProviderId(c) == null)))) {
            ordered.add(c);
          }
        }
      }
      // Alle übrigen als letzten Fallback
      for (final c in allCals) {
        if (!ordered.any((o) => o.id == c.id)) {
          ordered.add(c);
        }
      }

      final int hour = startTime?.hour ?? 9;
      final int minute = startTime?.minute ?? 0;
      final start = DateTime(
          expiryDate.year, expiryDate.month, expiryDate.day, hour, minute);
      final end = start.add(const Duration(minutes: 30));

      for (final Calendar cal in ordered) {
        if (cal.id == null) continue;

        // ── Existenz-Check ────────────────────────────────────────────────
        // Auf Samsung One UI 9 kann retrieveEvents mit eventIds abstürzen.
        // Wir versuchen es, und wenn es scheitert, gehen wir trotzdem weiter
        // (createOrUpdateEvent mit vorhandener eventId ist idempotent).
        bool mayExist = false;
        try {
          final check = await _plugin.retrieveEvents(
            cal.id!,
            RetrieveEventsParams(eventIds: [eventId]),
          );
          mayExist = check.data?.isNotEmpty == true;
        } catch (e) {
          debugPrint('updateEvent: retrieveEvents fehlgeschlagen für '
              'cal=${cal.id} – nehme Kalender trotzdem als Kandidat: $e');
          // Auf dem bekannten Kalender oder Provider-Kalender trotzdem versuchen
          mayExist = cal.id == calendarId ||
              _detectProviderId(cal) == providerId ||
              ((providerId == 'samsung' || providerId == 'system') &&
               (_detectProviderId(cal) == 'samsung' ||
                _detectProviderId(cal) == 'system' ||
                _detectProviderId(cal) == null));
        }

        if (!mayExist) continue;

        try {
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
            debugPrint('updateEvent: Erfolg in Kalender ${cal.id} (${cal.name})');
            return CreatedEvent(res!.data!, cal.id!);
          }
          final updateErrors = res?.errors
                  .map((e) => '${e.errorCode}: ${e.errorMessage}')
                  .join(' | ') ??
              '';
          debugPrint('updateEvent: Fehlgeschlagen in Kalender ${cal.id}: '
              'isSuccess=${res?.isSuccess}, errors=$updateErrors');
        } catch (e) {
          debugPrint('updateEvent: createOrUpdateEvent Fehler bei cal=${cal.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('updateEvent error: $e');
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────
  //  deleteEvent
  //  Sucht den Event in allen passenden Kalendern – nicht nur im ersten.
  // ────────────────────────────────────────────────────────────
  Future<bool> deleteEvent({
    required String eventId,
    required String providerId,
    String? calendarId,
  }) async {
    try {
      if (!await _ensurePermission()) return false;

      final List<Calendar> allCals = (await _retrieveWritableCalendars())
          .where((c) => c.id != null)
          .toList();

      // Reihenfolge: bekannter Kalender zuerst
      final List<Calendar> ordered = <Calendar>[];
      if (calendarId != null && calendarId.isNotEmpty) {
        ordered.addAll(allCals.where((c) => c.id == calendarId));
      }
      for (final c in allCals) {
        if (!ordered.any((o) => o.id == c.id)) {
          ordered.add(c);
        }
      }

      for (final cal in ordered) {
        if (cal.id == null) continue;
        try {
          // Erst prüfen ob Event da ist (mit Fallback)
          bool exists = false;
          try {
            final check = await _plugin.retrieveEvents(
              cal.id!,
              RetrieveEventsParams(eventIds: [eventId]),
            );
            exists = check.data?.isNotEmpty == true;
          } catch (_) {
            exists = cal.id == calendarId;
          }
          if (!exists) continue;

          final res = await _plugin.deleteEvent(cal.id!, eventId);
          if (res.isSuccess == true) {
            debugPrint('deleteEvent: Erfolg in Kalender ${cal.id}');
            return true;
          }
        } catch (e) {
          debugPrint('deleteEvent: Fehler bei cal=${cal.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('deleteEvent error: $e');
    }
    return false;
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

  // ────────────────────────────────────────────────────────────
  //  testProvider
  //  Probiert ALLE beschreibbaren Kalender durch (passende zuerst).
  //  Auf One UI 9 kann der erste Versuch scheitern – dann weiter.
  // ────────────────────────────────────────────────────────────
  Future<CalendarTestResult> testProvider(String providerId) async {
    _ensureTz();
    final log = <String>[];

    try {
      final hasPermissionBefore = (await _plugin.hasPermissions()).data == true;
      log.add('Berechtigung vor Anfrage: $hasPermissionBefore');

      if (!await _ensurePermission()) {
        log.add('❌ Keine Kalender-Berechtigung erteilt (auch nach Retry).');
        debugPrint('testProvider: keine Berechtigung');
        return CalendarTestResult(false, log.join('\n'));
      }
      log.add('✅ Berechtigung vorhanden.');

      final List<Calendar> rawCalendars = await _retrieveWritableCalendars();
      log.add('Gefundene beschreibbare Kalender: ${rawCalendars.length}');
      for (final c in rawCalendars) {
        log.add('  • id=${c.id} name="${c.name}" '
            'accountType="${c.accountType}" accountName="${c.accountName}" '
            'erkannt als "${_detectProviderId(c) ?? 'unbekannt'}"');
      }

      final List<Calendar> calendars =
          rawCalendars.where((c) => c.id != null).toList();

      if (calendars.isEmpty) {
        log.add('❌ Es wurden GAR KEINE beschreibbaren Kalender vom Gerät '
            'zurückgegeben – das ist kein Erkennungsproblem mehr, sondern '
            'der Android-Kalenderspeicher selbst liefert nichts. Prüfe: ist '
            'in den System-Einstellungen → Apps → Warranty Manager → '
            'Berechtigungen "Kalender" wirklich auf "Zulassen" (nicht nur '
            'einmalig) gestellt? Gibt es überhaupt ein Konto mit Kalender '
            '(Samsung-Konto, Google-Konto o.ä.) auf dem Gerät?');
        debugPrint('testProvider: keine beschreibbaren Kalender');
        return CalendarTestResult(false, log.join('\n'));
      }

      // Erst passende, dann Samsung/system Cross-Fallback, dann alle anderen
      final matching = <Calendar>[];
      final crossFallback = <Calendar>[];
      final others = <Calendar>[];

      for (final cal in calendars) {
        final det = _detectProviderId(cal);
        if (det == providerId) {
          matching.add(cal);
        } else if ((providerId == 'samsung' || providerId == 'system') &&
            (det == 'samsung' || det == 'system' || det == null)) {
          crossFallback.add(cal);
        } else {
          others.add(cal);
        }
      }

      final ordered = [...matching, ...crossFallback, ...others];

      for (final cal in ordered) {
        if (cal.id == null) continue;
        try {
          final now = DateTime.now().add(const Duration(minutes: 5));
          final test = Event(
            cal.id!,
            title: 'Warranty Manager Test',
            description: 'Test-Eintrag – kann gelöscht werden.',
            start: tz.TZDateTime.from(now, tz.local),
            end: tz.TZDateTime.from(
                now.add(const Duration(minutes: 10)), tz.local),
          );

          final res = await _plugin.createOrUpdateEvent(test);
          final errors = res?.errors
                  .map((e) => '${e.errorCode}: ${e.errorMessage}')
                  .join(' | ') ??
              '';
          log.add('Versuch cal=${cal.id} ("${cal.name}"): '
              'isSuccess=${res?.isSuccess}, eventId=${res?.data}'
              '${errors.isNotEmpty ? ', Fehler=$errors' : ''}');
          debugPrint('testProvider: cal=${cal.id} (${cal.name}) → '
              'success=${res?.isSuccess}, errors=$errors');

          if (res?.isSuccess == true && res?.data != null) {
            final del = await _plugin.deleteEvent(cal.id!, res!.data!);
            log.add('✅ Test-Event erfolgreich geschrieben und wieder '
                'gelöscht (deleteSuccess=${del.isSuccess}).');
            return CalendarTestResult(true, log.join('\n'));
          }
        } catch (e) {
          log.add('💥 Ausnahme bei cal=${cal.id}: $e');
          debugPrint('testProvider: Fehler bei cal=${cal.id}: $e');
        }
      }

      log.add('❌ Kein einziger Kalender hat das Test-Event angenommen. '
          'Das Schreiben (createOrUpdateEvent) schlägt also fehl, obwohl '
          'Berechtigung und Kalenderliste vorhanden sind – das deutet auf '
          'eine Einschränkung des jeweiligen Kalender-Kontos hin (z.B. ein '
          'read-only-ähnliches Samsung-Konto, das sich nur in der App selbst '
          'bearbeiten lässt), nicht mehr auf unsere Erkennungslogik.');
    } catch (e) {
      log.add('💥 Unerwarteter Fehler: $e');
      debugPrint('testProvider error: $e');
    }
    return CalendarTestResult(false, log.join('\n'));
  }
}