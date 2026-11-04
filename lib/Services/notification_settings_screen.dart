import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/notification_template_helper.dart';
import '../Services/settings_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  List<Map<String, String>> _parts = [];
  bool _loaded = false;

  DateTime get _dummyNotifDate => DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTemplate());
  }

  // ── Dummy-Gerät für die Vorschau ──
  Map<String, String> _buildDummyGerat(SettingsProvider settings) {
    final lang = settings.languageCode;
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 365));
    final buy = now.subtract(const Duration(days: 365));

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return {
      'name': getText(lang, 'notif_sample_name'),
      'kaufDatum': fmt(buy),
      'ablaufDatum': fmt(expiry),
      'woGekauft': getText(lang, 'notif_sample_store'),
      'preis': '1199',
      'waehrung': '€',
      'kategorie': 'electronics',
      'bemerkung': getText(lang, 'notif_sample_remarks'),
      'bildPfade': 'a.jpg,b.jpg,c.jpg',
    };
  }

  // ── Template laden ──
  Future<void> _loadTemplate() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final loaded = settings.notifTemplate;

    setState(() {
      _parts = loaded.isEmpty
          ? List.from(NotificationTemplateHelper.defaultTemplate())
          : List.from(loaded);
      _loaded = true;
    });

    if (loaded.isEmpty) {
      await settings.setNotifTemplate(_parts);
    }
  }

  Future<void> _saveTemplate() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.setNotifTemplate(_parts);
  }

  // ── Baustein-Operationen ──
  void _addPart(String type, {String? customText}) {
    setState(() {
      _parts.add(NotificationTemplateHelper.createPart(type,
          customText: customText));
    });
    _saveTemplate();
  }

  void _removePart(int index) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;

    if (_parts[index]['type'] == NotificationTemplateHelper.typeName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText(lang, 'notif_part_mandatory_hint')),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _parts.removeAt(index));
    _saveTemplate();
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _parts.removeAt(oldIndex);
      _parts.insert(newIndex, item);
    });
    _saveTemplate();
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _parts.removeAt(index);
      _parts.insert(index - 1, item);
    });
    _saveTemplate();
  }

  void _moveDown(int index) {
    if (index >= _parts.length - 1) return;
    setState(() {
      final item = _parts.removeAt(index);
      _parts.insert(index + 1, item);
    });
    _saveTemplate();
  }

  // ── Bottom Sheet: Baustein hinzufügen ──
  Future<void> _showAddPartSheet() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    getText(lang, 'notif_add_part'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ...NotificationTemplateHelper.availableTypes.map((type) {
                  final alreadyAdded = _parts.any((p) => p['type'] == type);
                  final isCustom =
                      type == NotificationTemplateHelper.typeCustom;
                  final disabled = alreadyAdded && !isCustom;
                  final typeColor =
                      NotificationTemplateHelper.colorForType(type);

                  return ListTile(
                    enabled: !disabled,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: disabled
                            ? Colors.grey.withValues(alpha: 0.12)
                            : typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForType(type),
                        color: disabled ? Colors.grey : typeColor,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      getText(lang,
                          NotificationTemplateHelper.getLabelKeyForType(type)),
                      style:
                          TextStyle(color: disabled ? Colors.grey : null),
                    ),
                    subtitle: disabled
                        ? Text(
                            getText(lang, 'notif_part_already_added'),
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    onTap: disabled
                        ? null
                        : () async {
                            Navigator.pop(sheetContext);
                            if (isCustom) {
                              await _addCustomText();
                            } else {
                              _addPart(type);
                            }
                          },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Dialog: Eigener Text ──
  Future<void> _addCustomText() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'notif_part_custom')),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            maxLength: 120,
            decoration: InputDecoration(
              hintText: getText(lang, 'notif_custom_text_hint'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(getText(lang, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(getText(lang, 'save')),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      _addPart(NotificationTemplateHelper.typeCustom, customText: result);
    }
  }

  // ── Konfigurations-Dialog für einen Baustein ──
  // FIX: Farbe wird nur lokal im Baustein gespeichert (part['color']),
  //      NICHT global in settings.savedAccentColors.
  Future<void> _openConfigDialog(int index) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;
    final part = _parts[index];
    final type = part['type'] ?? '';

    final canLabel = NotificationTemplateHelper.hasLabelOption(type);
    final canFormat = NotificationTemplateHelper.hasFormatOption(type);
    final isCustom = type == NotificationTemplateHelper.typeCustom;

    bool showLabel = NotificationTemplateHelper.getShowLabel(part);
    String format = NotificationTemplateHelper.getFormat(part);
    final textController = TextEditingController(text: part['text'] ?? '');

    // Aktuelle benutzerdefinierte Farbe aus dem Baustein lesen
    Color? currentColor;
    final rawColor = part['color'];
    if (rawColor != null && rawColor.isNotEmpty) {
      final int? argb = int.tryParse(rawColor);
      if (argb != null) currentColor = Color(argb);
    }

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final defaultColor =
                NotificationTemplateHelper.colorForType(type);
            final activeColor = currentColor ?? defaultColor;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Titel ──
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconForType(type),
                                color: activeColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              getText(lang, 'notif_part_settings'),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // ── Farbauswahl (nur lokal, nicht global gespeichert) ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
                        child: Text(
                          getText(lang, 'notif_color_title'),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: Text(
                          getText(lang, 'notif_color_hint'),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Row(
                          children: [
                            // ── Farb-Kreis (tippbar zum Öffnen des Dialogs) ──
                            GestureDetector(
                              onTap: () async {
                                final newColor =
                                    await _showHexColorDialog(
                                        context, settings, lang, activeColor);
                                if (newColor != null) {
                                  setSheetState(
                                      () => currentColor = newColor);
                                }
                              },
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: currentColor == null
                                    ? Icon(
                                        Icons.palette_outlined,
                                        color: SettingsProvider
                                            .contrastColor(activeColor),
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // ── Farb-Label / Hex-Code ──
                            Expanded(
                              child: Text(
                                currentColor == null
                                    ? getText(lang, 'notif_color_default')
                                    : '#${_toHex(currentColor!)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            // ── Reset-Button (nur wenn benutzerdefiniert) ──
                            if (currentColor != null)
                              TextButton.icon(
                                onPressed: () => setSheetState(
                                    () => currentColor = null),
                                icon: const Icon(Icons.restore, size: 18),
                                label:
                                    Text(getText(lang, 'notif_color_default')),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            // ── Farbe wählen (Hex-Dialog, NICHT global gespeichert) ──
                            OutlinedButton.icon(
                              icon: const Icon(Icons.color_lens_outlined,
                                  size: 18),
                              label: Text(getText(lang, 'add_color')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: activeColor,
                                side: BorderSide(color: activeColor),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                final newColor =
                                    await _showHexColorDialog(
                                        context, settings, lang, activeColor);
                                if (newColor != null) {
                                  // Wird AUSSCHLIESSLICH in diesem Baustein
                                  // (part['color']) gespeichert –
                                  // NICHT in settings.savedAccentColors.
                                  setSheetState(
                                      () => currentColor = newColor);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── Label-Toggle ──
                      if (canLabel)
                        SwitchListTile(
                          title: Text(getText(lang, 'notif_show_label')),
                          subtitle: Text(
                              getText(lang, 'notif_show_label_desc')),
                          value: showLabel,
                          onChanged: (v) =>
                              setSheetState(() => showLabel = v),
                        ),

                      // ── Format-Dropdown ──
                      if (canFormat)
                        ListTile(
                          title: Text(getText(lang, 'notif_format')),
                          trailing: DropdownButton<String>(
                            value: format,
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => format = v);
                              }
                            },
                            items: NotificationTemplateHelper.formatOptions
                                .map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(getText(
                                  lang,
                                  NotificationTemplateHelper
                                      .getFormatLabelKey(f),
                                )),
                              );
                            }).toList(),
                          ),
                        ),

                      // ── Custom-Text ──
                      if (isCustom)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: textController,
                            maxLines: 3,
                            maxLength: 120,
                            decoration: InputDecoration(
                              labelText:
                                  getText(lang, 'notif_part_custom'),
                              hintText: getText(
                                  lang, 'notif_custom_text_hint'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),

                      // ── Aktions-Buttons ──
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.pop(sheetContext),
                                child: Text(getText(lang, 'cancel')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final updated =
                                      Map<String, String>.from(part);
                                  if (canLabel) {
                                    updated['showLabel'] =
                                        showLabel ? 'true' : 'false';
                                  }
                                  if (canFormat) {
                                    updated['format'] = format;
                                  }
                                  if (isCustom) {
                                    updated['text'] =
                                        textController.text.trim();
                                  }
                                  // Farbe nur im Baustein selbst speichern
                                  if (currentColor == null) {
                                    updated.remove('color');
                                  } else {
                                    updated['color'] =
                                        currentColor!.toARGB32().toString();
                                  }
                                  Navigator.pop(sheetContext, updated);
                                },
                                child: Text(getText(lang, 'save')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _parts[index] = result);
      _saveTemplate();
    }
  }

  // ── Hex-/RGB-Farbdialog ──
  Color? _parseHex(String input) {
    var h = input.trim().replaceAll('#', '');
    if (h.length != 6) return null;
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }

  String _toHex(Color c) {
    final v = c.toARGB32() & 0xFFFFFF;
    return v.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  Future<Color?> _showHexColorDialog(
    BuildContext context,
    SettingsProvider settings,
    String lang,
    Color initial,
  ) async {
    final controller = TextEditingController(text: _toHex(initial));
    Color preview = initial;
    String? error;

    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void updateFromHex(String text) {
              final c = _parseHex(text);
              setLocal(() {
                if (c != null) preview = c;
                error = null;
              });
            }

            void updateFromSliders({int? r, int? g, int? b}) {
              final nr = r ?? ((preview.toARGB32() >> 16) & 0xFF);
              final ng = g ?? ((preview.toARGB32() >> 8) & 0xFF);
              final nb = b ?? (preview.toARGB32() & 0xFF);
              setLocal(() {
                preview = Color.fromARGB(255, nr, ng, nb);
                controller.text = _toHex(preview);
                error = null;
              });
            }

            final value = preview.toARGB32();
            final r = (value >> 16) & 0xFF;
            final g = (value >> 8) & 0xFF;
            final b = value & 0xFF;

            return AlertDialog(
              title: Text(getText(lang, 'add_color')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: preview,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade500),
                      ),
                      child: Text(
                        '#${_toHex(preview)}',
                        style: TextStyle(
                          color:
                              SettingsProvider.contrastColor(preview),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLength: 7,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: getText(lang, 'hex_code'),
                        hintText: getText(lang, 'hex_hint'),
                        prefixText: '#',
                        errorText: error,
                        counterText: '',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: updateFromHex,
                    ),
                    const SizedBox(height: 8),
                    _rgbSlider(getText(lang, 'color_red'), r,
                        Colors.red, (v) => updateFromSliders(r: v)),
                    _rgbSlider(getText(lang, 'color_green'), g,
                        Colors.green, (v) => updateFromSliders(g: v)),
                    _rgbSlider(getText(lang, 'color_blue'), b,
                        Colors.blue, (v) => updateFromSliders(b: v)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(getText(lang, 'cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final c = _parseHex(controller.text);
                    if (c == null) {
                      setLocal(() =>
                          error = getText(lang, 'hex_invalid'));
                      return;
                    }
                    Navigator.pop(dialogContext, c);
                  },
                  child: Text(getText(lang, 'use_color')),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Widget _rgbSlider(String label, int value, Color activeColor,
      ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 44,
            child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: activeColor,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
            width: 30,
            child:
                Text('$value', style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  // ── Vorlage zurücksetzen ──
  Future<void> _resetToDefault() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'notif_reset_title')),
          content: Text(getText(lang, 'notif_reset_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(getText(lang, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(getText(lang, 'notif_reset_default')),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _parts = List.from(NotificationTemplateHelper.defaultTemplate());
      });
      await _saveTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getText(lang, 'notif_saved'))),
        );
      }
    }
  }

  // ── Icon pro Baustein-Typ ──
  IconData _iconForType(String type) {
    switch (type) {
      case NotificationTemplateHelper.typeName:
        return Icons.label_important;
      case NotificationTemplateHelper.typeBuyDate:
        return Icons.shopping_bag;
      case NotificationTemplateHelper.typeExpiryDate:
        return Icons.event_busy;
      case NotificationTemplateHelper.typeDaysLeft:
        return Icons.hourglass_bottom;
      case NotificationTemplateHelper.typeStore:
        return Icons.storefront;
      case NotificationTemplateHelper.typePrice:
        return Icons.attach_money;
      case NotificationTemplateHelper.typeDuration:
        return Icons.timer;
      case NotificationTemplateHelper.typeCategory:
        return Icons.category;
      case NotificationTemplateHelper.typeRemarks:
        return Icons.notes;
      case NotificationTemplateHelper.typePhotoCount:
        return Icons.photo_library;
      case NotificationTemplateHelper.typeDetailLink:
        return Icons.open_in_new;
      case NotificationTemplateHelper.typeScreenshot:
        return Icons.screenshot_monitor;
      case NotificationTemplateHelper.typeCustom:
        return Icons.text_fields;
      default:
        return Icons.circle;
    }
  }

  // ── Vorschautext für einen einzelnen Baustein (Listenzeile) ──
  String _renderPartPreview(
    SettingsProvider settings,
    String lang,
    Map<String, String> part,
  ) {
    final dummy = _buildDummyGerat(settings);
    final rendered = NotificationTemplateHelper.renderPart(
      langCode: lang,
      part: part,
      gerat: dummy,
      currencySymbol: settings.currencySymbol,
      referenceDate: _dummyNotifDate,
    );
    return rendered.isEmpty ? '—' : rendered;
  }

  // ── Farbige TextSpans für die Vorschau-Karte ──
  // FIX: Jeder Baustein wird in seiner eigenen Farbe dargestellt.
  List<TextSpan> _buildPreviewSpans(SettingsProvider settings, String lang) {
    final dummy = _buildDummyGerat(settings);
    final spans = <TextSpan>[];
    bool first = true;

    for (final part in _parts) {
      final text = NotificationTemplateHelper.renderPart(
        langCode: lang,
        part: part,
        gerat: dummy,
        currencySymbol: settings.currencySymbol,
        referenceDate: _dummyNotifDate,
      );
      if (text.isEmpty) continue;

      if (!first) {
        spans.add(TextSpan(
          text: ' • ',
          style: TextStyle(
              color: Colors.grey[400], fontSize: 13, height: 1.4),
        ));
      }

      final color = NotificationTemplateHelper.getPartColor(part);
      spans.add(TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 13, height: 1.4),
      ));
      first = false;
    }

    // Fallback wenn keine Bausteine gerendert werden
    if (spans.isEmpty) {
      final dummy2 = _buildDummyGerat(settings);
      final fallback =
          '${getText(lang, 'notif_body')}${dummy2['ablaufDatum']}${getText(lang, 'notif_body_end')}';
      spans.add(TextSpan(
        text: fallback,
        style: TextStyle(
            color: Colors.grey[600], fontSize: 13, height: 1.4),
      ));
    }

    return spans;
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(getText(lang, 'notif_settings')),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Vorschau ──
                      _buildSectionTitle(
                          getText(lang, 'notif_preview'), settings),
                      const SizedBox(height: 8),
                      _buildNotificationPreview(settings, lang),
                      const SizedBox(height: 24),

                      // ── Bausteine-Header ──
                      Row(
                        children: [
                          _buildSectionTitle(
                              getText(lang, 'notif_template_parts'),
                              settings),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: settings.appButtonColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                      opacity: animation, child: child),
                                );
                              },
                              child: Text(
                                '${_parts.length}',
                                key: ValueKey(_parts.length),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: settings.appButtonColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        getText(lang, 'notif_template_hint'),
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),

                      // ── Baustein-Liste ──
                      if (_parts.isEmpty)
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                getText(lang, 'notif_template_empty_hint'),
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        )
                      else
                        // FIX Rütteln: TweenAnimationBuilder entfernt.
                        // Bausteine werden direkt ohne Scale-Animation gerendert.
                        ReorderableListView(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorderItem: _reorderItem,
                          children: List.generate(_parts.length,
                              (index) {
                            final part = _parts[index];
                            final type = part['type'] ?? '';
                            final isMandatory = type ==
                                NotificationTemplateHelper.typeName;
                            final label = getText(
                                lang,
                                NotificationTemplateHelper
                                    .getLabelKeyForType(type));
                            final customText = part['text'] ?? '';

                            // FIX Vorschautext: Farbe aus Baustein übernehmen
                            final previewText =
                                _renderPartPreview(settings, lang, part);
                            final typeColor =
                                NotificationTemplateHelper.getPartColor(
                                    part);

                            return Container(
                              key: ValueKey('part_$index'),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                      color: typeColor, width: 4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(
                                    left: 10,
                                    right: 4,
                                    top: 4,
                                    bottom: 4),
                                leading: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 250),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(
                                        alpha: 0.14),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _iconForType(type),
                                    color: typeColor,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  type ==
                                          NotificationTemplateHelper
                                              .typeCustom
                                      ? '$label: "$customText"'
                                      : label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.left,
                                ),
                                // FIX Ausrichtung: SizedBox erzwingt volle Breite,
                                // sodass TextAlign.left korrekt greift.
                                // FIX Farbe: Vorschautext in Baustein-Farbe.
                                subtitle: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    previewText,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: typeColor.withValues(
                                          alpha: 0.8),
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () => _openConfigDialog(index),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity:
                                          VisualDensity.compact,
                                      tooltip: getText(
                                          lang, 'notif_move_up'),
                                      icon: Icon(
                                        Icons.arrow_upward,
                                        size: 20,
                                        color: index > 0
                                            ? settings.appButtonColor
                                            : Colors.grey.shade400,
                                      ),
                                      onPressed: index > 0
                                          ? () => _moveUp(index)
                                          : null,
                                    ),
                                    IconButton(
                                      visualDensity:
                                          VisualDensity.compact,
                                      tooltip: getText(
                                          lang, 'notif_move_down'),
                                      icon: Icon(
                                        Icons.arrow_downward,
                                        size: 20,
                                        color:
                                            index < _parts.length - 1
                                                ? settings
                                                    .appButtonColor
                                                : Colors.grey.shade400,
                                      ),
                                      onPressed:
                                          index < _parts.length - 1
                                              ? () => _moveDown(index)
                                              : null,
                                    ),
                                    if (isMandatory)
                                      Tooltip(
                                        message: getText(lang,
                                            'notif_part_mandatory_hint'),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: Icon(
                                            Icons.lock,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    else
                                      IconButton(
                                        visualDensity:
                                            VisualDensity.compact,
                                        tooltip:
                                            getText(lang, 'delete'),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _removePart(index),
                                      ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 8),
                                        child: Icon(
                                          Icons.drag_handle,
                                          size: 22,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),

                      const SizedBox(height: 10),

                      // ── Baustein hinzufügen ──
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddPartSheet,
                          icon: Icon(Icons.add,
                              color: settings.appButtonColor),
                          label: Text(
                            getText(lang, 'notif_add_part'),
                            style: TextStyle(
                                color: settings.appButtonColor,
                                fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side:
                                BorderSide(color: settings.appButtonColor),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Reset ──
                      Center(
                        child: TextButton.icon(
                          onPressed: _resetToDefault,
                          icon: const Icon(Icons.restart_alt,
                              color: Colors.grey),
                          label: Text(
                            getText(lang, 'notif_reset_default'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Abschnittstitel ──
  Widget _buildSectionTitle(String text, SettingsProvider settings) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: settings.appButtonColor,
      ),
    );
  }

  // ── Benachrichtigungs-Vorschaukarte ──
  // FIX: Farbige Bausteine via RichText + TextSpan.
  // FIX: AnimatedSize entfernt (Ursache für Rütteln).
  // FIX: ?currentChild-Syntaxfehler behoben → if (currentChild != null).
  // FIX: AnimatedSwitcher layoutBuilder linksbündig.
  Widget _buildNotificationPreview(SettingsProvider settings, String lang) {
    final dummy = _buildDummyGerat(settings);
    final String title =
        '${getText(lang, 'notif_title')}${dummy['name']}';
    final spans = _buildPreviewSpans(settings, lang);

    // Key wechselt wenn Bausteine oder ihre Farben sich ändern
    final previewKey =
        _parts.map((p) => '${p['type']}${p['color']}${p['showLabel']}${p['format']}${p['text']}').join('|');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.appButtonColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: settings.appButtonColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App-Leiste ──
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: settings.appButtonColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.shield,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                getText(lang, 'app_title'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                getText(lang, 'notif_preview_now'),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Benachrichtigungs-Titel ──
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 4),

          // ── Body: farbige Spans, linksbündig ──
          // FIX: AnimatedSwitcher mit korrektem layoutBuilder (topLeft)
          //      und SizedBox(width: double.infinity) für saubere Ausrichtung.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.topLeft,
              children: [
                ...previousChildren,
                // FIX: ?currentChild war ein Syntaxfehler → korrektes if
                ?currentChild,
              ],
            ),
            child: SizedBox(
              key: ValueKey(previewKey),
              width: double.infinity,
              child: RichText(
                text: TextSpan(children: spans),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }
}