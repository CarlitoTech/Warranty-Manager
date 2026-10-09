import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onRestartTutorial;
  final VoidCallback onAllDataDeleted;
  final VoidCallback onDataImported;

  const SettingsScreen({
    super.key,
    required this.onRestartTutorial,
    required this.onAllDataDeleted,
    required this.onDataImported,
  });

  // Liest die App-Version dynamisch aus der pubspec.yaml aus
  // Zeigt nur die Versionsnummer (z. B. "1.0.1") - ohne "Beta" und ohne interne Build-Nummer (+2)
  Future<String> _getAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      if (version.isNotEmpty) return version;
      return '1.0.1';
    } catch (e) {
      return '1.0.1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    final systemIsDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isDarkMode = settings.themeMode == ThemeMode.dark ||
        (settings.themeMode == ThemeMode.system && systemIsDark);

    final is12h = settings.useAmPm;

    return Scaffold(
      appBar: AppBar(
        title: Text(getText(lang, 'settings')),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Colors.orange),
                    title: Text(getText(lang, 'tutorial_restart')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: onRestartTutorial,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  getText(lang, 'appearance'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(getText(lang, 'dark_mode')),
                        subtitle: Text(getText(lang, 'dark_mode_desc')),
                        secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.indigo),
                        value: isDarkMode,
                        onChanged: (bool value) {
                          settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(is12h ? getText(lang, 'switch_to_24h') : getText(lang, 'switch_to_12h')),
                        secondary: const Icon(Icons.access_time, color: Colors.orangeAccent),
                        value: is12h,
                        onChanged: (bool value) {
                          settings.setUseAmPm(value);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.sort, color: Colors.deepPurple),
                        title: Text(getText(lang, 'sort_by')),
                        trailing: Text(
                          _getSortName(lang, settings.sortOrder),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          _zeigeSortierungsAuswahl(context, settings);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language, color: Colors.blue),
                        title: Text(getText(lang, 'language')),
                        trailing: Text(_getLanguageName(lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return SafeArea(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          getText(lang, 'select_language'),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      ListTile(title: const Text('Deutsch'), onTap: () { settings.setLanguage('de'); Navigator.pop(context); }),
                                      ListTile(title: const Text('English'), onTap: () { settings.setLanguage('en'); Navigator.pop(context); }),
                                      ListTile(title: const Text('Français'), onTap: () { settings.setLanguage('fr'); Navigator.pop(context); }),
                                      ListTile(title: const Text('Español'), onTap: () { settings.setLanguage('es'); Navigator.pop(context); }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.attach_money, color: Colors.green),
                        title: Text(getText(lang, 'currency')),
                        trailing: Text(
                          settings.currencySymbol,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onTap: () {
                          _zeigeWaehrungsAuswahl(context, settings);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  getText(lang, 'data_management'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.upload_file, color: Colors.teal),
                        title: Text(getText(lang, 'export_data')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _exportieren(context, lang);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.download_for_offline, color: Colors.amber),
                        title: Text(getText(lang, 'import_data')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _importieren(context, settings, lang);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        title: Text(
                          getText(lang, 'delete_all_data'),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                        onTap: () {
                          _alleDatenLoeschen(context, settings, lang);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  getText(lang, 'info'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
                        title: Text(getText(lang, 'app_version')),
                        trailing: FutureBuilder<String>(
                          future: _getAppVersion(),
                          builder: (context, snapshot) {
                            final versionText = snapshot.hasData ? 'v${snapshot.data}' : 'Lade...';
                            return Text(
                              versionText,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.new_releases, color: Colors.green),
                        title: Text(getText(lang, 'update_log')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: Text(getText(lang, 'update_log_title')),
                                content: Text(getText(lang, 'update_log_desc'), style: const TextStyle(height: 1.5)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: Text(getText(lang, 'ok')),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security, color: Colors.deepOrange),
                        title: Text(getText(lang, 'privacy_policy')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _zeigeDatenschutzerklaerung(context, lang);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.gavel, color: Colors.purple),
                        title: Text(getText(lang, 'imprint')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _zeigeImpressum(context, lang);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code, color: Colors.grey),
                        title: Text(getText(lang, 'licenses')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final version = await _getAppVersion();
                          if (!context.mounted) return;

                          showLicensePage(
                            context: context,
                            applicationName: getText(lang, 'app_title'),
                            applicationVersion: 'v$version',
                            applicationIcon: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset('assets/logo.png', width: 64, height: 64),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _exportieren(BuildContext context, String lang) async {
    final wahl = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getText(lang, 'export_data')),
          content: Text(getText(lang, 'export_method_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'share'),
              child: Text(getText(lang, 'export_share')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: Text(getText(lang, 'export_save')),
            ),
          ],
        );
      },
    );

    if (wahl == null) return;

    if (!context.mounted) return;
    _showLoading(context);
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      final stagingDir = Directory('${tempDir.path}/WarrantyManager_Staging');
      if (stagingDir.existsSync()) {
        stagingDir.deleteSync(recursive: true);
      }
      stagingDir.createSync();

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final prefsMap = <String, dynamic>{};
      for (String key in prefs.getKeys()) {
        prefsMap[key] = prefs.get(key);
      }
      final prefsFile = File('${stagingDir.path}/prefs_backup.json');
      await prefsFile.writeAsString(jsonEncode(prefsMap));

      if (docDir.existsSync()) {
        for (var entity in docDir.listSync(recursive: false)) {
          if (entity is File) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (fileName.isNotEmpty) {
              entity.copySync('${stagingDir.path}/$fileName');
            }
          }
        }
      }

      final zipPath = '${tempDir.path}/WarrantyManager_Backup.zip';

      await Future(() {
        var encoder = ZipFileEncoder();
        encoder.create(zipPath);
        encoder.addDirectorySync(stagingDir, includeDirName: false);
        encoder.closeSync();
      });

      if (!context.mounted) return;
      Navigator.pop(context);

      if (wahl == 'save') {
        final bytes = File(zipPath).readAsBytesSync();
        final saveResult = await FilePicker.saveFile(
          dialogTitle: getText(lang, 'backup_save_title'),
          fileName: 'WarrantyManager_Backup.zip',
          bytes: bytes,
        );

        if (saveResult != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getText(lang, 'export_success'))),
          );
        }
      } else {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(zipPath)],
            text: getText(lang, 'backup_share_text'),
          ),
        );

        if (result.status == ShareResultStatus.success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getText(lang, 'export_success'))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getText(lang, 'export_error')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importieren(BuildContext context, SettingsProvider settings, String lang) async {
    final wahl = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'import_data')),
          content: Text(getText(lang, 'import_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(getText(lang, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(getText(lang, 'import_select_file')),
            ),
          ],
        );
      },
    );

    if (wahl != true) return;

    List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (files.isNotEmpty && context.mounted) {
      _showLoading(context);
      await Future.delayed(const Duration(milliseconds: 50));

      try {
        final Uint8List bytes = await files.single.readAsBytes();

        final tempDir = await getTemporaryDirectory();
        final extractPath = Directory('${tempDir.path}/extracted_backup');

        if (extractPath.existsSync()) {
          extractPath.deleteSync(recursive: true);
        }
        extractPath.createSync();

        await Future(() {
          final archive = ZipDecoder().decodeBytes(bytes);

          for (final file in archive) {
            final filename = file.name;
            if (file.isFile) {
              final data = file.content as List<int>;
              final cleanName = filename.replaceAll('\\', '/').split('/').last;
              if (cleanName.isNotEmpty) {
                final outFile = File('${extractPath.path}/$cleanName');
                outFile.createSync(recursive: true);
                outFile.writeAsBytesSync(data);
              }
            }
          }
        });

        final docDir = await getApplicationDocumentsDirectory();
        final prefsFile = File('${extractPath.path}/prefs_backup.json');

        if (prefsFile.existsSync()) {
          final prefsString = prefsFile.readAsStringSync();
          final Map<String, dynamic> prefsMap = jsonDecode(prefsString);

          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          for (final key in prefsMap.keys) {
            var value = prefsMap[key];

            if (key == 'gerate_liste' && value is String) {
              final List<dynamic> gerate = jsonDecode(value);
              for (var g in gerate) {
                final pfade = g['bildPfade']?.toString() ?? '';
                if (pfade.isNotEmpty) {
                  final teile = pfade.split(',');
                  final neuePfade = teile.map((p) {
                    String fileName = p.trim();
                    if (fileName.contains('/')) fileName = fileName.split('/').last;
                    if (fileName.contains('\\')) fileName = fileName.split('\\').last;
                    return '${docDir.path}/$fileName';
                  }).join(',');
                  g['bildPfade'] = neuePfade;
                }
              }
              value = jsonEncode(gerate);
              await prefs.setString(key, value);
            } else {
              if (value is bool) {await prefs.setBool(key, value);}
              else if (value is int) {await prefs.setInt(key, value);}
              else if (value is double) {await prefs.setDouble(key, value);}
              else if (value is String) {await prefs.setString(key, value);}
              else if (value is List) {
                await prefs.setStringList(key, value.map((e) => e.toString()).toList());
              }
            }
          }
        }
        await Future(() {
          final extractedDir = Directory(extractPath.path);
          for (final entity in extractedDir.listSync(recursive: true)) {
            if (entity is File && !entity.path.endsWith('prefs_backup.json')) {
              final filename = entity.path.split(Platform.pathSeparator).last;
              if (filename.isNotEmpty) {
                final targetFile = File('${docDir.path}/$filename');
                entity.copySync(targetFile.path);
              }
            }
          }
        });

        await settings.loadSettings();

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getText(lang, 'import_success'))),
          );
          onDataImported();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getText(lang, 'import_error')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _alleDatenLoeschen(BuildContext context, SettingsProvider settings, String lang) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'delete_all_title')),
          content: Text(
            getText(lang, 'delete_all_desc'),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(getText(lang, 'cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await settings.deleteAllData();

                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('gerate_liste');
                await prefs.setBool('is_first_start', true);

                try {
                  final docDir = await getApplicationDocumentsDirectory();
                  if (docDir.existsSync()) {
                    for (var entity in docDir.listSync()) {
                      if (entity is File) {
                        entity.deleteSync();
                      } else if (entity is Directory) {
                        entity.deleteSync(recursive: true);
                      }
                    }
                  }
                } catch (e) {
                  // ignorieren
                }
                await settings.loadSettings();
                if (context.mounted) {
                  onAllDataDeleted();
                }
              },
              child: Text(
                getText(lang, 'delete_all_confirm'),
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _zeigeImpressum(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'imprint_title')),
          content: SingleChildScrollView(
            child: Text(
              getText(lang, 'imprint_text'),
              style: const TextStyle(height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(getText(lang, 'ok')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _zeigeDatenschutzerklaerung(BuildContext context, String lang) async {
    bool isOnline = false;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isOnline = true;
      }
    } on SocketException catch (_) {
      isOnline = false;
    }

    if (isOnline) {
      final Uri url = Uri.parse('https://sites.google.com/view/privacy-policy-warrantymanager');

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        //
      }
    }

    String assetPath;
    switch (lang) {
      case 'en': assetPath = 'assets/DSVG_ENG.txt'; break;
      case 'fr': assetPath = 'assets/DSVG_FR.txt'; break;
      case 'es': assetPath = 'assets/DSVG_ES.txt'; break;
      case 'de': default: assetPath = 'assets/DSVG_DE.txt'; break;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'privacy_policy_title')),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<String>(
              future: DefaultAssetBundle.of(dialogContext).loadString(assetPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(getText(lang, 'error_loading_file'));
                }
                return SingleChildScrollView(
                  child: Text(
                    snapshot.data ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(getText(lang, 'ok')),
            ),
          ],
        );
      },
    );
  }

  void _zeigeSortierungsAuswahl(BuildContext context, SettingsProvider settings) {
    final lang = settings.languageCode;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(getText(lang, 'sort_a_z')),
                trailing: settings.sortOrder == 'a_z' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                onTap: () { settings.setSortOrder('a_z'); Navigator.pop(context); },
              ),
              ListTile(
                title: Text(getText(lang, 'sort_z_a')),
                trailing: settings.sortOrder == 'z_a' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                onTap: () { settings.setSortOrder('z_a'); Navigator.pop(context); },
              ),
              ListTile(
                title: Text(getText(lang, 'sort_newest')),
                trailing: settings.sortOrder == 'newest' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                onTap: () { settings.setSortOrder('newest'); Navigator.pop(context); },
              ),
              ListTile(
                title: Text(getText(lang, 'sort_oldest')),
                trailing: settings.sortOrder == 'oldest' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                onTap: () { settings.setSortOrder('oldest'); Navigator.pop(context); },
              ),
              ListTile(
                title: Text(getText(lang, 'sort_expiry')),
                trailing: settings.sortOrder == 'expiry_asc' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                onTap: () { settings.setSortOrder('expiry_asc'); Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );
  }

  void _zeigeWaehrungsAuswahl(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    getText(settings.languageCode, 'currency'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: appCurrencies.length,
                    itemBuilder: (context, index) {
                      final item = appCurrencies[index];
                      final isSelected = settings.currencySymbol == item['symbol'];

                      return ListTile(
                        title: Text('${getText(settings.languageCode, item['label_key']!)} (${item['symbol']})'),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.blueAccent)
                            : Text(item['symbol']!, style: const TextStyle(color: Colors.grey)),
                        onTap: () {
                          settings.setCurrency(item['symbol']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getSortName(String lang, String order) {
    switch (order) {
      case 'z_a': return getText(lang, 'sort_z_a');
      case 'newest': return getText(lang, 'sort_newest');
      case 'oldest': return getText(lang, 'sort_oldest');
      case 'expiry_asc': return getText(lang, 'sort_expiry');
      case 'a_z': default: return getText(lang, 'sort_a_z');
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'fr': return 'Français';
      case 'es': return 'Español';
      case 'de': default: return 'Deutsch';
    }
  }
}