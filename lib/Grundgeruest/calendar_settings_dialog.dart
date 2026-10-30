import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calender_service.dart';
import 'settings_provider.dart';

Future<void> showCalendarSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const _CalendarSettingsDialog(),
  );
}

class _CalendarSettingsDialog extends StatefulWidget {
  const _CalendarSettingsDialog();
  @override
  State<_CalendarSettingsDialog> createState() =>
      _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<_CalendarSettingsDialog> {
  bool _loading = true;
  bool _busy = false;
  List<CalendarProviderInfo> _providers = [];
  bool _didAutoSelect = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
  final providers = await CalendarService().getAvailableProviders();
  if (!mounted) return;

  setState(() {
    _providers = providers;
    _loading = false;
  });

  // Automatische Auswahl: nur wenn genau 1 echter Anbieter existiert
  // UND der Nutzer NICHT explizit ICS gewählt hat.
  if (!_didAutoSelect && mounted) {
    _didAutoSelect = true;
    final settings = context.read<SettingsProvider>();
    final current = settings.preferredCalendarApp;
    final currentValid = providers.any((p) => p.id == current);

    // ICS niemals überschreiben – das ist eine bewusste Nutzerentscheidung
    if (providers.length == 1 && !currentValid && current != 'ics') {
      await settings.setPreferredCalendarApp(providers.first.id);
    }
  }
}

  String _appName(String app, String lang) {
    switch (app) {
      case 'google':
        return getText(lang, 'calendar_app_google');
      case 'samsung':
        return getText(lang, 'calendar_app_samsung');
      case 'outlook':
        return getText(lang, 'calendar_app_outlook');
      case 'ics':
        return getText(lang, 'calendar_app_ics');
      case 'system':
      default:
        return getText(lang, 'calendar_app_system');
    }
  }

  String _reminderName(int minutes, String lang) {
    if (minutes <= 15) return getText(lang, 'reminder_time_15min');
    if (minutes <= 60) return getText(lang, 'reminder_time_1hour');
    if (minutes <= 1440) return getText(lang, 'reminder_time_1day');
    if (minutes <= 4320) return getText(lang, 'reminder_time_3days');
    return getText(lang, 'reminder_time_1week');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.languageCode;
        final selected = settings.preferredCalendarApp;
        final isIcs = selected == 'ics';
        final hasRealProvider =
            !isIcs && _providers.any((p) => p.id == selected);

        final canAutoSync = hasRealProvider;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.calendar_month, color: settings.appButtonColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  getText(lang, 'calendar_settings'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _loading
                ? const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getText(lang, 'calendar_settings_desc'),
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        // ── Status-Banner ────────────────────────
                        _buildStatusBanner(lang, settings, selected, isIcs),
                        const SizedBox(height: 12),

                        // ── Auto-Add / Auto-Update ───────────────
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            Icons.add_task,
                            color: canAutoSync
                                ? settings.appButtonColor
                                : Colors.grey,
                          ),
                          title: Text(
                            getText(lang, 'auto_add_to_calendar'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            canAutoSync
                                ? getText(lang, 'auto_add_to_calendar_desc')
                                : getText(lang, 'auto_add_disabled_hint'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: canAutoSync && settings.autoAddToCalendar,
                          onChanged: canAutoSync
                              ? (v) => settings.setAutoAddToCalendar(v)
                              : null,
                        ),
                        const Divider(height: 1),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            Icons.sync,
                            color: canAutoSync
                                ? settings.appButtonColor
                                : Colors.grey,
                          ),
                          title: Text(
                            getText(lang, 'auto_update_calendar'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            canAutoSync
                                ? getText(lang, 'auto_update_calendar_desc')
                                : getText(lang, 'auto_update_disabled_hint'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: canAutoSync && settings.autoUpdateCalendar,
                          onChanged: canAutoSync
                              ? (v) => settings.setAutoUpdateCalendar(v)
                              : null,
                        ),
                        const Divider(height: 1),

                        // ── Bevorzugte Kalender-App ──────────────
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.apps,
                              color: settings.appButtonColor),
                          title: Text(
                            getText(lang, 'preferred_calendar_app'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _appName(selected, lang),
                            style: TextStyle(
                              fontSize: 12,
                              color: settings.appButtonColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_drop_down),
                          onTap: _busy
                              ? null
                              : () => _showProviderPicker(settings, lang),
                        ),
                        const Divider(height: 1),

                        // ── Standard-Erinnerung ──────────────────
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.notifications_active_outlined,
                              color: settings.appButtonColor),
                          title: Text(
                            getText(lang, 'default_reminder_time'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _reminderName(
                                settings.defaultReminderMinutes, lang),
                            style: TextStyle(
                              fontSize: 12,
                              color: settings.appButtonColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_drop_down),
                          onTap: _busy
                              ? null
                              : () => _showReminderPicker(settings, lang),
                        ),
                        const Divider(height: 1),

                        // ── ICS-Download (immer verfügbar) ───────
                        const SizedBox(height: 8),
                        _buildIcsDownloadTile(settings, lang),
                        const SizedBox(height: 8),

                        // ── Alle Einträge synchronisieren ────────
                        if (hasRealProvider)
                          _buildSyncAllTile(settings, lang),
                      ],
                    ),
                  ),
          ),
          actions: [
            if (!_loading && hasRealProvider)
              TextButton.icon(
                onPressed: _busy ? null : () => _testProvider(settings, lang),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(getText(lang, 'calendar_test_button')),
              ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(getText(lang, 'ok')),
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  //  ICS-Download-Kachel
  // ────────────────────────────────────────────────────────────
  Widget _buildIcsDownloadTile(SettingsProvider settings, String lang) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _busy ? null : () => _downloadAllIcs(settings, lang),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.file_download_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getText(lang, 'calendar_app_ics'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    getText(lang, 'calendar_ics_hint'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  "Alle synchronisieren"-Kachel
  // ────────────────────────────────────────────────────────────
  Widget _buildSyncAllTile(SettingsProvider settings, String lang) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _busy ? null : () => _syncAllEntries(settings, lang),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: settings.appButtonColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: settings.appButtonColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.sync, color: settings.appButtonColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Alle Einträge jetzt synchronisieren',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: settings.appButtonColor,
                ),
              ),
            ),
            if (_busy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: settings.appButtonColor,
                ),
              )
            else
              Icon(Icons.chevron_right, color: settings.appButtonColor),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  Status-Banner
  // ────────────────────────────────────────────────────────────
  Widget _buildStatusBanner(
      String lang, SettingsProvider settings, String selected, bool isIcs) {
    if (_providers.isEmpty) {
      return _banner(
        color: Colors.orange,
        icon: Icons.info_outline,
        text: getText(lang, 'calendar_no_provider_desc'),
      );
    }

    if (!isIcs && !_providers.any((p) => p.id == selected)) {
      return _banner(
        color: Colors.redAccent,
        icon: Icons.error_outline,
        text: getText(lang, 'calendar_selected_unavailable'),
      );
    }

    if (isIcs) {
      return _banner(
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
        text: getText(lang, 'calendar_ics_hint_long'),
      );
    }

    return _banner(
      color: Colors.green,
      icon: Icons.check_circle_outline,
      text: '${getText(lang, 'calendar_detected_providers')}: '
          '${_providers.map((p) => _appName(p.id, lang)).join(', ')}',
    );
  }

  Widget _banner({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  Anbieter-Picker
  // ────────────────────────────────────────────────────────────
  void _showProviderPicker(SettingsProvider settings, String lang) {
  showDialog<void>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(getText(lang, 'preferred_calendar_app')),
      children: [
        if (_providers.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              getText(lang, 'calendar_no_provider'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )
        else
          for (final p in _providers)
            SimpleDialogOption(
              onPressed: () async {
                await settings.setPreferredCalendarApp(p.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _appName(p.id, lang),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (settings.preferredCalendarApp == p.id)
                    Icon(Icons.check, color: settings.appButtonColor),
                ],
              ),
            ),

        // NEU: ICS nur im Picker zeigen, wenn KEINE echte Kalender-App
        // installiert ist ODER der Nutzer aktuell ICS benutzt (dann muss er
        // wechseln können). Sobald er auf eine echte App wechselt,
        // verschwindet ICS aus dem Picker. Der ICS-Download bleibt
        // weiterhin über die separate orangene Kachel im Hauptdialog möglich.
        if (_providers.isEmpty || settings.preferredCalendarApp == 'ics') ...[
          const Divider(),
          SimpleDialogOption(
            onPressed: () => _confirmIcs(ctx, settings, lang),
            child: Row(
              children: [
                const Icon(Icons.file_download_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getText(lang, 'calendar_app_ics'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (settings.preferredCalendarApp == 'ics')
                  Icon(Icons.check, color: settings.appButtonColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              getText(lang, 'calendar_ics_hint'),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ],
    ),
  );
}

  Future<void> _confirmIcs(
      BuildContext ctx, SettingsProvider settings, String lang) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(getText(lang, 'calendar_ics_confirm_title')),
        content: Text(getText(lang, 'calendar_ics_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(getText(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(getText(lang, 'ok')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await settings.setPreferredCalendarApp('ics');
      await settings.setAutoAddToCalendar(false);
      await settings.setAutoUpdateCalendar(false);
      if (ctx.mounted) Navigator.pop(ctx);
    }
  }

  // ────────────────────────────────────────────────────────────
  //  Erinnerungszeit-Picker
  // ────────────────────────────────────────────────────────────
  void _showReminderPicker(SettingsProvider settings, String lang) {
    const options = <int>[15, 60, 1440, 4320, 10080];
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(getText(lang, 'default_reminder_time')),
        children: [
          for (final v in options)
            SimpleDialogOption(
              onPressed: () async {
                await settings.setDefaultReminderMinutes(v);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(_reminderName(v, lang),
                        style: const TextStyle(fontSize: 14)),
                  ),
                  if (settings.defaultReminderMinutes == v)
                    Icon(Icons.check, color: settings.appButtonColor),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  Test-Provider
  // ────────────────────────────────────────────────────────────
  Future<void> _testProvider(SettingsProvider settings, String lang) async {
    final ok =
        await CalendarService().testProvider(settings.preferredCalendarApp);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        icon: Icon(
          ok ? Icons.check_circle : Icons.error_outline,
          color: ok ? Colors.green : Colors.redAccent,
          size: 40,
        ),
        content: Text(
          getText(
              lang, ok ? 'calendar_test_success' : 'calendar_test_failed'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(getText(lang, 'ok')),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  ICS-Download (alle Einträge)
  // ────────────────────────────────────────────────────────────
  Future<void> _downloadAllIcs(SettingsProvider settings, String lang) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('gerate_liste');

    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText(lang, 'no_devices')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<Map<String, String>> entries;
    try {
      final List<dynamic> liste = jsonDecode(raw);
      entries = liste
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText(lang, 'import_error')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText(lang, 'no_devices')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final ics = CalendarService().buildIcsForEntries(
        entries: entries,
        reminderMinutes: settings.defaultReminderMinutes,
      );

      await CalendarService().shareIcsFile(
        icsContent: ics,
        fileName: 'WarrantyManager_Warranties.ics',
        subject: 'Warranty Manager – Garantien',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ICS-Export fehlgeschlagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ────────────────────────────────────────────────────────────
  //  "Alle Einträge jetzt synchronisieren"
  // ────────────────────────────────────────────────────────────
  Future<void> _syncAllEntries(SettingsProvider settings, String lang) async {
  setState(() => _busy = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('gerate_liste');
    if (raw == null || raw.isEmpty) {
      setState(() => _busy = false);
      return;
    }

    final List<dynamic> decoded = jsonDecode(raw);
    final List<Map<String, String>> entries =
        decoded.map((e) => Map<String, String>.from(e as Map)).toList();

    final providerId = settings.preferredCalendarApp;
    final service = CalendarService();
    int synced = 0;
    int failed = 0;

    for (final entry in entries) {
      final name = (entry['name'] ?? '').trim();
      if (name.isEmpty) continue;

      final expiry = service.parseEntryExpiry(entry['ablaufDatum']);
      if (expiry == null) continue;

      final description =
          'Garantie bis ${entry['ablaufDatum']}\n'
          'Gekauft bei: ${entry['woGekauft'] ?? '-'}';

      final existingId = entry['calendarEventId'];
      final existingCalId = entry['calendarId'];

      if (existingId != null && existingId.isNotEmpty) {
        final updated = await service.updateEvent(
          eventId: existingId,
          calendarId: existingCalId,
          providerId: providerId,
          title: name,
          description: description,
          expiryDate: expiry,
          reminderMinutes: settings.defaultReminderMinutes,
        );
        if (updated != null) {
          entry['calendarEventId'] = updated.eventId;
          entry['calendarId'] = updated.calendarId;
          synced++;
          continue;
        }
      }

      // Neu anlegen
      final created = await service.addEvent(
        title: name,
        description: description,
        expiryDate: expiry,
        providerId: providerId,
        reminderMinutes: settings.defaultReminderMinutes,
      );
      if (created != null) {
        entry['calendarEventId'] = created.eventId;
        entry['calendarId'] = created.calendarId;   // NEU: mitspeichern
        synced++;
      } else {
        failed++;
      }
    }

    await prefs.setString('gerate_liste', jsonEncode(entries));

    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed > 0
              ? 'Synchronisiert: $synced, Fehlgeschlagen: $failed'
              : 'Alle $synced Einträge synchronisiert ✓',
        ),
        backgroundColor:
            failed > 0 ? Colors.orange.shade800 : Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Synchronisation fehlgeschlagen: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}