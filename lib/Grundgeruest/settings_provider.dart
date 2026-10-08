import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  'de': {
    'today': 'Heute',
    'day_singular': 'Tag',
    'days_plural': 'Tage',
    'week_singular': 'Woche',
    'weeks_plural': 'Wochen',
    'month_singular': 'Monat',
    'months_plural': 'Monate',
    'year_singular': 'Jahr',
    'years_plural': 'Jahre',
    'expired_suffix': ' abgelaufen',
    'expires_today': 'Läuft heute ab',
    'expired_today': 'Heute abgelaufen',
    
    'select_language': 'Sprache auswählen',
    'ok': 'OK',
    'expired_since': 'Seit ',
    'expired_day_singular': ' Tag abgelaufen',
    'expired_day_plural': ' Tagen abgelaufen',
    'active': 'Aktiv',

    'app_title': 'Garantie Manager',
    'search_hint': 'Name, Kaufdatum und Händler',
    'store_hint': 'Wo gekauft?...',
    'all': 'Alle',
    'electronics': 'Elektronik',
    'clothes': 'Kleidung',
    'furniture': 'Möbel',
    'household': 'Haushalt',
    'others': 'Sonstiges',
    'expired_cat': 'Abgelaufen',

    'no_devices': 'Noch keine Einträge vorhanden',
    'no_devices_desc': 'Füge deinen ersten Eintrag hinzu, um Kassenbons zu speichern und Garantiefristen nicht zu verpassen.',
    'no_search_results': 'Keine Einträge für diesen Filter gefunden.',

    'bought_at': 'Gekauft bei',
    'buy_date': 'Kaufdatum',
    'expiry': 'Ablauf',
    'reminder': 'Erinnerung',

    'settings': 'Einstellungen',
    'product_name': 'Eintragsname',
    'category': 'Kategorie',
    'buy_details': 'Kaufdetails',
    'price': 'Preis',
    'warranty_duration': 'Garantiedauer',
    'own_duration': 'Eigene Dauer',
    'duration': 'Dauer',
    'unit': 'Einheit',
    'expiry_date': 'Ablaufdatum',
    'set_reminder': 'Erinnerung',
    'never': 'Nie',
    'photos': 'Fotos',
    'save': 'Speichern',
    'camera': 'Kamera',
    'gallery': 'Galerie',
    'details': 'Produkt-Details',
    'unknown': 'Unbekannt',

    'delete_device_title': 'Eintrag löschen?',
    'delete_device_desc': 'Möchtest du diesen Eintrag wirklich dauerhaft löschen?',
    'cancel': 'Abbrechen',
    'delete': 'Löschen',
    'edit': 'Bearbeiten',

    'allow': 'Zulassen',
    'notif_perm_title': 'Benachrichtigungen erlauben',
    'notif_perm_desc': 'Bitte erlaube Benachrichtigungen, damit wir dich an deine eingestellten Erinnerungen erinnern können.',
    
    'time_format_12h': '12-Stunden-Format',
    'turn_on_light_mode': 'Hellen Modus aktivieren',
    'turn_on_dark_mode': 'Dunklen Modus aktivieren',
    'switch_to_12h': '24h-Format',
    'switch_to_24h': '12h-Format',

    'past_time_error': 'Die Uhrzeit darf nicht in der Vergangenheit liegen!',

    'error_max_photos': 'Du kannst maximal 4 Bilder hinzufügen!',
    'error_name_missing': 'Eintragsname fehlt.',
    'error_name_used': 'Dieser Name wird bereits verwendet.',
    'error_price_invalid': 'Der Preis muss 1 oder höher sein.',
    'error_duration_invalid': 'Die Garantie muss länger als 1 Woche sein.',
    'error_store_missing': 'Gekauft bei fehlt.',
    'error_photo_missing': 'Mindestens 1 Foto wird benötigt, um spätere Garantiefälle mit einem Kassenbon zu belegen.',
    'demo_product': 'Demo-Produkt',
    'demo_store': 'MUSTERLADEN',
    'export_error': 'Export fehlgeschlagen',
    'error_loading_file': 'Fehler beim Laden der Datei.',

    'notif_title': 'Garantie läuft bald ab: ',
    'notif_body': 'Die Garantie für diesen Eintrag läuft am ',
    'notif_body_end': ' ab!',

    'expiry_title': 'Ablaufkalender',
    'no_reminders': 'Keine Erinnerungen eingetragen.',
    'expired': 'Abgelaufen',
    'days_left': 'Noch ',
    'days': ' Tage',
    'deleted_success': ' wurde gelöscht.',

    'appearance': 'Darstellung & Format',
    'dark_mode': 'Dunkles Design',
    'dark_mode_desc': 'Schont die Augen bei Dunkelheit',
    'language': 'Sprache',
    'currency': 'Währung',
    'sort_by': 'Sortierung der Hauptliste',
    'sort_a_z': 'Alphabetisch (A bis Z)',
    'sort_z_a': 'Alphabetisch (Z bis A)',
    'sort_newest': 'Neuestes Kaufdatum zuerst',
    'sort_oldest': 'Ältestes Kaufdatum zuerst',
    'sort_expiry': 'Ablaufdatum (demnächst zuerst)',

    'data_management': 'Datenverwaltung & Backup',
    'export_data': 'Daten exportieren (Backup)',
    'import_data': 'Daten importieren',
    'export_success': 'Backup wurde erfolgreich exportiert!',
    'import_success': 'Backup wurde erfolgreich importiert!',
    'import_error': 'Fehler beim Importieren der Daten. Ist die ZIP-Datei gültig?',
    'delete_all_data': 'Alle Daten löschen',
    'delete_all_title': 'Alle Daten unwiderruflich löschen?',
    'delete_all_desc': 'Dies entfernt alle lokal gespeicherten Einträge, Einstellungen und Belege. Diese Aktion kann nicht rückgängig gemacht werden!',
    'delete_all_confirm': 'Alles löschen',
    'all_data_deleted': 'Alle Daten wurden gelöscht.',
    
    'export_method_desc': 'Wie möchtest du das Backup exportieren?',
    'export_share': 'Teilen / Senden',
    'export_save': 'In Speicher sichern',
    'import_desc': 'Um Daten kabellos von einem anderen Gerät zu empfangen, sende das Backup (ZIP) z.B. per Quick Share oder E-Mail an dieses Gerät und speichere es.\n\nWähle das Backup anschließend hier aus.',
    'import_select_file': 'Datei auswählen',
    'backup_save_title': 'Backup speichern',
    'backup_share_text': 'Backup Warranty Manager',

    'info': 'Info & Rechtliches',
    'app_version': 'Version',
    'update_log': 'Update-Verlauf',
    'update_log_title': 'Was ist neu?',
    'update_log_desc': 'September 2026\n• Veröffentlichung der App und alle geplanten Funktionen wurden hinzugefügt.',
    'privacy_policy': 'Datenschutzerklärung',
    'privacy_policy_title': 'Datenschutzerklärung',
    'privacy_policy_text': 'Datenschutzerklärung\n\n1. Speicherung von Daten\nAlle von Ihnen eingegebenen Daten werden ausschließlich lokal auf Ihrem Gerät gespeichert.\n\n2. Kamerazugriff & Fotos\nDie App benötigt Zugriff auf Kamera und Galerie, um Fotos von Kassenbons lokal auf Ihrem Gerät zu sichern.',
    'imprint': 'Impressum & Anbieter',
    'imprint_title': 'Impressum',
    'imprint_text': 'Dienstanbieter:\nPeter Weissenborn\nE-Mail: support.warrantymanager@gmail.com\n\nVerantwortlich für den Inhalt gemäß DSGVO.',
    'licenses': 'Open-Source-Lizenzen',
    
    'license_title': 'Software-Lizenzen',
    'license_details': 'Lizenzdetails & Drittanbieter-Bibliotheken',
    'license_summary': 'Diese Anwendung nutzt Open-Source-Komponenten des Flutter Frameworks sowie dazugehörige Bibliotheken.',
    'license_legalese': '© 2026 Peter Weissenborn. Alle Rechte vorbehalten.',
    'license_view_all': 'Alle Lizenzen anzeigen',
    'license_packages': 'Verwendete Pakete',
    'no_licenses_found': 'Keine Lizenzinformationen gefunden.',

    'tutorial_restart': 'Tutorial erneut ansehen',
    'tut_skip': 'Überspringen',

    'tut_search_title': 'Suchen & Filtern',
    'tut_search_desc': 'Benutze oben die Suchleisten und Kategorien, um deine Einträge schneller zu finden.',
    'tut_add_title': 'Eintrag hinzufügen',
    'tut_add_desc': 'Drücke hier, um deinen ersten Eintrag hinzuzufügen.',
    'tut_name_desc': 'Gib hier den Namen des Eintrags ein und wähle die passende Kategorie aus.',
    'tut_kauf_desc': 'Trage hier den Händler und den Kaufpreis ein.',
    'tut_garantie_desc': 'Trage hier das Kaufdatum und die Garantiedauer ein.',
    'tut_timer_desc': 'Stelle ein, wie lange vor Ablauf der Garantie du benachrichtigt werden möchtest.',
    'tut_foto_desc': 'Füge bis zu 4 Fotos des Kassenbons oder des Produkts hinzu.',
    'tut_save_desc': 'Klicke hier, um den Eintrag jetzt anzulegen!',
    'tut_demo_title': 'Dein neuer Eintrag!',
    'tut_demo_desc': 'Tippe auf die Kachel, um die Detailansicht mit deinen angegebenen Informationen zu öffnen.\nDu kannst außerdem die Fotos hier in der Vollbildansicht einsehen und diese Informationen als PDF drucken.',
    'tut_click_details_title': 'Details anzeigen',
    'tut_click_details_desc': 'Hier drauf klicken, um die Details anzuzeigen.',
    'tut_detail_title': 'Detailansicht',
    'tut_detail_info_desc': 'Hier siehst du alle Informationen zu deinem Eintrag sowie deine hinterlegten Kassenbon-Fotos.',
    'tut_download_title': 'PDF Download',
    'tut_download_desc': 'Lade hier die Garantie-Informationen als PDF herunter.',
    'tut_print_title': 'Drucken',
    'tut_print_desc': 'Drucke das PDF direkt über dein Gerät aus.',
    'tut_back_title': 'Zurück zum Hauptbildschirm',
    'tut_back_desc': 'Klicke auf den Pfeil, um zurück zum Hauptbildschirm zu gelangen.',
    'tut_edit_title': 'Eintrag bearbeiten',
    'tut_edit_desc': 'Über dieses Stift-Symbol kannst du die Daten deines Eintrags jederzeit anpassen.',
    'tut_del_title': 'Eintrag löschen',
    'tut_del_desc': 'Klicke auf das Mülleimer-Symbol, um den Eintrag endgültig zu entfernen.',
    'tut_notif_title': 'Garantie-Ablauf',
    'tut_notif_desc': 'Hier siehst du, welche Garantien demnächst ablaufen.',
    'tut_bell_title': 'Ablaufübersicht (Glocke)',
    'tut_bell_desc': 'Klicke auf die Glocke, um zur Ablaufübersicht zu gelangen.',
    'tut_exp_active_title': 'Aktive Garantien',
    'tut_exp_active_desc': 'Hier findest du alle Garantien, die noch nicht abgelaufen sind.',
    'tut_exp_expired_title': 'Abgelaufene Garantien',
    'tut_exp_expired_desc': 'Hier werden alle abgelaufenen Einträge gesammelt.',
    'tut_exp_entry_title': 'Garantie-Eintrag',
    'tut_exp_entry_desc': 'Hier siehst du den Status und die verbleibenden Tage der Garantie.',
    'tut_set_title': 'Einstellungen',
    'tut_set_desc': 'Hier kannst du Einstellungen wie Sprache und Design anpassen.',
    'tut_set_lang_title': 'Spracheinstellungen',
    'tut_set_lang_desc': 'Wechsle die Sprache der App nach deinen Wünschen.',
    'tut_set_ver_title': 'App-Version',
    'tut_set_ver_desc': 'Hier siehst du deine aktuelle Version und das Update-Log.',
    'tut_set_end_title': 'Tutorial abgeschlossen!',
    'tut_set_end_desc': 'Du kennst nun alle Funktionen. Viel Spaß mit dem Garantie Manager!',
    'tut_fin_title': 'Tutorial beendet!',
    'tut_fin_desc': 'Tippe hier oder auf das Icon, um das Tutorial abzuschließen und deine Garantien zu verwalten!',
    'tut_welcome_title': 'Willkommen beim Garantie Manager!',
    'tut_welcome_desc': 'Mit dem Button „Überspringen“ oben rechts kannst du das Tutorial jederzeit überspringen.\nUm einen nächsten Schritt zu gehen, tippe auf die aufgehellten Bereiche!',
    'tut_welcome_start': 'Los geht\'s',

    'wochen': 'Wochen',
    'monate': 'Monate',
    'jahre': 'Jahre',
    'jahr': 'Jahr',
    'on_date': 'am ',
    'at_time': ' um ',
    'clock': ' Uhr',
    'time_am': 'AM',
    'time_pm': 'PM',
    'time_picker_dial_help': 'UHRZEIT AUSWÄHLEN',
    'time_picker_input_help': 'UHRZEIT EINGEBEN',
    'time_picker_hour': 'Stunde',
    'time_picker_minute': 'Minute',
    'time_picker_dial_mode': 'Zur Zifferblattauswahl wechseln',
    'time_picker_input_mode': 'Zur Texteingabe wechseln',
    'time_picker_invalid': 'Ungültige Uhrzeit',
    'time_picker_hour_announce': 'Stunden auswählen',
    'time_picker_minute_announce': 'Minuten auswählen',

    'select_empty': 'Keine Angabe',
    'remarks': 'Bemerkung',
    'remarks_hint': 'Notizen...',
    'photo_info_text': 'Mindestens 1 Foto wird benötigt, um spätere Garantiefälle mit einem Kassenbon zu belegen.',

    'curr_eur': 'Euro',
    'curr_chf': 'Schweizer Franken',
    'curr_usd': 'US-Dollar',
    'curr_cad': 'Kanadischer Dollar',
    'curr_aud': 'Australischer Dollar',
    'curr_nzd': 'Neuseeländischer Dollar',
    'curr_gbp': 'Britisches Pfund',
    'curr_mxn': 'Mexikanischer Peso',
    'curr_ars': 'Argentinischer Peso',
    'curr_clp': 'Chilenischer Peso',
    'curr_cop': 'Kolumbianischer Peso',
    'curr_pen': 'Peruanischer Sol',
    'curr_uyu': 'Uruguayischer Peso',
    'curr_pyg': 'Paraguayischer Guaraní',
    'curr_bob': 'Bolivianischer Boliviano',
    'curr_brl': 'Brasilianischer Real',
    'curr_crc': 'Costa-Rica-Colón',
    'curr_gtq': 'Guatemaltekischer Quetzal',
    'curr_hnl': 'Honduranische Lempira',
    'curr_nio': 'Nicaraguanischer Córdoba',
    'curr_dop': 'Dominikanischer Peso',
    'curr_htg': 'Haitianische Gourde',
    'curr_cup': 'Kubanischer Peso',
    'curr_xof': 'Westafrikanischer CFA-Franc',
    'curr_xaf': 'Zentralafrikanischer CFA-Franc',
    'curr_mad': 'Marokkanischer Dirham',
    'curr_dzd': 'Algerischer Dinar',
    'curr_tnd': 'Tunesischer Dinar',
    'curr_kmf': 'Komoren-Franc',
    'curr_djf': 'Dschibutischer Franc',
    'curr_rwf': 'Ruanda-Franc',
    'curr_bif': 'Burundischer Franc',
    'curr_xcd': 'Ostkaribischer Dollar',
    'curr_xpf': 'CFP-Franc',
  },
  'en': {
    'today': 'Today',
    'day_singular': 'day',
    'days_plural': 'days',
    'week_singular': 'week',
    'weeks_plural': 'weeks',
    'month_singular': 'month',
    'months_plural': 'months',
    'year_singular': 'year',
    'years_plural': 'years',
    'expired_suffix': ' ago',
    'expires_today': 'Expires today',
    'expired_today': 'Expired today',
    
    'select_language': 'Select language',
    'ok': 'OK',
    'expired_since': 'Expired for ',
    'expired_day_singular': ' day',
    'expired_day_plural': ' days',
    'active': 'Active',

    'app_title': 'Warranty Manager',
    'search_hint': 'name, purchase date and store',
    'store_hint': 'Where bought?...',
    'all': 'All',
    'electronics': 'Electronics',
    'clothes': 'Clothing',
    'furniture': 'Furniture',
    'household': 'Household',
    'others': 'Other',
    'expired_cat': 'Expired',

    'no_devices': 'No entries available yet',
    'no_devices_desc': 'Add your first entry to save receipts and never miss a warranty deadline.',
    'no_search_results': 'No entries found for this filter.',

    'bought_at': 'Bought at',
    'buy_date': 'Purchase date',
    'expiry': 'Expiry',
    'reminder': 'Reminder',

    'settings': 'Settings',
    'product_name': 'Entry name',
    'category': 'Category',
    'buy_details': 'Purchase details',
    'price': 'Price',
    'warranty_duration': 'Warranty duration',
    'own_duration': 'Custom duration',
    'duration': 'Duration',
    'unit': 'Unit',
    'expiry_date': 'Expiry date',
    'set_reminder': 'Reminder',
    'never': 'Never',
    'photos': 'Photos',
    'save': 'Save',
    'camera': 'Camera',
    'gallery': 'Gallery',
    'details': 'Product details',
    'unknown': 'Unknown',

    'delete_device_title': 'Delete entry?',
    'delete_device_desc': 'Do you really want to permanently delete this entry?',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',

    'allow': 'Allow',
    'notif_perm_title': 'Allow notifications',
    'notif_perm_desc': 'Please allow notifications so we can remind you of your scheduled reminders.',
    
    'time_format_12h': '12-hour format',
    'turn_on_light_mode': 'Enable light mode',
    'turn_on_dark_mode': 'Enable dark mode',
    'switch_to_12h': '24h format',
    'switch_to_24h': '12h format',

    'past_time_error': 'The time cannot be in the past!',

    'export_error': 'Export failed',
    'error_loading_file': 'Error loading file.',
    'error_max_photos': 'You can add a maximum of 4 photos!',
    'error_name_missing': 'Entry name is missing.',
    'error_name_used': 'This entry name is already in use.',
    'error_price_invalid': 'Price must be 1 or higher.',
    'error_duration_invalid': 'The warranty must be longer than 1 week.',
    'error_store_missing': 'Store is missing.',
    'error_photo_missing': 'At least 1 photo is required to prove warranty claims later with a receipt.',
    'demo_product': 'Demo Product',
    'demo_store': 'SAMPLE STORE',

    'notif_title': 'Warranty expires soon: ',
    'notif_body': 'The warranty for this entry expires on ',
    'notif_body_end': '!',

    'expiry_title': 'Expiry Calendar',
    'no_reminders': 'No reminders set.',
    'expired': 'Expired',
    'days_left': '',
    'days': ' days left',
    'deleted_success': ' was deleted.',

    'appearance': 'Appearance & Format',
    'dark_mode': 'Dark Theme',
    'dark_mode_desc': 'Easy on the eyes in the dark',
    'language': 'Language',
    'currency': 'Currency',
    'sort_by': 'Main List Sorting',
    'sort_a_z': 'Alphabetical (A to Z)',
    'sort_z_a': 'Alphabetical (Z to A)',
    'sort_newest': 'Newest purchase date first',
    'sort_oldest': 'Oldest purchase date first',
    'sort_expiry': 'Expiry date (soonest first)',

    'data_management': 'Data Management & Backup',
    'export_data': 'Export Data (Backup)',
    'import_data': 'Import Data',
    'export_success': 'Backup exported successfully!',
    'import_success': 'Backup imported successfully!',
    'import_error': 'Error importing data. Is the ZIP file valid?',
    'delete_all_data': 'Delete All Data',
    'delete_all_title': 'Permanently delete all data?',
    'delete_all_desc': 'This will remove all locally stored entries, settings, and receipts. This action cannot be undone!',
    'delete_all_confirm': 'Delete Everything',
    'all_data_deleted': 'All data has been deleted.',
    
    'export_method_desc': 'How would you like to export the backup?',
    'export_share': 'Share / Send',
    'export_save': 'Save to storage',
    'import_desc': 'To receive data wirelessly from another device, send the backup (ZIP) via Quick Share, or email to this device and save it.\n\nThen select the backup here.',
    'import_select_file': 'Select file',
    'backup_save_title': 'Save backup',
    'backup_share_text': 'Backup Warranty Manager',

    'info': 'Info & Legal',
    'app_version': 'Version',
    'update_log': 'Update Log',
    'update_log_title': 'What\'s new?',
    'update_log_desc': 'September 2026\n• App release and all planned features have been added.',
    'privacy_policy': 'Privacy Policy',
    'privacy_policy_title': 'Privacy Policy',
    'privacy_policy_text': 'Privacy Policy\n\n1. Data Storage\nAll data entered by you is stored exclusively locally on your device.\n\n2. Camera & Photo Access\nThe app requires access to your camera and gallery to save receipt photos locally.',
    'imprint': 'Imprint & Provider',
    'imprint_title': 'Imprint',
    'imprint_text': 'Service Provider:\nPeter Weissenborn\nEmail: support.warrantymanager@gmail.com\n\nResponsible for content in accordance with GDPR.',
    'licenses': 'Open Source Licenses',

    'license_title': 'Software Licenses',
    'license_details': 'License details & third-party libraries',
    'license_summary': 'This application uses open source components from the Flutter framework and associated packages.',
    'license_legalese': '© 2026 Peter Weissenborn. All rights reserved.',
    'license_view_all': 'View all licenses',
    'license_packages': 'Packages Used',
    'no_licenses_found': 'No license info found.',

    'tutorial_restart': 'Watch tutorial again',
    'tut_skip': 'Skip',

    'tut_search_title': 'Search & Filter',
    'tut_search_desc': 'Use the search bars and categories above to find your entries faster.',
    'tut_add_title': 'Add entry',
    'tut_add_desc': 'Press here to add your first entry.',
    'tut_name_desc': 'Enter the name of the entry here and choose the appropriate category.',
    'tut_kauf_desc': 'Enter the retailer and purchase price here.',
    'tut_garantie_desc': 'Enter the purchase date and warranty duration here.',
    'tut_timer_desc': 'Set how long before the warranty expires you want to be notified.',
    'tut_foto_desc': 'Add up to 4 photos of the receipt or the product.',
    'tut_save_desc': 'Click here to create the entry now!',
    'tut_demo_title': 'Your new entry!',
    'tut_demo_desc': 'Tap on the tile to open the detailed view with your provided information.\nYou can also view the photos in full screen here and print this information as a PDF.',
    'tut_click_details_title': 'View Details',
    'tut_click_details_desc': 'Click here to view the details.',
    'tut_detail_title': 'Details View',
    'tut_detail_info_desc': 'Here you can see all information about your entry as well as your stored receipt photos.',
    'tut_download_title': 'PDF Download',
    'tut_download_desc': 'Download your warranty information as a PDF here.',
    'tut_print_title': 'Print',
    'tut_print_desc': 'Print the PDF directly from your device.',
    'tut_back_title': 'Back to main screen',
    'tut_back_desc': 'Click the arrow to return to the main screen.',
    'tut_edit_title': 'Edit entry',
    'tut_edit_desc': 'You can adjust your entry\'s data at any time using this pencil icon.',
    'tut_del_title': 'Delete entry',
    'tut_del_desc': 'Click on the trash can icon to permanently remove the entry.',
    'tut_notif_title': 'Warranty Expiry',
    'tut_notif_desc': 'Here you can see which warranties are expiring soon.',
    'tut_bell_title': 'Expiry Overview (Bell)',
    'tut_bell_desc': 'Click on the bell to go to the expiry overview.',
    'tut_exp_active_title': 'Active Warranties',
    'tut_exp_active_desc': 'Here you will find all warranties that have not yet expired.',
    'tut_exp_expired_title': 'Expired Warranties',
    'tut_exp_expired_desc': 'All expired entries are collected here.',
    'tut_exp_entry_title': 'Warranty entry',
    'tut_exp_entry_desc': 'Here you can see the status and remaining days of the warranty.',
    'tut_set_title': 'Settings',
    'tut_set_desc': 'Here you can adjust settings like language and theme.',
    'tut_set_lang_title': 'Language Settings',
    'tut_set_lang_desc': 'Change the app language to your preference.',
    'tut_set_ver_title': 'App Version',
    'tut_set_ver_desc': 'View your current version and update log here.',
    'tut_set_end_title': 'Tutorial Finished!',
    'tut_set_end_desc': 'You now know all features. Have fun using Warranty Manager!',
    'tut_fin_title': 'Tutorial finished!',
    'tut_fin_desc': 'Tap here or on the icon to finish the tutorial and manage your warranties!',
    'tut_welcome_title': 'Welcome to Warranty Manager!',
    'tut_welcome_desc': 'Use the “Skip” button at the top right to skip the tutorial at any time.\nTo move on to the next step, tap the highlighted areas!',
    'tut_welcome_start': 'Let\'s go',

    'wochen': 'Weeks',
    'monate': 'Months',
    'jahre': 'Years',
    'jahr': 'Year',
    'on_date': 'on ',
    'at_time': ' at ',
    'clock': '',
    'time_am': 'AM',
    'time_pm': 'PM',
    'time_picker_dial_help': 'SELECT TIME',
    'time_picker_input_help': 'ENTER TIME',
    'time_picker_hour': 'Hour',
    'time_picker_minute': 'Minute',
    'time_picker_dial_mode': 'Switch to dial picker mode',
    'time_picker_input_mode': 'Switch to text input mode',
    'time_picker_invalid': 'Invalid time',
    'time_picker_hour_announce': 'Select hours',
    'time_picker_minute_announce': 'Select minutes',

    'select_empty': 'Not specified',
    'remarks': 'Remarks',
    'remarks_hint': 'Notes...',
    'photo_info_text': 'At least 1 photo is required to prove warranty claims later with a receipt.',

    'curr_eur': 'Euro',
    'curr_chf': 'Swiss Franc',
    'curr_usd': 'US Dollar',
    'curr_cad': 'Canadian Dollar',
    'curr_aud': 'Australian Dollar',
    'curr_nzd': 'New Zealand Dollar',
    'curr_gbp': 'British Pound',
    'curr_mxn': 'Mexican Peso',
    'curr_ars': 'Argentine Peso',
    'curr_clp': 'Chilean Peso',
    'curr_cop': 'Colombian Peso',
    'curr_pen': 'Peruan Sol',
    'curr_uyu': 'Uruguayan Peso',
    'curr_pyg': 'Paraguayan Guaraní',
    'curr_bob': 'Bolivian Boliviano',
    'curr_brl': 'Brazilian Real',
    'curr_crc': 'Costa Rican Colón',
    'curr_gtq': 'Guatemalan Quetzal',
    'curr_hnl': 'Honduran Lempira',
    'curr_nio': 'Nicaraguan Córdoba',
    'curr_dop': 'Dominican Peso',
    'curr_htg': 'Haitian Gourde',
    'curr_cup': 'Cuban Peso',
    'curr_xof': 'West African CFA Franc',
    'curr_xaf': 'Central African CFA Franc',
    'curr_mad': 'Moroccan Dirham',
    'curr_dzd': 'Algerian Dinar',
    'curr_tnd': 'Tunisian Dinar',
    'curr_kmf': 'Comorian Franc',
    'curr_djf': 'Djiboutian Franc',
    'curr_rwf': 'Rwandan Franc',
    'curr_bif': 'Burundian Franc',
    'curr_xcd': 'East Caribbean Dollar',
    'curr_xpf': 'CFP Franc',
  },
  'fr': {
    'today': 'Aujourd\'hui',
    'day_singular': 'jour',
    'days_plural': 'jours',
    'week_singular': 'semaine',
    'weeks_plural': 'semaines',
    'month_singular': 'mois',
    'months_plural': 'mois',
    'year_singular': 'an',
    'years_plural': 'ans',
    'expired_suffix': '',
    'expires_today': 'Expire aujourd\'hui',
    'expired_today': 'Expiré aujourd\'hui',
    
    'select_language': 'Choisir la langue',
    'ok': 'OK',
    'expired_since': 'Expiré depuis ',
    'expired_day_singular': ' jour',
    'expired_day_plural': ' jours',
    'active': 'Actif',

    'app_title': 'Gestionnaire de garantie',
    'search_hint': 'nom, date d\'achat et magasin...',
    'store_hint': 'Où acheté ?...',
    'all': 'Tous',
    'electronics': 'Électronique',
    'clothes': 'Vêtements',
    'furniture': 'Meubles',
    'household': 'Ménage',
    'others': 'Autres',
    'expired_cat': 'Expiré',

    'no_devices': 'Aucune entrée pour le moment',
    'no_devices_desc': 'Ajoutez votre première entrée pour sauvegarder vos reçus et ne manquer aucun délai de garantie.',
    'no_search_results': 'Aucune entrée trouvée pour ce filtre.',

    'bought_at': 'Acheté chez',
    'buy_date': 'Date d\'achat',
    'expiry': 'Expiration',
    'reminder': 'Rappel',

    'settings': 'Paramètres',
    'product_name': 'Nom de l\'entrée',
    'category': 'Catégorie',
    'buy_details': 'Détails d\'achat',
    'price': 'Prix',
    'warranty_duration': 'Durée de la garantie',
    'own_duration': 'Durée personnalisée',
    'duration': 'Durée',
    'unit': 'Unité',
    'expiry_date': 'Date d\'expiration',
    'set_reminder': 'Rappel',
    'never': 'Jamais',
    'photos': 'Photos',
    'save': 'Enregistrer',
    'camera': 'Appareil photo',
    'gallery': 'Galerie',
    'details': 'Détails du produit',
    'unknown': 'Inconnu',

    'delete_device_title': 'Supprimer l\'entrée ?',
    'delete_device_desc': 'Voulez-vous vraiment supprimer définitivement cette entrée ?',
    'cancel': 'Annuler',
    'delete': 'Supprimer',
    'edit': 'Modifier',

    'allow': 'Autoriser',
    'notif_perm_title': 'Autoriser les notifications',
    'notif_perm_desc': 'Veuillez autoriser les notifications afin que nous puissions vous rappeler vos échéances.',
    
    'time_format_12h': 'Format 12 heures',
    'turn_on_light_mode': 'Activer le mode clair',
    'turn_on_dark_mode': 'Activer le mode sombre',
    'switch_to_12h': 'Format 24h',
    'switch_to_24h': 'Format 12h',

    'past_time_error': 'L\'heure ne peut pas être dans le passé !',

    'export_error': 'Échec de l\'exportation',
    'error_loading_file': 'Erreur lors du chargement du fichier.',
    'error_max_photos': 'Vous pouvez ajouter un maximum de 4 photos !',
    'error_name_missing': 'Le nom de l\'entrée est manquant.',
    'error_name_used': 'Ce nom d\'entrée est déjà utilisé.',
    'error_price_invalid': 'Le prix doit être égal ou supérieur à 1.',
    'error_duration_invalid': 'La garantie doit être supérieure à 1 semaine.',
    'error_store_missing': 'Le magasin est manquant.',
    'error_photo_missing': 'Au moins 1 photo est requise pour prouver les demandes de garantie ultérieurement avec un reçu.',
    'demo_product': 'Produit Démo',
    'demo_store': 'MAGASIN TEMPOREL',

    'notif_title': 'La garantie expire bientôt : ',
    'notif_body': 'La garantie pour cette entrée expire le ',
    'notif_body_end': ' !',

    'expiry_title': 'Calendrier d\'expiration',
    'no_reminders': 'Aucun rappel défini.',
    'expired': 'Expiré',
    'days_left': 'Encore ',
    'days': ' jours',
    'deleted_success': ' a été supprimé.',

    'appearance': 'Apparence & Format',
    'dark_mode': 'Thème sombre',
    'dark_mode_desc': 'Soulage les yeux dans l\'obscurité',
    'language': 'Langue',
    'currency': 'Devise',
    'sort_by': 'Tri de la liste principale',
    'sort_a_z': 'Alphabétique (De A à Z)',
    'sort_z_a': 'Alphabétique (De Z à A)',
    'sort_newest': 'Date d\'achat récente en premier',
    'sort_oldest': 'Date d\'achat ancienne en premier',
    'sort_expiry': 'Date d\'expiration (prochaine en premier)',

    'data_management': 'Gestion des données & Sauvegarde',
    'export_data': 'Exporter les données (Sauvegarde)',
    'import_data': 'Importer des données',
    'export_success': 'Sauvegarde exportée avec succès !',
    'import_success': 'Sauvegarde importée avec succès !',
    'import_error': 'Erreur lors de l\'importation des données. Le fichier ZIP est-il valide ?',
    'delete_all_data': 'Supprimer toutes les données',
    'delete_all_title': 'Supprimer définitivement toutes les données ?',
    'delete_all_desc': 'Cela supprimera toutes les entrées, paramètres et reçus stockés localement. Cette action est irréversible !',
    'delete_all_confirm': 'Tout supprimer',
    'all_data_deleted': 'Toutes les données ont été supprimées.',

    'export_method_desc': 'Comment souhaitez-vous exporter la sauvegarde ?',
    'export_share': 'Partager / Envoyer',
    'export_save': 'Enregistrer dans le stockage',
    'import_desc': 'Pour recevoir des données sans fil d\'un autre appareil, envoyez la sauvegarde (ZIP) via Quick Share ou par e-mail à cet appareil et enregistrez-la.\n\nSélectionnez ensuite la sauvegarde ici.',
    'import_select_file': 'Sélectionner un fichier',
    'backup_save_title': 'Enregistrer la sauvegarde',
    'backup_share_text': 'Backup Warranty Manager',

    'info': 'Info & Légal',
    'app_version': 'Version',
    'update_log': 'Historique des mises à jour',
    'update_log_title': 'Quoi de neuf ?',
    'update_log_desc': 'Septembre 2026\n• Lancement de l\'application et toutes les fonctionnalités prévues ont été ajoutées.',
    'privacy_policy': 'Politique de confidentialité',
    'privacy_policy_title': 'Politique de confidentialité',
    'privacy_policy_text': 'Politique de confidentialité\n\n1. Stockage des données\nToutes les données saisies sont stockées exclusivement en local sur votre appareil.\n\n2. Accès appareil photo & photos\nL\'application nécessite l\'accès à l\'appareil photo et à la galerie pour enregistrer les reçus localement.',
    'imprint': 'Mentions légales & Prestataire',
    'imprint_title': 'Mentions légales',
    'imprint_text': 'Prestataire de services :\nPeter Weissenborn\nE-mail : support.warrantymanager@gmail.com\n\nResponsable du contenu conformément au RGPD.',
    'licenses': 'Licences open source',

    'license_title': 'Licences de logiciel',
    'license_details': 'Détails des licences & bibliothèques tierces',
    'license_summary': 'Cette application utilise des composants open source du framework Flutter et des paquets associés.',
    'license_legalese': '© 2026 Peter Weissenborn. Tous droits réservés.',
    'license_view_all': 'Afficher toutes les licences',
    'license_packages': 'Paquets utilisés',
    'no_licenses_found': 'Aucune information de licence trouvée.',

    'tutorial_restart': 'Revoir le tutoriel',
    'tut_skip': 'Passer',

    'tut_search_title': 'Recherche & Filtre',
    'tut_search_desc': 'Utilisez les barres de recherche et les catégories ci-dessus pour trouver vos entrées plus rapidement.',
    'tut_add_title': 'Ajouter une entrée',
    'tut_add_desc': 'Appuyez ici pour ajouter votre première entrée.',
    'tut_name_desc': 'Entrez le nom de l\'entrée ici et choisissez la catégorie appropriée.',
    'tut_kauf_desc': 'Inscrivez le commerçant et le prix d\'achat ici.',
    'tut_garantie_desc': 'Inscrivez la date d\'achat et la durée de la garantie ici.',
    'tut_timer_desc': 'Définissez combien de temps avant l\'expiration de la garantie vous souhaitez être averti.',
    'tut_foto_desc': 'Ajoutez jusqu\'à 4 photos du reçu ou du produit.',
    'tut_save_desc': 'Cliquez ici pour créer l\'entrée maintenant !',
    'tut_demo_title': 'Votre nouvelle entrée !',
    'tut_demo_desc': 'Appuyez sur la tuile pour ouvrir la vue détaillée avec vos informations fournies.\nVous pouvez également afficher les photos en plein écran ici et imprimer ces informations au format PDF.',
    'tut_click_details_title': 'Afficher les détails',
    'tut_click_details_desc': 'Cliquez ici pour afficher les détails.',
    'tut_detail_title': 'Vue détaillée',
    'tut_detail_info_desc': 'Vous trouverez ici toutes les informations concernant votre entrée ainsi que vos photos de reçus enregistrées.',
    'tut_download_title': 'Télécharger PDF',
    'tut_download_desc': 'Téléchargez vos informations de garantie au format PDF ici.',
    'tut_print_title': 'Imprimer',
    'tut_print_desc': 'Imprimez le PDF directement depuis votre appareil.',
    'tut_back_title': 'Retour à l\'écran principal',
    'tut_back_desc': 'Cliquez sur la flèche pour retourner à l\'écran principal.',
    'tut_edit_title': 'Modifier l\'entrée',
    'tut_edit_desc': 'Vous pouvez ajuster les données de votre entrée à tout moment à l\'aide de cette icône de crayon.',
    'tut_del_title': 'Supprimer l\'entrée',
    'tut_del_desc': 'Cliquez sur l\'icône de la corbeille pour supprimer définitivement l\'entrée.',
    'tut_notif_title': 'Expiration de la garantie',
    'tut_notif_desc': 'Ici, vous pouvez voir quelles garanties expirent bientôt.',
    'tut_bell_title': 'Aperçu des expirations (Cloche)',
    'tut_bell_desc': 'Cliquez sur la cloche pour accéder à l\'aperçu des expirations.',
    'tut_exp_active_title': 'Garanties Actives',
    'tut_exp_active_desc': 'Vous trouverez ici toutes les garanties non expirées.',
    'tut_exp_expired_title': 'Garanties Expirées',
    'tut_exp_expired_desc': 'Toutes les entrées expirées sont rassemblées ici.',
    'tut_exp_entry_title': 'Entrée de garantie',
    'tut_exp_entry_desc': 'Ici vous pouvez voir le statut et les jours restants de la garantie.',
    'tut_set_title': 'Paramètres',
    'tut_set_desc': 'Ici, vous pouvez ajuster des paramètres tels que la langue et le thème.',
    'tut_set_lang_title': 'Paramètres de langue',
    'tut_set_lang_desc': 'Changez la langue de l\'application selon vos préférences.',
    'tut_set_ver_title': 'Version de l\'App',
    'tut_set_ver_desc': 'Consultez votre version actuelle et l\'historique des mises à jour ici.',
    'tut_set_end_title': 'Tutoriel terminé !',
    'tut_set_end_desc': 'Vous connaissez maintenant toutes les fonctionnalités. Amusez-vous bien !',
    'tut_fin_title': 'Tutoriel terminé !',
    'tut_fin_desc': 'Appuyez ici pour terminer le tutoriel et gérer vos garanties !',
    'tut_welcome_title': 'Bienvenue dans le Gestionnaire de garantie !',
    'tut_welcome_desc': 'Avec le bouton « Passer » en haut à droite, vous pouvez ignorer le tutoriel à tout moment.\nPour passer à l\'étape suivante, appuyez sur les zones éclairées !',
    'tut_welcome_start': 'C\'est parti !',

    'wochen': 'Semaines',
    'monate': 'Mois',
    'jahre': 'Années',
    'jahr': 'Année',
    'on_date': 'le ',
    'at_time': ' à ',
    'clock': '',
    'time_am': 'AM',
    'time_pm': 'PM',
    'time_picker_dial_help': 'SÉLECTIONNER L\'HEURE',
    'time_picker_input_help': 'SAISIR L\'HEURE',
    'time_picker_hour': 'Heure',
    'time_picker_minute': 'Minute',
    'time_picker_dial_mode': 'Passer au mode cadran',
    'time_picker_input_mode': 'Passer à la saisie au clavier',
    'time_picker_invalid': 'Heure invalide',
    'time_picker_hour_announce': 'Sélectionner les heures',
    'time_picker_minute_announce': 'Sélectionner les minutes',

    'select_empty': 'Non spécifié',
    'remarks': 'Remarque',
    'remarks_hint': 'Notes...',
    'photo_info_text': 'Au moins 1 photo est requise pour prouver les demandes de garantie ultérieurement avec un reçu.',

    'curr_eur': 'Euro',
    'curr_chf': 'Franc suisse',
    'curr_usd': 'Dollar américain',
    'curr_cad': 'Dollar canadien',
    'curr_aud': 'Dollar australien',
    'curr_nzd': 'Dollar néo-zélandais',
    'curr_gbp': 'Livre sterling',
    'curr_mxn': 'Peso mexicain',
    'curr_ars': 'Peso argentin',
    'curr_clp': 'Peso chilien',
    'curr_cop': 'Colombian Peso',
    'curr_pen': 'Peruan Sol',
    'curr_uyu': 'Peso uruguayen',
    'curr_pyg': 'Guaraní paraguayen',
    'curr_bob': 'Boliviano',
    'curr_brl': 'Réal brésilien',
    'curr_crc': 'Colón costaricain',
    'curr_gtq': 'Quetzal guatémaltèque',
    'curr_hnl': 'Lempira hondurien',
    'curr_nio': 'Córdoba nicaraguayen',
    'curr_dop': 'Peso dominicain',
    'curr_htg': 'Gourde haïtienne',
    'curr_cup': 'Peso cubain',
    'curr_xof': 'Franc CFA (BCEAO)',
    'curr_xaf': 'Franc CFA (BEAC)',
    'curr_mad': 'Dirham marocain',
    'curr_dzd': 'Dinar algérien',
    'curr_tnd': 'Dinar tunisien',
    'curr_kmf': 'Franc comorien',
    'curr_djf': 'Franc djiboutien',
    'curr_rwf': 'Franc rwandais',
    'curr_bif': 'Franc burundais',
    'curr_xcd': 'Dollar des Caraïbes orientales',
    'curr_xpf': 'Franc CFP',
  },
  'es': {
    'today': 'Hoy',
    'day_singular': 'día',
    'days_plural': 'días',
    'week_singular': 'semana',
    'weeks_plural': 'semanas',
    'month_singular': 'mes',
    'months_plural': 'meses',
    'year_singular': 'año',
    'years_plural': 'años',
    'expired_suffix': '',
    'expires_today': 'Caduca hoy',
    'expired_today': 'Caducó hoy',
    
    'select_language': 'Seleccionar idioma',
    'ok': 'OK',
    'expired_since': 'Caducado hace ',
    'expired_day_singular': ' día',
    'expired_day_plural': ' días',
    'active': 'Activo',

    'app_title': 'Gestor de garantías',
    'search_hint': 'nombre, fecha de compra y tienda...',
    'store_hint': '¿Dónde lo compraste?...',
    'all': 'Todos',
    'electronics': 'Electrónica',
    'clothes': 'Ropa',
    'furniture': 'Muebles',
    'household': 'Hogar',
    'others': 'Otros',
    'expired_cat': 'Caducado',

    'no_devices': 'Aún no hay entradas',
    'no_devices_desc': 'Añade tu primera entrada para guardar tus tickets de compra y no perder ningún plazo de garantía.',
    'no_search_results': 'No se encontraron entradas para este filtro.',

    'bought_at': 'Comprado en',
    'buy_date': 'Fecha de compra',
    'expiry': 'Vencimiento',
    'reminder': 'Recordatorio',

    'settings': 'Ajustes',
    'product_name': 'Nombre de la entrada',
    'category': 'Categoría',
    'buy_details': 'Detalles de compra',
    'price': 'Precio',
    'warranty_duration': 'Duración de la garantía',
    'own_duration': 'Duración personalizada',
    'duration': 'Duración',
    'unit': 'Unidad',
    'expiry_date': 'Fecha de vencimiento',
    'set_reminder': 'Recordatorio',
    'never': 'Nunca',
    'photos': 'Fotos',
    'save': 'Guardar',
    'camera': 'Cámara',
    'gallery': 'Galería',
    'details': 'Detalles del producto',
    'unknown': 'Desconocido',

    'delete_device_title': '¿Eliminar entrada?',
    'delete_device_desc': '¿Seguro que quieres eliminar esta entrada de forma permanente?',
    'cancel': 'Cancelar',
    'delete': 'Eliminar',
    'edit': 'Editar',

    'allow': 'Permitir',
    'notif_perm_title': 'Permitir notificaciones',
    'notif_perm_desc': 'Permite las notificaciones para que podamos recordarte tus avisos programados.',
    
    'time_format_12h': 'Formato de 12 horas',
    'turn_on_light_mode': 'Activar modo claro',
    'turn_on_dark_mode': 'Activar modo oscuro',
    'switch_to_12h': 'Formato 24h',
    'switch_to_24h': 'Formato 12h',

    'past_time_error': '¡La hora no puede estar en el pasado!',

    'export_error': 'Error al exportar',
    'error_loading_file': 'Error al cargar el archivo.',
    'error_max_photos': '¡Puedes añadir un máximo de 4 fotos!',
    'error_name_missing': 'Falta el nombre de la entrada.',
    'error_name_used': 'Este nombre ya está en uso.',
    'error_price_invalid': 'El precio debe ser 1 o superior.',
    'error_duration_invalid': 'La garantía debe ser superior a 1 semana.',
    'error_store_missing': 'Falta el lugar de compra.',
    'error_photo_missing': 'Se necesita al menos 1 foto para poder justificar con un ticket de compra futuras reclamaciones de garantía.',
    'demo_product': 'Producto de demostración',
    'demo_store': 'TIENDA DE EJEMPLO',

    'notif_title': 'La garantía caduca pronto: ',
    'notif_body': 'La garantía de esta entrada caduca el ',
    'notif_body_end': '!',

    'expiry_title': 'Calendario de vencimientos',
    'no_reminders': 'No hay recordatorios configurados.',
    'expired': 'Caducado',
    'days_left': 'Quedan ',
    'days': ' días',
    'deleted_success': ' se ha eliminado.',

    'appearance': 'Apariencia y formato',
    'dark_mode': 'Tema oscuro',
    'dark_mode_desc': 'Cuida tu vista en la oscuridad',
    'language': 'Idioma',
    'currency': 'Moneda',
    'sort_by': 'Orden de la lista principal',
    'sort_a_z': 'Alfabético (de A a Z)',
    'sort_z_a': 'Alfabético (de Z a A)',
    'sort_newest': 'Fecha de compra más reciente primero',
    'sort_oldest': 'Fecha de compra más antigua primero',
    'sort_expiry': 'Fecha de vencimiento (próxima primero)',

    'data_management': 'Gestión de datos y copia de seguridad',
    'export_data': 'Exportar datos (copia de seguridad)',
    'import_data': 'Importar datos',
    'export_success': '¡Copia de seguridad exportada correctamente!',
    'import_success': '¡Copia de seguridad importada correctamente!',
    'import_error': 'Error al importar los datos. ¿Es válido el archivo ZIP?',
    'delete_all_data': 'Eliminar todos los datos',
    'delete_all_title': '¿Eliminar todos los datos de forma irreversible?',
    'delete_all_desc': 'Esto elimina todas las entradas, ajustes y justificantes guardados localmente. ¡Esta acción no se puede deshacer!',
    'delete_all_confirm': 'Eliminar todo',
    'all_data_deleted': 'Todos los datos han sido eliminados.',

    'export_method_desc': '¿Cómo quieres exportar la copia de seguridad?',
    'export_share': 'Compartir / Enviar',
    'export_save': 'Guardar en el almacenamiento',
    'import_desc': 'Para recibir datos de forma inalámbrica desde otro dispositivo, envía la copia de seguridad (ZIP) a este dispositivo, por ejemplo con Quick Share o por correo electrónico, y guárdala.\n\nDespués selecciona aquí la copia de seguridad.',
    'import_select_file': 'Seleccionar archivo',
    'backup_save_title': 'Guardar copia de seguridad',
    'backup_share_text': 'Backup Warranty Manager',

    'info': 'Info y aspectos legales',
    'app_version': 'Versión',
    'update_log': 'Historial de actualizaciones',
    'update_log_title': '¿Qué hay de nuevo?',
    'update_log_desc': 'Septiembre de 2026\n• Lanzamiento de la aplicación y se han añadido todas las funciones previstas.',
    'privacy_policy': 'Política de privacidad',
    'privacy_policy_title': 'Política de privacidad',
    'privacy_policy_text': 'Política de privacidad\n\n1. Almacenamiento de datos\nTodos los datos introducidos se almacenan exclusivamente de forma local en su dispositivo.\n\n2. Acceso a la cámara y a las fotos\nLa aplicación necesita acceso a la cámara y a la galería para guardar localmente en su dispositivo las fotos de los tickets de compra.',
    'imprint': 'Aviso legal y proveedor',
    'imprint_title': 'Aviso legal',
    'imprint_text': 'Proveedor del servicio:\nPeter Weissenborn\nCorreo electrónico: support.warrantymanager@gmail.com\n\nResponsable del contenido conforme al RGPD.',
    'licenses': 'Licencias de código abierto',

    'license_title': 'Licencias de software',
    'license_details': 'Detalles de licencias y bibliotecas de terceros',
    'license_summary': 'Esta aplicación utiliza componentes de código abierto del framework Flutter y bibliotecas relacionadas.',
    'license_legalese': '© 2026 Peter Weissenborn. Todos los derechos reservados.',
    'license_view_all': 'Ver todas las licencias',
    'license_packages': 'Paquetes utilizados',
    'no_licenses_found': 'No se encontró información de licencias.',

    'tutorial_restart': 'Volver a ver el tutorial',
    'tut_skip': 'Omitir',

    'tut_search_title': 'Buscar y filtrar',
    'tut_search_desc': 'Usa las barras de búsqueda y las categorías de arriba para encontrar tus entradas más rápido.',
    'tut_add_title': 'Añadir entrada',
    'tut_add_desc': 'Pulsa aquí para añadir tu primera entrada.',
    'tut_name_desc': 'Introduce aquí el nombre de la entrada y elige la categoría adecuada.',
    'tut_kauf_desc': 'Introduce aquí la tienda y el precio de compra.',
    'tut_garantie_desc': 'Introduce aquí la fecha de compra y la duración de la garantía.',
    'tut_timer_desc': 'Configura con cuánta antelación al vencimiento de la garantía quieres recibir un aviso.',
    'tut_foto_desc': 'Añade hasta 4 fotos del ticket de compra o del producto.',
    'tut_save_desc': '¡Haz clic aquí para crear la entrada ahora!',
    'tut_demo_title': '¡Tu nueva entrada!',
    'tut_demo_desc': 'Toca la tarjeta para abrir la vista de detalles con la información que has introducido.\nAdemás, aquí puedes ver las fotos a pantalla completa e imprimir esta información en PDF.',
    'tut_click_details_title': 'Mostrar detalles',
    'tut_click_details_desc': 'Haz clic aquí para mostrar los detalles.',
    'tut_detail_title': 'Vista de detalles',
    'tut_detail_info_desc': 'Aquí ves toda la información de tu entrada, así como las fotos de tickets que has guardado.',
    'tut_download_title': 'Descargar PDF',
    'tut_download_desc': 'Descarga aquí la información de la garantía en PDF.',
    'tut_print_title': 'Imprimir',
    'tut_print_desc': 'Imprime el PDF directamente desde tu dispositivo.',
    'tut_back_title': 'Volver a la pantalla principal',
    'tut_back_desc': 'Haz clic en la flecha para volver a la pantalla principal.',
    'tut_edit_title': 'Editar entrada',
    'tut_edit_desc': 'Con este icono de lápiz puedes modificar los datos de tu entrada en cualquier momento.',
    'tut_del_title': 'Eliminar entrada',
    'tut_del_desc': 'Haz clic en el icono de la papelera para eliminar la entrada de forma definitiva.',
    'tut_notif_title': 'Vencimiento de la garantía',
    'tut_notif_desc': 'Aquí ves qué garantías caducarán próximamente.',
    'tut_bell_title': 'Resumen de vencimientos (campana)',
    'tut_bell_desc': 'Haz clic en la campana para ir al resumen de vencimientos.',
    'tut_exp_active_title': 'Garantías activas',
    'tut_exp_active_desc': 'Aquí encuentras todas las garantías que aún no han caducado.',
    'tut_exp_expired_title': 'Garantías caducadas',
    'tut_exp_expired_desc': 'Aquí se recogen todas las entradas caducadas.',
    'tut_exp_entry_title': 'Entrada de garantía',
    'tut_exp_entry_desc': 'Aquí ves el estado y los días restantes de la garantía.',
    'tut_set_title': 'Ajustes',
    'tut_set_desc': 'Aquí puedes configurar ajustes como el idioma y el diseño.',
    'tut_set_lang_title': 'Ajustes de idioma',
    'tut_set_lang_desc': 'Cambia el idioma de la aplicación a tu gusto.',
    'tut_set_ver_title': 'Versión de la app',
    'tut_set_ver_desc': 'Aquí ves tu versión actual y el registro de actualizaciones.',
    'tut_set_end_title': '¡Tutorial completado!',
    'tut_set_end_desc': 'Ya conoces todas las funciones. ¡Que disfrutes del Gestor de garantías!',
    'tut_fin_title': '¡Tutorial terminado!',
    'tut_fin_desc': '¡Toca aquí o en el icono para terminar el tutorial y gestionar tus garantías!',
    'tut_welcome_title': '¡Bienvenido al Gestor de garantías!',
    'tut_welcome_desc': 'Con el botón «Omitir» de arriba a la derecha puedes saltarte el tutorial en cualquier momento.\nPara pasar al siguiente paso, ¡toca las zonas resaltadas!',
    'tut_welcome_start': '¡Vamos!',

    'wochen': 'Semanas',
    'monate': 'Meses',
    'jahre': 'Años',
    'jahr': 'Año',
    'on_date': 'el ',
    'at_time': ' a las ',
    'clock': '',
    'time_am': 'AM',
    'time_pm': 'PM',
    'time_picker_dial_help': 'SELECCIONAR HORA',
    'time_picker_input_help': 'INTRODUCIR HORA',
    'time_picker_hour': 'Hora',
    'time_picker_minute': 'Minuto',
    'time_picker_dial_mode': 'Cambiar al modo de reloj',
    'time_picker_input_mode': 'Cambiar a entrada de texto',
    'time_picker_invalid': 'Hora no válida',
    'time_picker_hour_announce': 'Seleccionar horas',
    'time_picker_minute_announce': 'Seleccionar minutos',

    'select_empty': 'Sin especificar',
    'remarks': 'Observación',
    'remarks_hint': 'Notas...',
    'photo_info_text': 'Se necesita al menos 1 foto para poder justificar con un ticket de compra futuras reclamaciones de garantía.',

    'curr_eur': 'Euro',
    'curr_chf': 'Franco suizo',
    'curr_usd': 'Dólar estadounidense',
    'curr_cad': 'Dólar canadiense',
    'curr_aud': 'Dólar australiano',
    'curr_nzd': 'Dólar neozelandés',
    'curr_gbp': 'Libra esterlina',
    'curr_mxn': 'Peso mexicano',
    'curr_ars': 'Peso argentino',
    'curr_clp': 'Peso chileno',
    'curr_cop': 'Peso colombiano',
    'curr_pen': 'Sol peruano',
    'curr_uyu': 'Peso uruguayo',
    'curr_pyg': 'Guaraní paraguayo',
    'curr_bob': 'Boliviano',
    'curr_brl': 'Real brasileño',
    'curr_crc': 'Colón costarricense',
    'curr_gtq': 'Quetzal guatemalteco',
    'curr_hnl': 'Lempira hondureño',
    'curr_nio': 'Córdoba nicaragüense',
    'curr_dop': 'Peso dominicano',
    'curr_htg': 'Gourde haitiano',
    'curr_cup': 'Peso cubano',
    'curr_xof': 'Franco CFA de África Occidental',
    'curr_xaf': 'Franco CFA de África Central',
    'curr_mad': 'Dírham marroquí',
    'curr_dzd': 'Dinar argelino',
    'curr_tnd': 'Dinar tunecino',
    'curr_kmf': 'Franco comorano',
    'curr_djf': 'Franco yibutiano',
    'curr_rwf': 'Franco ruandés',
    'curr_bif': 'Franco burundés',
    'curr_xcd': 'Dólar del Caribe Oriental',
    'curr_xpf': 'Franco CFP',
  },
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