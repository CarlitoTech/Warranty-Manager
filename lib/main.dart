import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 

import 'Grundgeruest/add_screen.dart';
import 'Grundgeruest/detail_screen.dart';
import 'Grundgeruest/expiry_screen.dart';
import 'Grundgeruest/setting_screen.dart';
import 'Grundgeruest/splash_screen.dart';
import 'Grundgeruest/notification_service.dart';
import 'Grundgeruest/settings_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart'; 

import 'Manual/tutorial.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      onGenerateTitle: (context) => getText(settings.languageCode, 'app_title'),
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode, 
      
      locale: Locale(settings.languageCode),
      supportedLocales: const [
        Locale('de', ''),
        Locale('en', ''),
        Locale('fr', ''),
        Locale('es', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}

class GarantieApp extends StatelessWidget {
  const GarantieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<Map<String, String>>? preloadedListe;
  final String? preloadedDocPath;

  const HomeScreen({
    super.key,
    this.preloadedListe,
    this.preloadedDocPath,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _gerateListe = [];
  bool _isLoading = true; 
  String _appDocPath = '';
  
  bool _isTutorialActive = false;

  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _demoDeviceKey = GlobalKey(); 
  final GlobalKey _editButtonKey = GlobalKey();
  final GlobalKey _deleteButtonKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();

  final Set<String> _ausgewaehlteKategorien = {}; 
  
  final TextEditingController _suchController = TextEditingController();
  String _suchText = '';

  final List<String> _filterKategorieKeys = [
    'electronics', 'furniture', 'household', 'others', 'expired_cat'
  ];
  
  @override
  void initState() {
    super.initState();
    
    if (widget.preloadedListe != null && widget.preloadedDocPath != null) {
      _gerateListe = widget.preloadedListe!;
      _appDocPath = widget.preloadedDocPath!;
      _isLoading = false; 
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startApp();
    });

    _suchController.addListener(() {
      if (mounted && _suchText != _suchController.text) {
        setState(() {
          _suchText = _suchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _suchController.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    if (widget.preloadedListe == null || widget.preloadedDocPath == null) {
      await _initDocPath();
      await _ladeListe();
    }
    
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstStart = prefs.getBool('is_first_start') ?? true;

    if (isFirstStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _fordereBenachrichtigungDirektAn();
        if (!mounted) return;

        final String osLang = Platform.localeName.split('_')[0].toLowerCase();
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        
        if (['de', 'en', 'fr', 'es'].contains(osLang)) {
          await settings.setLanguage(osLang);
        } else {
          await _zeigeSprachAuswahl(); 
        }
        
        if (!mounted) return;
        await _zeigeWaehrungsAuswahlStart();
        
        await prefs.setBool('is_first_start', false);
        _starteTutorialKomplett();
      });
    }
  }

  Future<void> _fordereBenachrichtigungDirektAn() async {
    if (Platform.isAndroid) {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _zeigeSprachAuswahl() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'select_language'), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Deutsch', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)), onTap: () { settings.setLanguage('de'); Navigator.of(dialogContext).pop(); }),
              ListTile(title: const Text('English', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)), onTap: () { settings.setLanguage('en'); Navigator.of(dialogContext).pop(); }),
              ListTile(title: const Text('Français', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)), onTap: () { settings.setLanguage('fr'); Navigator.of(dialogContext).pop(); }),
              ListTile(title: const Text('Español', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)), onTap: () { settings.setLanguage('es'); Navigator.of(dialogContext).pop(); }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _zeigeWaehrungsAuswahlStart() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'currency'), textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: appCurrencies.length,
              itemBuilder: (context, index) {
                final item = appCurrencies[index];
                return ListTile(
                  title: Text('${getText(lang, item['label_key']!)} (${item['symbol']})'),
                  trailing: Text(item['symbol']!, style: const TextStyle(color: Colors.grey)),
                  onTap: () {
                    settings.setCurrency(item['symbol']!);
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _starteTutorialKomplett() {
    FocusManager.instance.primaryFocus?.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isTutorialActive = true; 
        });
      }
    });

    TutorialHelper.onTutorialAbbruch = () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _gerateListe.removeWhere((g) => g['isDemo'] == 'true');
              _isTutorialActive = false;
            });
            _speichereListe();
          }
        });
      }
    };

    TutorialHelper.zeigeHauptTutorial(
      context: context,
      filterKey: _filterKey,
      addKey: _addKey,
      onDemoGeraetErstellt: (demoGerat) async {
        final Map<String, String> angepasstesDemoGerat = Map.from(demoGerat);
        angepasstesDemoGerat['bildPfade'] = '';
        angepasstesDemoGerat['isDemo'] = 'true';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _gerateListe.insert(0, angepasstesDemoGerat);
            });
          }
        });

        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        TutorialHelper.zeigeHomeKlickDetailTutorial(
          context: context,
          demoDeviceKey: _demoDeviceKey,
          onKlickDetail: () async {
            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  gerat: angepasstesDemoGerat,
                  isFromTutorial: true,
                  onEdit: () {},
                ),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;

            TutorialHelper.zeigeHomeBearbeitenLoeschenGlockeTutorial(
              context: context,
              editButtonKey: _editButtonKey,
              deleteButtonKey: _deleteButtonKey,
              notificationsKey: _notificationsKey,
              onOpenExpiry: () async {
                if (!mounted) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpiryScreen(
                      gerateListe: _gerateListe,
                      isFromTutorial: true,
                    ),
                  ),
                );

                await Future.delayed(const Duration(milliseconds: 300));
                if (!mounted) return;

                TutorialHelper.zeigeHomeSettingsUndEndeTutorial(
                  context: context,
                  settingsKey: _settingsKey,
                  hauptBildschirmKey: _filterKey,
                  onTutorialFinished: () {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            if (_gerateListe.isNotEmpty) {
                              _gerateListe.removeWhere((g) => g['isDemo'] == 'true');
                            }
                            _isTutorialActive = false;
                          });
                          _speichereListe();
                        }
                      });
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _initDocPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (mounted) {
        setState(() {
          _appDocPath = directory.path;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _ladeListe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); 
      
      final String? gespeicherterString = prefs.getString('gerate_liste');

      if (gespeicherterString != null && gespeicherterString.isNotEmpty) {
        final dynamic decodedData = await compute(jsonDecode, gespeicherterString);
        final List<dynamic> jsonListe = decodedData as List<dynamic>;
        
        if (mounted) {
          setState(() {
            _gerateListe = jsonListe.map((item) => Map<String, String>.from(item)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _gerateListe = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _speichereListe() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = await compute(jsonEncode, _gerateListe);
    await prefs.setString('gerate_liste', jsonString);
  }

  DateTime? _parseDatum(String? d) {
    if (d == null) return null;
    final p = d.split('.');
    if (p.length == 3) return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    return null;
  }

  String formatiereDatumStr(String? d) {
    if(d == null || d.isEmpty) return '-';
    final p = d.split('.');
    if(p.length == 3) {
      return '${p[0].padLeft(2, '0')}.${p[1].padLeft(2, '0')}.${p[2]}';
    }
    return d;
  }

  List<Map<String, String>> get _gefilterteGerate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    List<Map<String, String>> gefiltert = _gerateListe.where((gerat) {
      if (_isTutorialActive) return true;

      final ad = _parseDatum(gerat['ablaufDatum']);
      final isExpired = ad != null && ad.isBefore(today);

      final query = _suchText.toLowerCase().trim();
      final name = gerat['name']?.toLowerCase() ?? '';
      final woGekauft = gerat['woGekauft']?.toLowerCase() ?? '';
      final kauf = gerat['kaufDatum']?.toLowerCase() ?? '';
      final ablauf = gerat['ablaufDatum']?.toLowerCase() ?? '';

      final matchesSearch = query.isEmpty || 
                            name.contains(query) || 
                            woGekauft.contains(query) ||
                            kauf.contains(query) ||
                            ablauf.contains(query);

      if (!matchesSearch) return false;

      if (_ausgewaehlteKategorien.isEmpty) {
        if (isExpired) return false;
      } else {
        bool isExpiredSelected = _ausgewaehlteKategorien.contains('expired_cat');
        bool catMatch = _ausgewaehlteKategorien.contains(gerat['kategorie']);
        
        if (isExpiredSelected) {
          if (_ausgewaehlteKategorien.length == 1) {
            if (!isExpired) return false;
          } else {
            if (!isExpired && !catMatch) return false;
          }
        } else {
          if (isExpired) return false;
          if (!catMatch) return false;
        }
      }

      return true;
    }).toList();

    switch (settings.sortOrder) {
      case 'z_a':
        gefiltert.sort((a, b) => (b['name'] ?? '').toLowerCase().compareTo((a['name'] ?? '').toLowerCase()));
        break;
      case 'newest':
        gefiltert.sort((a, b) {
          final da = _parseDatum(a['kaufDatum']) ?? DateTime(1900);
          final db = _parseDatum(b['kaufDatum']) ?? DateTime(1900);
          return db.compareTo(da);
        });
        break;
      case 'oldest':
        gefiltert.sort((a, b) {
          final da = _parseDatum(a['kaufDatum']) ?? DateTime(1900);
          final db = _parseDatum(b['kaufDatum']) ?? DateTime(1900);
          return da.compareTo(db);
        });
        break;
      case 'expiry_asc':
        gefiltert.sort((a, b) {
          final da = _parseDatum(a['ablaufDatum']) ?? DateTime(2099);
          final db = _parseDatum(b['ablaufDatum']) ?? DateTime(2099);
          return da.compareTo(db);
        });
        break;
      case 'a_z':
      default:
        gefiltert.sort((a, b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));
        break;
    }

    if (_isTutorialActive) {
      final demoIndex = gefiltert.indexWhere((g) => g['isDemo'] == 'true');
      if (demoIndex != -1) {
        final demoDevice = gefiltert.removeAt(demoIndex);
        gefiltert.insert(0, demoDevice);
      }
    }

    return gefiltert;
  }

  Future<void> _geratLoeschen(Map<String, String> gerat) async {
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;
    
    final bool? loeschenBestaetigt = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getText(lang, 'delete_device_title')),
          content: Text(getText(lang, 'delete_device_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(getText(lang, 'cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(getText(lang, 'delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (loeschenBestaetigt == true) {
      try {
        if (gerat['notificationId'] != null) {
          final int? id = int.tryParse(gerat['notificationId']!);
          if (id != null) {
            await NotificationService().cancelNotification(id);
          }
        }
      } catch (e) {
       // ignore
      }

      if (mounted) {
        setState(() {
          _gerateListe.remove(gerat); 
          _gerateListe.removeWhere((g) => 
            g['name'] == gerat['name'] && 
            g['kaufDatum'] == gerat['kaufDatum'] && 
            g['ablaufDatum'] == gerat['ablaufDatum'] &&
            g['woGekauft'] == gerat['woGekauft']
          );
        });
        await _speichereListe();
      }
    }
  }

  Future<void> _geratBearbeiten(Map<String, String> gerat) async {
    final originalGeratStr = jsonEncode(gerat);

    final aktualisiertesGerat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddScreen(
          bearbeitenGerat: gerat,
          existingDevices: _gerateListe,
        ),
      ),
    );

    if (aktualisiertesGerat != null && aktualisiertesGerat is Map<String, String>) {
      int index = _gerateListe.indexOf(gerat);
      if (index == -1) {
        index = _gerateListe.indexWhere((g) => jsonEncode(g) == originalGeratStr);
      }
      
      if (index != -1 && mounted) {
        setState(() {
          _gerateListe[index] = aktualisiertesGerat;
        });
        await _speichereListe();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gefilterteListe = _gefilterteGerate;
    
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;
    final useAmPm = settings.useAmPm; 

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return PopScope(
      canPop: !_isTutorialActive,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          title: Text(getText(lang, 'app_title')),
          toolbarHeight: isLandscape ? 40.0 : 56.0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          key: _filterKey,
                          width: double.infinity,
                          child: Column(
                            children: [
                              TextField(
                                controller: _suchController,
                                readOnly: _isTutorialActive,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                onChanged: (wert) {
                                  setState(() {
                                    _suchText = wert;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: getText(lang, 'search_hint'), 
                                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 20),
                                  suffixIcon: _suchText.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: _isTutorialActive ? () {} : () {
                                            _suchController.clear();
                                            setState(() => _suchText = '');
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                height: 45,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _filterKategorieKeys.length,
                                  itemBuilder: (context, index) {
                                    final katKey = _filterKategorieKeys[index];
                                    final istAusgewaehlt = _ausgewaehlteKategorien.contains(katKey);

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: FilterChip(
                                        label: Text(getText(lang, katKey)),
                                        selected: istAusgewaehlt,
                                        selectedColor: Colors.blueAccent,
                                        checkmarkColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: istAusgewaehlt
                                              ? Colors.white
                                              : Theme.of(context).textTheme.bodyMedium?.color,
                                          fontWeight: istAusgewaehlt ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        backgroundColor: Theme.of(context).cardColor,
                                        onSelected: _isTutorialActive 
                                          ? (selected) {} 
                                          : (selected) {
                                            setState(() {
                                              if (selected) {
                                                _ausgewaehlteKategorien.add(katKey);
                                              } else {
                                                _ausgewaehlteKategorien.remove(katKey);
                                              }
                                            });
                                          },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Expanded(
                          child: gefilterteListe.isEmpty
                              ? (_gerateListe.isEmpty
                                  ? Center(
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.devices_other_rounded, size: 80, color: Colors.grey[400]),
                                              const SizedBox(height: 20),
                                              Text(
                                                getText(lang, 'no_devices'),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                getText(lang, 'no_devices_desc'),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                                              ),
                                              const SizedBox(height: 24)
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: SingleChildScrollView( 
                                        child: Text(getText(lang, 'no_search_results')),
                                      ),
                                    ))
                              : ListView.builder(
                                  itemCount: gefilterteListe.length,
                                  itemBuilder: (context, index) {
                                    final gerat = gefilterteListe[index];
                                    final String? bildPfadeText = gerat['bildPfade'];
                                    final List<String> pfade = (bildPfadeText != null && bildPfadeText.isNotEmpty)
                                        ? bildPfadeText.split(',')
                                        : [];

                                    final ad = _parseDatum(gerat['ablaufDatum']);
                                    final now = DateTime.now();
                                    final isExpired = ad != null && ad.isBefore(DateTime(now.year, now.month, now.day));

                                    String woText = (gerat['woGekauft'] == 'Unbekannt' || gerat['woGekauft'] == null || gerat['woGekauft']!.isEmpty) 
                                        ? getText(lang, 'unknown') 
                                        : gerat['woGekauft']!;
                                    
                                    String waehrung = gerat['waehrung'] ?? settings.currencySymbol;
                                    String preis = gerat['preis'] ?? '';
                                    String preisText = (preis.isNotEmpty && preis != 'Unbekannt') ? '$preis $waehrung' : '';
                                    String ladenUndPreis = preisText.isNotEmpty ? '$woText  |  $preisText' : woText;

                                    return Card(
                                      key: (index == 0 && _isTutorialActive) ? _demoDeviceKey : null,
                                      elevation: 3,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: _isTutorialActive ? () {} : () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailScreen(
                                                gerat: gerat,
                                                onEdit: () => _geratBearbeiten(gerat),
                                              ),
                                            ),
                                          );
                                          if (mounted) setState(() {});
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 75,
                                                height: 75,
                                                child: pfade.isNotEmpty
                                                    ? Builder(
                                                        builder: (context) {
                                                          final anzahl = pfade.length;
                                                          return GridView.builder(
                                                            physics: const NeverScrollableScrollPhysics(),
                                                            padding: EdgeInsets.zero,
                                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: anzahl == 1 ? 1 : 2,
                                                              crossAxisSpacing: 3,
                                                              mainAxisSpacing: 3,
                                                              childAspectRatio: anzahl == 2 ? 0.5 : 1.0,
                                                            ),
                                                            itemCount: pfade.take(4).length,
                                                            itemBuilder: (context, imgIndex) {
                                                              final reinerName = pfade[imgIndex].trim();
                                                              final String vollstaendigerPfad =
                                                                  (reinerName.contains('/') || reinerName.contains('\\'))
                                                                      ? reinerName
                                                                      : '$_appDocPath/$reinerName';

                                                              final File imageFile = File(vollstaendigerPfad);
                                                              return ClipRRect(
                                                                borderRadius: BorderRadius.circular(4),
                                                                child: Image.file(
                                                                  imageFile,
                                                                  fit: BoxFit.cover,
                                                                  cacheWidth: 200, 
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Container(
                                                                      color: Colors.blue.withValues(alpha: 0.1),
                                                                      child: const Icon(Icons.receipt_long,
                                                                          size: 16, color: Colors.blueAccent),
                                                                    );
                                                                  },
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      )
                                                    : Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 28),
                                                      ),
                                              ),
                                              const SizedBox(width: 14),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      gerat['name'] ?? getText(lang, 'unknown'),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),

                                                    Row(
                                                      children: [
                                                        const Icon(Icons.store, size: 14, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            ladenUndPreis,
                                                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),

                                                    Row(
                                                      children: [
                                                        Icon(isExpired ? Icons.event_busy : Icons.date_range, size: 14, color: isExpired ? Colors.redAccent : Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            '${formatiereDatumStr(gerat['kaufDatum'])}  —  ${formatiereDatumStr(gerat['ablaufDatum'])}', 
                                                            style: TextStyle(
                                                              color: isExpired ? Colors.redAccent : Colors.grey[700],
                                                              fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                                              fontSize: 13,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),

                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Icon(Icons.notifications_active, size: 14, color: Colors.orangeAccent),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Builder(
                                                            builder: (context) {
                                                              String display = '${getText(lang, 'reminder')}: ${getText(lang, 'unknown')}';
                                                              final raw = gerat['erinnerung'];
                                                              
                                                              if (raw == null || raw == 'Nie') {
                                                                display = '${getText(lang, 'reminder')}: ${getText(lang, 'never')}';
                                                              } else {
                                                                try {
                                                                  final decoded = jsonDecode(raw);
                                                                  if (decoded['ausloeseZeit'] != null) {
                                                                    final dt = DateTime.parse(decoded['ausloeseZeit']);
                                                                    display = '${getText(lang, 'reminder')}: ${localizeReminderDate(dt, lang, useAmPm)}';
                                                                  }
                                                                } catch (_) {
                                                                  display = '${getText(lang, 'reminder')}: $raw';
                                                                }
                                                              }
                                                              return Text(
                                                                display,
                                                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                                                                overflow: TextOverflow.visible, 
                                                                softWrap: true,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    key: (index == 0 && _isTutorialActive) ? _editButtonKey : null,
                                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 22),
                                                    onPressed: _isTutorialActive ? () {} : () => _geratBearbeiten(gerat),
                                                  ),
                                                  IconButton(
                                                    key: (index == 0 && _isTutorialActive) ? _deleteButtonKey : null,
                                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                                    onPressed: _isTutorialActive ? () {} : () => _geratLoeschen(gerat),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          key: _addKey,
          backgroundColor: Colors.blueAccent,
          onPressed: _isTutorialActive ? () {} : () async {
            final neuesGerat = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddScreen(existingDevices: _gerateListe), 
              ),
            );

            if (neuesGerat != null && neuesGerat is Map<String, String>) {
              setState(() {
                _gerateListe.insert(0, neuesGerat);
              });
              _speichereListe();
            }
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          color: Theme.of(context).cardColor,
          height: isLandscape ? 48.0 : null,
          padding: isLandscape ? const EdgeInsets.symmetric(horizontal: 16.0) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              IconButton(
                key: _notificationsKey,
                icon: const Icon(Icons.notifications_active, color: Colors.blueAccent),
                onPressed: _isTutorialActive ? () {} : () async {
                  final aktualisierteListe = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpiryScreen(gerateListe: _gerateListe),
                    ),
                  );

                  if (aktualisierteListe != null && aktualisierteListe is List<Map<String, String>>) {
                    setState(() {
                      _gerateListe.clear();
                      _gerateListe.addAll(aktualisierteListe);
                    });
                    _speichereListe();
                  }
                },
              ),

              IconButton(
                key: _settingsKey,
                icon: const Icon(Icons.settings, color: Colors.blueAccent),
                onPressed: _isTutorialActive ? () {} : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        onRestartTutorial: () {
                          Navigator.pop(context); 
                          _starteTutorialKomplett(); 
                        },
                        onAllDataDeleted: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const SplashScreen()),
                            (route) => false,
                          );
                        },
                        onDataImported: () async {
                          Navigator.pop(context); 
                          await _ladeListe(); 
                          if (mounted) setState(() {}); 
                        }
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      )
    );
  }
}