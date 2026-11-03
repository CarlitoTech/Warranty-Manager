import 'package:flutter/material.dart';
import 'settings_provider.dart';

/// Zentrale Logik zum Rendern von Notification-Bausteinen.
/// Wird sowohl für die Live-Vorschau in den Einstellungen als auch
/// für die tatsächliche Notification verwendet, damit beides identisch ist.
class NotificationTemplateHelper {
  static const String typeName = 'name';
  static const String typeBuyDate = 'buyDate';
  static const String typeExpiryDate = 'expiryDate';
  static const String typeDaysLeft = 'daysLeft';
  static const String typeStore = 'store';
  static const String typePrice = 'price';
  static const String typeDuration = 'duration';
  static const String typeCategory = 'category';
  static const String typeRemarks = 'remarks';
  static const String typePhotoCount = 'photoCount';
  static const String typeDetailLink = 'detailLink';
  static const String typeScreenshot = 'screenshot';
  static const String typeCustom = 'custom';

  // ── Format-Optionen (nur für daysLeft + duration) ──
  static const String formatAuto = 'auto';
  static const String formatDays = 'days';
  static const String formatWeeks = 'weeks';
  static const String formatMonths = 'months';
  static const String formatYears = 'years';

  static const List<String> formatOptions = [
    formatAuto,
    formatDays,
    formatWeeks,
    formatMonths,
    formatYears,
  ];

  /// Bausteine, die nur einmal hinzugefügt werden dürfen.
  static const List<String> singleUseTypes = [
    typeName,
    typeBuyDate,
    typeExpiryDate,
    typeDaysLeft,
    typeStore,
    typePrice,
    typeDuration,
    typeCategory,
    typeRemarks,
    typePhotoCount,
    typeDetailLink,
    typeScreenshot,
  ];

  /// Alle verfügbaren Baustein-Typen (inkl. custom).
  static const List<String> availableTypes = [
    typeName,
    typeBuyDate,
    typeExpiryDate,
    typeDaysLeft,
    typeStore,
    typePrice,
    typeDuration,
    typeCategory,
    typeRemarks,
    typePhotoCount,
    typeDetailLink,
    typeScreenshot,
    typeCustom,
  ];

  // ── Optionen pro Baustein-Typ ──

  /// Ob der Baustein ein Label ("Ablauf: ", ...) unterstützt.
  /// Kein Label bei:
  /// - Name (nur der Name)
  /// - Store (immer "Gekauft bei: X" – Toggle wäre verwirrend, weil "X" allein nicht verständlich wäre)
  /// - Price ("1199 €" ist selbsterklärend – "Preis: 1199 €" wäre redundant)
  /// - Custom (kein Wert vorhanden, nur Freitext)
  /// - Detail-Link / Screenshot (fester Hinweistext)
  /// - Fotoanzahl ("3 Fotos" ist selbsterklärend)
  static bool hasLabelOption(String type) {
    switch (type) {
      case typeName:
      case typeStore:
      case typePrice:
      case typeCustom:
      case typeDetailLink:
      case typeScreenshot:
      case typePhotoCount:
        return false;
      default:
        return true;
    }
  }

  /// Ob der Baustein eine Format-Auswahl (Tage/Wochen/Monate/Jahre) unterstützt.
  static bool hasFormatOption(String type) {
    return type == typeDaysLeft || type == typeDuration;
  }

  /// Standardfarbe pro Baustein-Typ (ohne Override).
  static Color colorForType(String type) {
    switch (type) {
      case typeName:
        return Colors.blue;
      case typeBuyDate:
        return Colors.green;
      case typeExpiryDate:
        return Colors.orange;
      case typeDaysLeft:
        return Colors.purple;
      case typeStore:
        return Colors.teal;
      case typePrice:
        return Colors.amber.shade700;
      case typeDuration:
        return Colors.indigo;
      case typeCategory:
        return Colors.cyan.shade700;
      case typeRemarks:
        return Colors.pink.shade400;
      case typePhotoCount:
        return Colors.brown;
      case typeDetailLink:
        return Colors.lightBlue.shade700;
      case typeScreenshot:
        return Colors.deepPurple;
      case typeCustom:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// Liefert die effektive Farbe eines Bausteins – mit optionalem Override
  /// über `part['color']` (als ARGB-String gespeichert).
  static Color getPartColor(Map<String, String> part) {
    final raw = part['color'];
    if (raw != null && raw.isNotEmpty) {
      final int? argb = int.tryParse(raw);
      if (argb != null) return Color(argb);
    }
    return colorForType(part['type'] ?? '');
  }

  static String getLabelKeyForType(String type) {
    switch (type) {
      case typeName:
        return 'product_name';
      case typeBuyDate:
        return 'buy_date';
      case typeExpiryDate:
        return 'expiry';
      case typeDaysLeft:
        return 'notif_part_days_left';
      case typeStore:
        return 'bought_at';
      case typePrice:
        return 'price';
      case typeDuration:
        return 'warranty_duration';
      case typeCategory:
        return 'category';
      case typeRemarks:
        return 'remarks';
      case typePhotoCount:
        return 'notif_part_photo_count';
      case typeDetailLink:
        return 'notif_part_detail_link';
      case typeScreenshot:
        return 'notif_part_screenshot';
      case typeCustom:
        return 'notif_part_custom';
      default:
        return 'unknown';
    }
  }

  static String getFormatLabelKey(String format) {
    switch (format) {
      case formatDays:
        return 'notif_format_days';
      case formatWeeks:
        return 'notif_format_weeks';
      case formatMonths:
        return 'notif_format_months';
      case formatYears:
        return 'notif_format_years';
      case formatAuto:
      default:
        return 'notif_format_auto';
    }
  }

  /// Erzeugt einen neuen Baustein mit sinnvollen Standardwerten.
  static Map<String, String> createPart(String type, {String? customText}) {
    final part = <String, String>{'type': type};
    if (hasLabelOption(type)) part['showLabel'] = 'true';
    if (hasFormatOption(type)) part['format'] = formatAuto;
    if (type == typeCustom && customText != null) part['text'] = customText;
    return part;
  }

  static bool getShowLabel(Map<String, String> part) {
    return part['showLabel'] != 'false';
  }

  static String getFormat(Map<String, String> part) {
    return part['format'] ?? formatAuto;
  }

  static List<Map<String, String>> defaultTemplate() {
    return [
      createPart(typeName),
      createPart(typeExpiryDate),
      createPart(typeDaysLeft),
    ];
  }

  static DateTime? parseDateStr(String? s) {
    if (s == null || s.isEmpty) return null;
    final p = s.split('.');
    if (p.length == 3) {
      try {
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _formatDurationValue({
    required String langCode,
    required int totalDays,
    required String format,
  }) {
    int value;
    String singularKey;
    String pluralKey;

    switch (format) {
      case formatDays:
        value = totalDays;
        singularKey = 'day_singular';
        pluralKey = 'days_plural';
        break;
      case formatWeeks:
        value = (totalDays / 7).round();
        singularKey = 'week_singular';
        pluralKey = 'weeks_plural';
        break;
      case formatMonths:
        value = (totalDays / 30.44).round();
        singularKey = 'month_singular';
        pluralKey = 'months_plural';
        break;
      case formatYears:
        value = (totalDays / 365.25).round();
        singularKey = 'year_singular';
        pluralKey = 'years_plural';
        break;
      case formatAuto:
      default:
        final roundedYears = (totalDays / 365.25).round();
        if (roundedYears >= 1 &&
            (totalDays - roundedYears * 365.25).abs() <= 20) {
          value = roundedYears;
          singularKey = 'year_singular';
          pluralKey = 'years_plural';
        } else {
          final months = (totalDays / 30.44).round();
          if (months >= 1) {
            value = months;
            singularKey = 'month_singular';
            pluralKey = 'months_plural';
          } else if (totalDays >= 7) {
            value = totalDays ~/ 7;
            singularKey = 'week_singular';
            pluralKey = 'weeks_plural';
          } else {
            value = totalDays;
            singularKey = 'day_singular';
            pluralKey = 'days_plural';
          }
        }
    }

    if (value < 1) value = 1;
    final unit = value == 1
        ? getText(langCode, singularKey)
        : getText(langCode, pluralKey);
    return '$value $unit';
  }

  static String _renderDaysLeft({
    required String langCode,
    required Map<String, String>? gerat,
    required DateTime? referenceDate,
    required bool showLabel,
    required String format,
  }) {
    final expiry = parseDateStr(gerat?['ablaufDatum']);
    if (expiry == null) return '';

    final ref = referenceDate ?? DateTime.now();
    final refDay = DateTime(ref.year, ref.month, ref.day);
    final days = expiry.difference(refDay).inDays;

    if (days == 0) return getText(langCode, 'expires_today');

    if (days > 0) {
      final text = _formatDurationValue(
        langCode: langCode,
        totalDays: days,
        format: format,
      );
      return showLabel ? '${getText(langCode, 'days_left')}$text' : text;
    }

    final absDays = days.abs();
    if (showLabel) {
      final unit = absDays == 1
          ? getText(langCode, 'expired_day_singular')
          : getText(langCode, 'expired_day_plural');
      return '${getText(langCode, 'expired_since')}$absDays$unit';
    }
    final unit = absDays == 1
        ? getText(langCode, 'day_singular')
        : getText(langCode, 'days_plural');
    return '$absDays $unit';
  }

  static String _renderDuration({
    required String langCode,
    required Map<String, String>? gerat,
    required bool showLabel,
    required String format,
  }) {
    final buy = parseDateStr(gerat?['kaufDatum']);
    final expiry = parseDateStr(gerat?['ablaufDatum']);
    if (buy == null || expiry == null) return '';
    final totalDays = expiry.difference(buy).inDays;
    if (totalDays <= 0) return '';

    final text = _formatDurationValue(
      langCode: langCode,
      totalDays: totalDays,
      format: format,
    );
    return showLabel
        ? '${getText(langCode, 'warranty_duration')}: $text'
        : text;
  }

  /// Rendert einen einzelnen Baustein in Text.
  static String renderPart({
    required String langCode,
    required Map<String, String> part,
    required Map<String, String>? gerat,
    required String currencySymbol,
    required DateTime? referenceDate,
  }) {
    final type = part['type'] ?? '';
    final showLabel = getShowLabel(part);
    final format = getFormat(part);

    switch (type) {
      case typeName:
        final n = gerat?['name'] ?? '';
        return n.isEmpty ? getText(langCode, 'unknown') : n;
      case typeBuyDate:
        final d = gerat?['kaufDatum'] ?? '';
        if (d.isEmpty) return '';
        return showLabel
            ? '${getText(langCode, 'buy_date')}: $d'
            : d;
      case typeExpiryDate:
        final d = gerat?['ablaufDatum'] ?? '';
        if (d.isEmpty) return '';
        return showLabel
            ? '${getText(langCode, 'expiry')}: $d'
            : d;
      case typeDaysLeft:
        return _renderDaysLeft(
          langCode: langCode,
          gerat: gerat,
          referenceDate: referenceDate,
          showLabel: showLabel,
          format: format,
        );
      case typeStore:
        // Immer mit Label, da "MediaMarkt" alleine nicht verständlich wäre.
        final s = gerat?['woGekauft'] ?? '';
        if (s.isEmpty || s == 'Unbekannt') {
          return '${getText(langCode, 'bought_at')}: ${getText(langCode, 'unknown')}';
        }
        return '${getText(langCode, 'bought_at')}: $s';
      case typePrice:
        // Kein Label – "1199 €" ist selbsterklärend.
        final p = gerat?['preis'] ?? '';
        if (p.isEmpty || p == 'Unbekannt') return '';
        final w = gerat?['waehrung'] ?? currencySymbol;
        return '$p $w';
      case typeDuration:
        return _renderDuration(
          langCode: langCode,
          gerat: gerat,
          showLabel: showLabel,
          format: format,
        );
      case typeCategory:
        final c = gerat?['kategorie'] ?? '';
        if (c.isEmpty) return '';
        final catName = getText(langCode, c);
        return showLabel
            ? '${getText(langCode, 'category')}: $catName'
            : catName;
      case typeRemarks:
        final r = gerat?['bemerkung'] ?? '';
        if (r.isEmpty) return '';
        return showLabel
            ? '${getText(langCode, 'remarks')}: $r'
            : r;
      case typePhotoCount:
        // Immer ohne Label – "3 Fotos" ist selbsterklärend.
        final paths = gerat?['bildPfade'] ?? '';
        final count = paths.isEmpty
            ? 0
            : paths
                .split(',')
                .where((p) => p.trim().isNotEmpty)
                .length;
        if (count == 0) return '';
        final unit = count == 1
            ? getText(langCode, 'notif_photo_singular')
            : getText(langCode, 'notif_photo_plural');
        return '$count $unit';
      case typeDetailLink:
        return getText(langCode, 'notif_detail_link_text');
      case typeScreenshot:
        return getText(langCode, 'notif_screenshot_text');
      case typeCustom:
        return part['text'] ?? '';
      default:
        return '';
    }
  }

  static String buildBody({
    required String langCode,
    required List<Map<String, String>> template,
    required String produktName,
    required String ablaufDatumStr,
    required Map<String, String>? gerat,
    required String currencySymbol,
    required DateTime? referenceDate,
  }) {
    if (template.isEmpty) {
      return '${getText(langCode, 'notif_body')}$ablaufDatumStr${getText(langCode, 'notif_body_end')}';
    }

    final effective = <String, String>{};
    if (gerat != null) effective.addAll(gerat);
    if ((effective['name'] ?? '').isEmpty) {
      effective['name'] = produktName;
    }
    if ((effective['ablaufDatum'] ?? '').isEmpty) {
      effective['ablaufDatum'] = ablaufDatumStr;
    }

    final buffer = StringBuffer();
    bool first = true;
    for (final part in template) {
      final text = renderPart(
        langCode: langCode,
        part: part,
        gerat: effective,
        currencySymbol: currencySymbol,
        referenceDate: referenceDate,
      );
      if (text.isEmpty) continue;
      if (!first) buffer.write(' • ');
      buffer.write(text);
      first = false;
    }
    return buffer.toString();
  }
}