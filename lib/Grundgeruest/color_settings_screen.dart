import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';

enum _ColorTarget { accent, button }

class ColorSettingsScreen extends StatelessWidget {
  const ColorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(getText(lang, 'color_settings'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  settings,
                  lang,
                  target: _ColorTarget.accent,
                  title: getText(lang, 'accent_color'),
                  desc: getText(lang, 'accent_color_desc'),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  settings,
                  lang,
                  target: _ColorTarget.button,
                  title: getText(lang, 'button_color'),
                  desc: getText(lang, 'button_color_desc'),
                ),
                const SizedBox(height: 16),
                Text(
                  getText(lang, 'saved_colors_hint'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color? _currentColor(SettingsProvider s, _ColorTarget t) =>
      t == _ColorTarget.accent ? s.accentColor : s.accentButtonColor;

  Future<void> _apply(SettingsProvider s, _ColorTarget t, Color? c) {
    return t == _ColorTarget.accent ? s.setAccentColor(c) : s.setAccentButtonColor(c);
  }

  Widget _buildSection(
    BuildContext context,
    SettingsProvider settings,
    String lang, {
    required _ColorTarget target,
    required String title,
    required String desc,
  }) {
    final current = _currentColor(settings, target);
    final saved = settings.savedAccentColors;
    final defaultPreview = target == _ColorTarget.accent
        ? settings.appBarBackground(Theme.of(context).brightness)
        : Colors.blueAccent;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _swatch(
                  context,
                  color: defaultPreview,
                  selected: current == null,
                  label: getText(lang, 'default_color'),
                  onTap: () => _apply(settings, target, null),
                ),
                for (int i = 0; i < saved.length; i++)
                  _swatch(
                    context,
                    color: saved[i],
                    selected: current != null && current.toARGB32() == saved[i].toARGB32(),
                    onTap: () => _apply(settings, target, saved[i]),
                    onDelete: () async {
                      final ok = await settings.removeSavedColor(i);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(getText(lang, ok ? 'color_deleted' : 'color_in_use')),
                        ),
                      );
                    },
                  ),
                _addSwatch(context, lang, () => _showHexDialog(context, settings, lang, target)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(
    BuildContext context, {
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onDelete,
    String? label,
  }) {
    final fg = SettingsProvider.contrastColor(color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade500,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected ? Icon(Icons.check, color: fg) : null,
              ),
            ),
            if (onDelete != null)
              Positioned(
                right: -6,
                top: -6,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ],
    );
  }

  Widget _addSwatch(BuildContext context, String lang, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade500, width: 1.5),
            ),
            child: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 4),
        Text(getText(lang, 'add_color'), style: const TextStyle(fontSize: 11)),
      ],
    );
  }

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

  Future<void> _showHexDialog(
    BuildContext context,
    SettingsProvider settings,
    String lang,
    _ColorTarget target,
  ) async {
    final start = _currentColor(settings, target) ?? Colors.blueAccent;
    final controller = TextEditingController(text: _toHex(start));
    Color preview = start;
    String? error;

    await showDialog<void>(
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
              final nr = r ?? (preview.toARGB32() >> 16) & 0xFF;
              final ng = g ?? (preview.toARGB32() >> 8) & 0xFF;
              final nb = b ?? preview.toARGB32() & 0xFF;
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
            final full = settings.savedAccentColors.length >= SettingsProvider.maxSavedColors;
            final alreadySaved =
                settings.savedAccentColors.any((c) => c.toARGB32() == preview.toARGB32());

            Color? validated() {
              final c = _parseHex(controller.text);
              if (c == null) {
                setLocal(() => error = getText(lang, 'hex_invalid'));
              }
              return c;
            }

            return AlertDialog(
              title: Text(getText(lang, 'add_color')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: preview,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade500),
                      ),
                      child: Text(
                        '#${_toHex(preview)}',
                        style: TextStyle(
                          color: SettingsProvider.contrastColor(preview),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    _slider(getText(lang, 'color_red'), r, Colors.red, (v) => updateFromSliders(r: v)),
                    _slider(getText(lang, 'color_green'), g, Colors.green, (v) => updateFromSliders(g: v)),
                    _slider(getText(lang, 'color_blue'), b, Colors.blue, (v) => updateFromSliders(b: v)),
                    if (full && !alreadySaved)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          getText(lang, 'save_full'),
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(getText(lang, 'cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    final c = validated();
                    if (c == null) return;
                    await _apply(settings, target, c);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text(getText(lang, 'use_color')),
                ),
                ElevatedButton(
                  onPressed: (full && !alreadySaved)
                      ? null
                      : () async {
                          final c = validated();
                          if (c == null) return;
                          await settings.addSavedColor(c);
                          await _apply(settings, target, c);
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(getText(lang, 'color_saved'))),
                            );
                          }
                        },
                  child: Text(getText(lang, 'save_and_use')),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Widget _slider(String label, int value, Color activeColor, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: activeColor,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 30, child: Text('$value', style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}