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
    typeCustom,
  ];

  // ── Optionen pro Baustein-Typ ──

  /// Ob der Baustein ein Label ("Ablauf: ", "Preis: ", ...) unterstützt.
  static bool hasLabelOption(String type) {
    return type != typeName && type != typeCustom;
  }

  /// Ob der Baustein eine Format-Auswahl (Tage/Wochen/Monate/Jahre) unterstützt.
  static bool hasFormatOption(String type) {
    return type == typeDaysLeft || type == typeDuration;
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

  /// Default: Label anzeigen (auch für alte Templates ohne 'showLabel'-Feld).
  static bool getShowLabel(Map<String, String> part) {
    return part['showLabel'] != 'false';
  }

  /// Default: 'auto' (auch für alte Templates ohne 'format'-Feld).
  static String getFormat(Map<String, String> part) {
    return part['format'] ?? formatAuto;
  }

  /// Gibt das Standard-Template zurück, das beim ersten Öffnen
  /// der Einstellungen angezeigt wird.
  static List<Map<String, String>> defaultTemplate() {
    return [
      createPart(typeName),
      createPart(typeExpiryDate),
      createPart(typeDaysLeft),
    ];
  }

  /// Parst einen Datums-String im Format DD.MM.YYYY.
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

  /// Formatiert eine Tages-Anzahl in den gewählten Einheiten.
  /// Liefert z. B. "2 Jahre" / "11 Monate" / "48 Wochen" / "335 Tage".
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
        // Smart: nahe an ganzem Jahr → Jahre, sonst Monate → Wochen → Tage
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

  // ── Einzel-Renderer ──

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
      // Zukunftsfall: Format anwenden
      final text = _formatDurationValue(
        langCode: langCode,
        totalDays: days,
        format: format,
      );
      return showLabel ? '${getText(langCode, 'days_left')}$text' : text;
    }

    // Abgelaufen: immer in Tagen (grammatikalisch korrekt)
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
  /// Berücksichtigt `showLabel` und `format` aus dem Baustein.
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
        final s = gerat?['woGekauft'] ?? '';
        if (s.isEmpty || s == 'Unbekannt') {
          return showLabel
              ? '${getText(langCode, 'bought_at')}: ${getText(langCode, 'unknown')}'
              : getText(langCode, 'unknown');
        }
        return showLabel ? '${getText(langCode, 'bought_at')}: $s' : s;
      case typePrice:
        final p = gerat?['preis'] ?? '';
        if (p.isEmpty || p == 'Unbekannt') return '';
        final w = gerat?['waehrung'] ?? currencySymbol;
        return showLabel
            ? '${getText(langCode, 'price')}: $p $w'
            : '$p $w';
      case typeDuration:
        return _renderDuration(
          langCode: langCode,
          gerat: gerat,
          showLabel: showLabel,
          format: format,
        );
      case typeCustom:
        return part['text'] ?? '';
      default:
        return '';
    }
  }

  /// Baut den kompletten Notification-Body aus dem Template.
  /// Ist das Template leer, wird das bisherige Legacy-Format genutzt.
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
      // Legacy-Fallback
      return '${getText(langCode, 'notif_body')}$ablaufDatumStr${getText(langCode, 'notif_body_end')}';
    }

    // Fallback-Werte für Name + Ablaufdatum einsetzen, falls gerat sie nicht hat
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