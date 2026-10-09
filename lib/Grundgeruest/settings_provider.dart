import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garantiemanager/Translations/translations_de.dart';
import 'package:garantiemanager/Translations/translations_en.dart';
import 'package:garantiemanager/Translations/translations_fr.dart';
import 'package:garantiemanager/Translations/translations_es.dart';

const List<Map<String, String>> appCurrencies = [
  {'label_key': 'curr_eur', 'symbol': '€'},
  {'label_key': 'curr_chf', 'symbol': 'CHF'},
  {'label_key': 'curr_usd', 'symbol': '\$'},
  {'label_key': 'curr_cad', 'symbol': 'CA\$'},
  {'label_key': 'curr_aud', 'symbol': 'A\$'},
  {'label_key': 'curr_nzd', 'symbol': 'NZ\$'},
  {'label_key': 'curr_gbp', 'symbol': '£'},
  {'label_key': 'curr_mxn', 'symbol': 'MXN'},
  {'label_key': 'curr_ars', 'symbol': 'ARS'},
  {'label_key': 'curr_clp', 'symbol': 'CLP'},
  {'label_key': 'curr_cop', 'symbol': 'COP'},
  {'label_key': 'curr_pen', 'symbol': 'PEN'},
  {'label_key': 'curr_uyu', 'symbol': 'UYU'},
  {'label_key': 'curr_pyg', 'symbol': '₲'},
  {'label_key': 'curr_bob', 'symbol': 'Bs.'},
  {'label_key': 'curr_brl', 'symbol': 'R\$'},
  {'label_key': 'curr_crc', 'symbol': '₡'},
  {'label_key': 'curr_gtq', 'symbol': 'Q'},
  {'label_key': 'curr_hnl', 'symbol': 'L'},
  {'label_key': 'curr_nio', 'symbol': 'C\$'},
  {'label_key': 'curr_dop', 'symbol': 'RD\$'},
  {'label_key': 'curr_htg', 'symbol': 'G'},
  {'label_key': 'curr_cup', 'symbol': 'CUP'},
  {'label_key': 'curr_xof', 'symbol': 'XOF'},
  {'label_key': 'curr_xaf', 'symbol': 'XAF'},
  {'label_key': 'curr_mad', 'symbol': 'MAD'},
  {'label_key': 'curr_dzd', 'symbol': 'DZD'},
  {'label_key': 'curr_tnd', 'symbol': 'DT'},
  {'label_key': 'curr_kmf', 'symbol': 'CF'},
  {'label_key': 'curr_djf', 'symbol': 'Fdj'},
  {'label_key': 'curr_rwf', 'symbol': 'RF'},
  {'label_key': 'curr_bif', 'symbol': 'FBu'},
  {'label_key': 'curr_xcd', 'symbol': 'EC\$'},
  {'label_key': 'curr_xpf', 'symbol': 'XPF'},
];

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'de';
  String _currencySymbol = '€';
  bool _useAmPm = false;
  String _sortOrder = 'a_z';

  // --- NEUE DESIGN-VARIABLEN ---
  Color? _primaryColor;
  Color? _tileColor;
  Color? _textColor;
  Color? _buttonColor;
  Color? _backgroundColor;
  Color? _shadowColor;
  List<Color> _customPalette = [];
  Map<String, Color> _categoryColors = {};
  List<String> _customCategories = [];

  // Pro-Screen Design-Overrides: { screenId: { elementKey: colorValueARGB32 } }
  // elementKey ist eines von: bg, primary, tile, text, button, shadow
  Map<String, Map<String, int>> _screenColorOverrides = {};
  
  double _fontSizeScale = 1.0;
  double _tileBorderRadius = 12.0;
  double _buttonHeight = 48.0;
  double _shadowBlur = 4.0;
  String _buttonAlignment = 'center';
  String _fontFamily = 'default';

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  String get currencySymbol => _currencySymbol;
  bool get useAmPm => _useAmPm;
  String get sortOrder => _sortOrder;

  // Getter für Design
  Color? get primaryColor => _primaryColor;
  Color? get tileColor => _tileColor;
  Color? get textColor => _textColor;
  Color? get buttonColor => _buttonColor;
  Color? get backgroundColor => _backgroundColor;
  Color? get shadowColor => _shadowColor;
  List<Color> get customPalette => _customPalette;
  Map<String, Color> get categoryColors => _categoryColors;
  List<String> get customCategories => _customCategories;
  Map<String, Map<String, int>> get screenColorOverrides => _screenColorOverrides;
  
  double get fontSizeScale => _fontSizeScale;
  double get tileBorderRadius => _tileBorderRadius;
  double get buttonHeight => _buttonHeight;
  double get shadowBlur => _shadowBlur;
  String get buttonAlignment => _buttonAlignment;
  String get fontFamily => _fontFamily;

  SettingsProvider() {
    loadSettings();
  }

  void _initCustomLicenses() {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        [getText(_languageCode, 'app_title')],
        '${getText(_languageCode, 'license_summary')}\n\n${getText(_languageCode, 'license_legalese')}',
      );
    });
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeString = prefs.getString('theme_mode');
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    _languageCode = prefs.getString('app_language') ?? 'de';
    _currencySymbol = prefs.getString('currency_symbol') ?? '€';
    _useAmPm = prefs.getBool('use_am_pm') ?? false;
    _sortOrder = prefs.getString('sort_order') ?? 'a_z';

    // Design Laden
    if (prefs.containsKey('design_primary_color')) _primaryColor = Color(prefs.getInt('design_primary_color')!);
    if (prefs.containsKey('design_tile_color')) _tileColor = Color(prefs.getInt('design_tile_color')!);
    if (prefs.containsKey('design_text_color')) _textColor = Color(prefs.getInt('design_text_color')!);
    if (prefs.containsKey('design_button_color')) _buttonColor = Color(prefs.getInt('design_button_color')!);
    if (prefs.containsKey('design_bg_color')) _backgroundColor = Color(prefs.getInt('design_bg_color')!);
    if (prefs.containsKey('design_shadow_color')) _shadowColor = Color(prefs.getInt('design_shadow_color')!);
    
    _fontSizeScale = prefs.getDouble('design_font_scale') ?? 1.0;
    _tileBorderRadius = prefs.getDouble('design_tile_radius') ?? 12.0;
    _buttonHeight = prefs.getDouble('design_button_height') ?? 48.0;
    _shadowBlur = prefs.getDouble('design_shadow_blur') ?? 4.0;
    _buttonAlignment = prefs.getString('design_button_align') ?? 'center';
    _fontFamily = prefs.getString('design_font_family') ?? 'default';

    if (prefs.containsKey('design_custom_palette')) {
      final List<dynamic> loaded = jsonDecode(prefs.getString('design_custom_palette')!);
      _customPalette = loaded.map((e) => Color(e as int)).toList();
    }
    
    if (prefs.containsKey('design_category_colors')) {
      final Map<String, dynamic> loadedMap = jsonDecode(prefs.getString('design_category_colors')!);
      _categoryColors = loadedMap.map((key, value) => MapEntry(key, Color(value as int)));
    }

    _customCategories = prefs.getStringList('design_custom_categories') ?? [];

    if (prefs.containsKey('design_screen_overrides')) {
      try {
        final Map<String, dynamic> loadedOverrides = jsonDecode(prefs.getString('design_screen_overrides')!);
        _screenColorOverrides = loadedOverrides.map((screenId, elementMap) {
          final Map<String, dynamic> inner = elementMap as Map<String, dynamic>;
          return MapEntry(screenId, inner.map((k, v) => MapEntry(k, v as int)));
        });
      } catch (_) {
        _screenColorOverrides = {};
      }
    }

    _initCustomLicenses();
    notifyListeners();
  }

  // --- DESIGN SETTER & LOGIK ---
  Future<void> setPrimaryColor(Color? color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    color == null ? prefs.remove('design_primary_color') : prefs.setInt('design_primary_color', color.toARGB32());
  }

  Future<void> setTileColor(Color? color) async {
    _tileColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    color == null ? prefs.remove('design_tile_color') : prefs.setInt('design_tile_color', color.toARGB32());
  }

  Future<void> setTextColor(Color? color) async {
    _textColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    color == null ? prefs.remove('design_text_color') : prefs.setInt('design_text_color', color.toARGB32());
  }

  Future<void> setButtonColor(Color? color) async {
    _buttonColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    color == null ? prefs.remove('design_button_color') : prefs.setInt('design_button_color', color.toARGB32());
  }

  Future<void> setBackgroundColor(Color? color) async {
    _backgroundColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    color == null ? prefs.remove('design_bg_color') : prefs.setInt('design_bg_color', color.toARGB32());
  }

  Future<void> setShadowColor(Color? color) async {
    _shadowColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    color == null ? prefs.remove('design_shadow_color') : prefs.setInt('design_shadow_color', color.toARGB32());
  }

  Future<void> addCustomColor(Color color) async {
    if (_customPalette.length < 10) {
      _customPalette.add(color);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('design_custom_palette', jsonEncode(_customPalette.map((c) => c.toARGB32()).toList()));
    }
  }

  Future<void> removeCustomColor(int index) async {
    if (index >= 0 && index < _customPalette.length) {
      _customPalette.removeAt(index);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('design_custom_palette', jsonEncode(_customPalette.map((c) => c.toARGB32()).toList()));
    }
  }

  Future<void> setCategoryColor(String categoryKey, Color? color) async {
    if (color == null) {
      _categoryColors.remove(categoryKey);
    } else {
      _categoryColors[categoryKey] = color;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('design_category_colors', jsonEncode(_categoryColors.map((k, v) => MapEntry(k, v.toARGB32()))));
  }

  Color? getCategoryColor(String categoryKey) {
    return _categoryColors[categoryKey];
  }

  Future<void> addCustomCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _customCategories.contains(trimmed)) return;
    _customCategories.add(trimmed);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('design_custom_categories', _customCategories);
  }

  Future<void> removeCustomCategory(String name) async {
    _customCategories.remove(name);
    _categoryColors.remove(name);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('design_custom_categories', _customCategories);
    prefs.setString('design_category_colors', jsonEncode(_categoryColors.map((k, v) => MapEntry(k, v.toARGB32()))));
  }

  // --- PRO-SCREEN DESIGN ---
  // screenId Beispiele: 'main', 'settings', 'add', 'detail', 'expiry'
  Future<void> setScreenColor(String screenId, String elementKey, Color? color) async {
    final screenMap = _screenColorOverrides.putIfAbsent(screenId, () => {});
    if (color == null) {
      screenMap.remove(elementKey);
      if (screenMap.isEmpty) _screenColorOverrides.remove(screenId);
    } else {
      screenMap[elementKey] = color.toARGB32();
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('design_screen_overrides', jsonEncode(_screenColorOverrides));
  }

  Color? getScreenColor(String screenId, String elementKey) {
    final value = _screenColorOverrides[screenId]?[elementKey];
    return value != null ? Color(value) : null;
  }

  Future<void> resetScreenDesign(String screenId) async {
    _screenColorOverrides.remove(screenId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('design_screen_overrides', jsonEncode(_screenColorOverrides));
  }

  // Prüft, ob mind. ein gespeichertes Gerät diese Kategorie verwendet.
  Future<bool> categoryHasEntries(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('gerate_liste');
    if (raw == null || raw.isEmpty) return false;
    try {
      final List<dynamic> liste = jsonDecode(raw);
      return liste.any((item) => (item as Map)['kategorie'] == categoryName);
    } catch (_) {
      return false;
    }
  }

  // Löscht eine eigene Kategorie nur, wenn kein Gerät sie noch verwendet.
  // Gibt true zurück, wenn gelöscht wurde, sonst false.
  Future<bool> tryRemoveCustomCategory(String name) async {
    if (await categoryHasEntries(name)) return false;
    await removeCustomCategory(name);
    return true;
  }

  Future<void> setFontSizeScale(double scale) async {
    _fontSizeScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('design_font_scale', scale);
  }

  Future<void> setTileBorderRadius(double radius) async {
    _tileBorderRadius = radius;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('design_tile_radius', radius);
  }

  Future<void> setButtonHeight(double height) async {
    _buttonHeight = height;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('design_button_height', height);
  }

  Future<void> setShadowBlur(double blur) async {
    _shadowBlur = blur;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('design_shadow_blur', blur);
  }

  Future<void> setButtonAlignment(String alignment) async {
    _buttonAlignment = alignment;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('design_button_align', alignment);
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('design_font_family', family);
  }

  Future<void> resetThemeToDefault() async {
    _primaryColor = null;
    _tileColor = null;
    _textColor = null;
    _buttonColor = null;
    _backgroundColor = null;
    _shadowColor = null;
    _fontSizeScale = 1.0;
    _tileBorderRadius = 12.0;
    _buttonHeight = 48.0;
    _shadowBlur = 4.0;
    _buttonAlignment = 'center';
    _fontFamily = 'default';
    _categoryColors.clear();
    _screenColorOverrides.clear();
    
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('design_screen_overrides');
    prefs.remove('design_primary_color');
    prefs.remove('design_tile_color');
    prefs.remove('design_text_color');
    prefs.remove('design_button_color');
    prefs.remove('design_bg_color');
    prefs.remove('design_shadow_color');
    prefs.remove('design_font_scale');
    prefs.remove('design_tile_radius');
    prefs.remove('design_button_height');
    prefs.remove('design_shadow_blur');
    prefs.remove('design_button_align');
    prefs.remove('design_font_family');
    prefs.remove('design_category_colors');
  }

  // --- HILFSFUNKTIONEN FÜR DAS UI ---
  // screenId ist optional: wird es übergeben, hat ein für diesen Screen
  // gespeicherter Override Vorrang vor dem globalen Design.
  Color getEffectiveBgColor(BuildContext context, {String? screenId}) {
    if (screenId != null) {
      final override = getScreenColor(screenId, 'bg');
      if (override != null) return override;
    }
    if (_backgroundColor != null) return _backgroundColor!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9);
  }

  Color getEffectiveAppBarColor(BuildContext context, {String? screenId}) {
    if (screenId != null) {
      final override = getScreenColor(screenId, 'primary');
      if (override != null) return override;
    }
    if (_primaryColor != null) return _primaryColor!;
    return getEffectiveBgColor(context, screenId: screenId);
  }

  Color getEffectiveButtonColor(BuildContext context, {String? screenId}) {
    if (screenId != null) {
      final override = getScreenColor(screenId, 'button');
      if (override != null) return override;
    }
    if (_buttonColor != null) return _buttonColor!;
    if (screenId != null) {
      final primaryOverride = getScreenColor(screenId, 'primary');
      if (primaryOverride != null) return primaryOverride;
    }
    return _primaryColor ?? Colors.blueAccent;
  }

  TextStyle getTextStyle(BuildContext context, {double baseSize = 14, FontWeight fontWeight = FontWeight.normal, Color? color, String? screenId}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color? screenOverride = screenId != null ? getScreenColor(screenId, 'text') : null;
    Color finalColor = color ?? screenOverride ?? _textColor ?? (isDark ? Colors.white : Colors.black87);
    
    return TextStyle(
      fontSize: baseSize * _fontSizeScale,
      fontWeight: fontWeight,
      color: finalColor,
      fontFamily: _fontFamily == 'default' ? null : _fontFamily,
    );
  }

  BoxDecoration getTileDecoration(BuildContext context, {Color? customTileColor, String? screenId}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTile = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final screenTileOverride = screenId != null ? getScreenColor(screenId, 'tile') : null;
    final screenShadowOverride = screenId != null ? getScreenColor(screenId, 'shadow') : null;
    
    return BoxDecoration(
      color: customTileColor ?? screenTileOverride ?? _tileColor ?? defaultTile,
      borderRadius: BorderRadius.circular(_tileBorderRadius),
      boxShadow: [
        if (!isDark) BoxShadow(color: (screenShadowOverride ?? _shadowColor ?? Colors.black).withValues(alpha: 0.05), blurRadius: _shadowBlur, offset: const Offset(0, 2)),
      ],
    );
  }
  // ------------------------------------

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    await prefs.setString('theme_mode', modeString);
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    _initCustomLicenses();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
  }

  Future<void> setUseAmPm(bool value) async {
    _useAmPm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_am_pm', value);
  }

  Future<void> setSortOrder(String order) async {
    _sortOrder = order;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_order', order);
  }

  Future<void> deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _themeMode = ThemeMode.system;
    _languageCode = 'de';
    _currencySymbol = '€';
    _useAmPm = false;
    _sortOrder = 'a_z';
    await resetThemeToDefault();
    _customPalette.clear();
    _customCategories.clear();
    _initCustomLicenses();
    notifyListeners();
  }

  void showTranslatedLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: getText(_languageCode, 'app_title'),
      applicationVersion: '1.0.0',
      applicationLegalese: getText(_languageCode, 'license_legalese'),
    );
  }
}

// --- HIER FOLGEN DIE UNANGETASTETEN ÜBERSETZUNGEN ---
const Map<String, Map<String, String>> translations = {
  'de': translationsDe,
  'en': translationsEn,
  'fr': translationsFr,
  'es': translationsEs,
};

String getText(String lang, String key) {
  return translations[lang]?[key] ?? translations['de']?[key] ?? key;
}

String localizeDuration(String? durationStr, String langCode) {
  if (durationStr == null || durationStr.isEmpty) return '-';
  if (durationStr == 'Unbekannt') return getText(langCode, 'unknown');

  return durationStr
      .replaceAll('Jahre', getText(langCode, 'jahre'))
      .replaceAll('Jahr', getText(langCode, 'jahr'))
      .replaceAll('Monate', getText(langCode, 'monate'))
      .replaceAll('Wochen', getText(langCode, 'wochen'));
}

// Formatiert eine Uhrzeit abhängig von Sprache und 12h/24h-Einstellung.
// 24h: "14:30 Uhr" (de) bzw. "14:30" (en/fr) – 12h: "02:30 PM"
String localizeTimeOfDay(int hour, int minute, String langCode, bool useAmPm) {
  final min = minute.toString().padLeft(2, '0');
  if (useAmPm) {
    int h = hour;
    final String period = h >= 12 ? getText(langCode, 'time_pm') : getText(langCode, 'time_am');
    if (h == 0) {
      h = 12;
    } else if (h > 12) {
      h -= 12;
    }
    return '${h.toString().padLeft(2, '0')}:$min $period';
  }
  return '${hour.toString().padLeft(2, '0')}:$min${getText(langCode, 'clock')}';
}

String localizeReminderDate(DateTime dt, String langCode, bool useAmPm) {
  final t = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final j = dt.year.toString();

  final timeString = localizeTimeOfDay(dt.hour, dt.minute, langCode, useAmPm);

  return '${getText(langCode, 'on_date')}$t.$m.$j${getText(langCode, 'at_time')}$timeString';
}