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

  // Referenz-Zeitpunkt für die Vorschau (30 Tage ab jetzt).
  // Ablaufdatum = 365 Tage ab jetzt → 335 Tage übrig, sodass alle
  // Formate (Tage/Wochen/Monate/Jahre/Auto) sinnvolle Werte liefern.
  DateTime get _dummyNotifDate => DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTemplate());
  }

  // ── Dummy-Daten für die Vorschau (mit übersetzten Platzhaltern) ──
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
    };
  }

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

  /// Wird von ReorderableListView.onReorderItem aufgerufen.
  /// Der newIndex ist bereits um den entfernten Eintrag korrigiert.
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
                  final alreadyAdded =
                      _parts.any((p) => p['type'] == type);
                  final isCustom =
                      type == NotificationTemplateHelper.typeCustom;
                  final disabled = alreadyAdded && !isCustom;
                  final typeColor =
                      NotificationTemplateHelper.colorForType(type);

                  return ListTile(
                    enabled: !disabled,
                    leading: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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
                      getText(
                          lang,
                          NotificationTemplateHelper.getLabelKeyForType(
                              type)),
                      style: TextStyle(
                          color: disabled ? Colors.grey : null),
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

  // ── Konfigurations-Dialog für einen bestehenden Baustein ──
  Future<void> _openConfigDialog(int index) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;
    final part = _parts[index];
    final type = part['type'] ?? '';

    final canLabel = NotificationTemplateHelper.hasLabelOption(type);
    final canFormat = NotificationTemplateHelper.hasFormatOption(type);
    final isCustom = type == NotificationTemplateHelper.typeCustom;

    if (!canLabel && !canFormat && !isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText(lang, 'notif_no_options')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    bool showLabel = NotificationTemplateHelper.getShowLabel(part);
    String format = NotificationTemplateHelper.getFormat(part);
    final textController = TextEditingController(text: part['text'] ?? '');
    final typeColor = NotificationTemplateHelper.colorForType(type);

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconForType(type),
                                color: typeColor,
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

                      if (canLabel)
                        SwitchListTile(
                          title: Text(getText(lang, 'notif_show_label')),
                          subtitle: Text(
                              getText(lang, 'notif_show_label_desc')),
                          value: showLabel,
                          onChanged: (v) =>
                              setSheetState(() => showLabel = v),
                        ),

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
      setState(() {
        _parts[index] = result;
      });
      _saveTemplate();
    }
  }

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
      case NotificationTemplateHelper.typeCustom:
        return Icons.text_fields;
      default:
        return Icons.circle;
    }
  }

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
                      // ── Vorschau ────────────────────────────────────
                      _buildSectionTitle(
                          getText(lang, 'notif_preview'), settings),
                      const SizedBox(height: 8),
                      _buildNotificationPreview(settings, lang),
                      const SizedBox(height: 24),

                      // ── Bausteine (Titel + animierter Zähler) ───────
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
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),

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
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        )
                      else
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorderItem: _reorderItem,
                          children: List.generate(_parts.length, (index) {
                            final part = _parts[index];
                            final type = part['type'] ?? '';
                            final isMandatory =
                                type == NotificationTemplateHelper.typeName;
                            final label = getText(
                                lang,
                                NotificationTemplateHelper
                                    .getLabelKeyForType(type));
                            final customText = part['text'] ?? '';
                            final previewText =
                                _renderPartPreview(settings, lang, part);
                            final typeColor =
                                NotificationTemplateHelper.colorForType(type);

                            return TweenAnimationBuilder<double>(
                              key: ObjectKey(part),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.scale(
                                    scale: 0.96 + 0.04 * value,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(10),
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
                                    duration:
                                        const Duration(milliseconds: 250),
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
                                  ),
                                  subtitle: AnimatedSwitcher(
                                    duration: const Duration(
                                        milliseconds: 250),
                                    transitionBuilder:
                                        (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      previewText,
                                      key: ValueKey(previewText),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
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
                                          color: index <
                                                  _parts.length - 1
                                              ? settings.appButtonColor
                                              : Colors.grey.shade400,
                                        ),
                                        onPressed: index <
                                                _parts.length - 1
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
                              ),
                            );
                          }),
                        ),

                      const SizedBox(height: 10),
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
                            side: BorderSide(
                                color: settings.appButtonColor),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: TextButton.icon(
                          onPressed: _resetToDefault,
                          icon: const Icon(Icons.restart_alt,
                              color: Colors.grey),
                          label: Text(
                            getText(lang, 'notif_reset_default'),
                            style:
                                const TextStyle(color: Colors.grey),
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

  Widget _buildNotificationPreview(
      SettingsProvider settings, String lang) {
    final currencySymbol = settings.currencySymbol;
    final dummy = _buildDummyGerat(settings);

    final String title =
        '${getText(lang, 'notif_title')}${dummy['name']}';
    final String body = NotificationTemplateHelper.buildBody(
      langCode: lang,
      template: _parts,
      produktName: dummy['name'] ?? '',
      ablaufDatumStr: dummy['ablaufDatum'] ?? '',
      gerat: dummy,
      currencySymbol: currencySymbol,
      referenceDate: _dummyNotifDate,
    );

    // Akzentfarbe: erste Baustein-Farbe, sonst App-Button-Farbe
    final Color accentColor = _parts.isNotEmpty
        ? NotificationTemplateHelper.colorForType(_parts.first['type'] ?? '')
        : settings.appButtonColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
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
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),

          // ── Animierter Body ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              child: Text(
                body,
                key: ValueKey(body),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}