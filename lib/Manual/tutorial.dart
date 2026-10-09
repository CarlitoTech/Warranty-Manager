import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:garantiemanager/Grundgeruest/add_screen.dart';
import 'package:provider/provider.dart'; 
import 'package:garantiemanager/Grundgeruest/settings_provider.dart'; 

class TutorialHelper {
  
  static bool isTutorialActive = false;
  // Wird genutzt um System-Pops zu blockieren, aber programmierte Pops auszuführen[cite: 8].
  static bool forcePopFlag = false; 
  // Globaler Callback, um bei Abbruch den Demoeintrag zu killen[cite: 8]
  static VoidCallback? onTutorialAbbruch;

  static Future<void> _sperreQuerformat() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await Future.delayed(const Duration(milliseconds: 200)); 
  }

  static Future<void> _freigebenOrientierung() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Zentralisierter Abbruch-Ablauf[cite: 8]
  static void abbruch(BuildContext context) {
    isTutorialActive = false;
    _freigebenOrientierung();
    onTutorialAbbruch?.call();
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  // 0. Willkommen-Screen (erscheint automatisch vor dem ersten Tutorial-Schritt)
  // Gibt true zurück, wenn der Nutzer starten will, false bei "Überspringen".
  static Future<bool> _zeigeWillkommen(BuildContext context, String lang) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.8),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PopScope(
          canPop: false,
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 64),
                          const SizedBox(height: 20),
                          Text(
                            getText(lang, 'tut_welcome_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            getText(lang, 'tut_welcome_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: Text(getText(lang, 'tut_welcome_start')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 12,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        getText(lang, 'tut_skip'),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
    return result ?? false;
  }

  // 1. Haupt-Tutorial (Suchleiste & + Button)[cite: 8]
  static Future<void> zeigeHauptTutorial({
    required BuildContext context,
    required GlobalKey filterKey,
    required GlobalKey addKey,
    required Function(Map<String, String>) onDemoGeraetErstellt,
  }) async {
    isTutorialActive = true; 
    FocusManager.instance.primaryFocus?.unfocus();

    await _sperreQuerformat(); 
    if (!context.mounted) return;
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;

    // Willkommen-Screen: erscheint automatisch, kein zusätzlicher Klick nötig, um das Tutorial zu beginnen
    final bool tutorialStarten = await _zeigeWillkommen(context, lang);
    if (!tutorialStarten) {
      // Nutzer hat auf "Überspringen" getippt -> Tutorial komplett abbrechen
      isTutorialActive = false;
      _freigebenOrientierung();
      onTutorialAbbruch?.call();
      return;
    }
    if (!context.mounted) return;

    late TutorialCoachMark tutorial;
    
    bool naechsterSchrittGestartet = false; 

    void starteAddScreen() async {
      if (naechsterSchrittGestartet) return; 
      naechsterSchrittGestartet = true; 
      tutorial.finish();

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AddScreen(isFromTutorial: true),
        ),
      );
      if (!context.mounted) return;
      if (result != null && result is Map<String, String>) {
        onDemoGeraetErstellt(result);
      } else {
        abbruch(context);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final messTarget = TargetFocus(
        identify: "filter_measure",
        keyTarget: filterKey,
      );

      final aktuellePosition = getTargetCurrent(
        messTarget,
        rootOverlay: false,
      );

      if (aktuellePosition == null) {
        abbruch(context);
        return;
      }

      final screenWidth = MediaQuery.of(context).size.width;
      final targetWidth = screenWidth - 32.0;
      final targetLeft = 16.0;

      final filterPosition = TargetPosition(
        Size(targetWidth, aktuellePosition.size.height),
        Offset(targetLeft, aktuellePosition.offset.dy),
      );

      final targets = <TargetFocus>[
        TargetFocus(
          identify: "filter_target",
          keyTarget: null,
          targetPosition: filterPosition,
          shape: ShapeLightFocus.RRect,
          radius: 20.0,
          paddingFocus: 4.0,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getText(lang, 'tut_search_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getText(lang, 'tut_search_desc'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "add_target",
          keyTarget: addKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getText(lang, 'tut_add_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getText(lang, 'tut_add_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ];

      tutorial = TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black,
        opacityShadow: 0.8,
        useSafeArea: true,
        paddingFocus: 4.0,
        skipWidget: Text(
          getText(lang, 'tut_skip'),
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        alignSkip: Alignment.topRight,
        onFinish: () {
          if (!naechsterSchrittGestartet) {
            abbruch(context); 
          }
        },
        onSkip: () {
          abbruch(context);
          return true;
        },
        onClickTarget: (target) {
          if (target.identify == "add_target") {
            starteAddScreen();
          }
        },
        onClickOverlay: (target) {
          if (target.identify == "add_target") {
            starteAddScreen();
          }
        },
      );

      tutorial.show(
        context: context,
        rootOverlay: false,
      );
    });
  }

  // 2. AddDevice Tutorial[cite: 8]
  static Future<void> zeigeAddDeviceTutorial({
    required BuildContext context,
    required GlobalKey nameKey,
    required GlobalKey kaufdetailsKey,
    required GlobalKey garantieKey,
    required GlobalKey timerKey,
    required GlobalKey fotosKey,
    required GlobalKey saveKey,
    required Function() onSaveDemo,
  }) async {
    if (!isTutorialActive) return; 
    FocusManager.instance.primaryFocus?.unfocus();

    await _sperreQuerformat(); 

    late TutorialCoachMark tutorial;
    if (!context.mounted) return;
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;

    Future<void> scrollZu(GlobalKey zielKey) async {
      final targetContext = zielKey.currentContext;
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 400),
          alignment: 0.08,
          curve: Curves.easeInOut,
        );
      }
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: "name_target",
        keyTarget: nameKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Text(
              getText(lang, 'tut_name_desc'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "kaufdetails_target",
        keyTarget: kaufdetailsKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText(lang, 'tut_kauf_desc'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  getText(lang, 'tut_garantie_desc'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                )
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "timer_target",
        keyTarget: timerKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Text(
              getText(lang, 'tut_timer_desc'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "fotos_target",
        keyTarget: fotosKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Text(
              getText(lang, 'tut_foto_desc'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "save_target",
        keyTarget: saveKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Text(
              getText(lang, 'tut_save_desc'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ];

    bool isProcessing = false;
    void handleNext(TargetFocus target) {
      if (isProcessing) return;
      isProcessing = true;

      if (target.identify == "name_target") {
        scrollZu(kaufdetailsKey).then((_) => isProcessing = false);
      } else if (target.identify == "kaufdetails_target") {
        scrollZu(timerKey).then((_) => isProcessing = false); 
      } else if (target.identify == "timer_target") {
        scrollZu(fotosKey).then((_) => isProcessing = false);
      } else if (target.identify == "fotos_target") {
        scrollZu(saveKey).then((_) => isProcessing = false);
      } else if (target.identify == "save_target") {
        tutorial.finish();
        Future.delayed(const Duration(milliseconds: 200), () {
          onSaveDemo();
        });
      } else {
        isProcessing = false;
      }
    }

    tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      skipWidget: Text(
        getText(lang, 'tut_skip'),
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      alignSkip: Alignment.topRight,
      onFinish: () {},
      onSkip: () {
        abbruch(context);
        return true;
      },
      onClickTarget: handleNext,
      onClickOverlay: handleNext,
    );
    tutorial.show(context: context);
  }

  // 3. Zwischenschritt nach dem Speichern[cite: 8]
  static Future<void> zeigeHomeKlickDetailTutorial({
    required BuildContext context,
    required GlobalKey demoDeviceKey,
    required Function() onKlickDetail,
  }) async {
    if (!isTutorialActive) return;
    FocusManager.instance.primaryFocus?.unfocus();

    await _sperreQuerformat();
    if (!context.mounted) return;
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;
    late TutorialCoachMark tutorial;

    bool gestartet = false;
    void proceed() {
      if (gestartet) return;
      gestartet = true;
      tutorial.finish();
      onKlickDetail();
    }
    final targets = [
      TargetFocus(
        identify: "klick_detail_target",
        keyTarget: demoDeviceKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText(lang, 'tut_click_details_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  getText(lang, 'tut_click_details_desc'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      skipWidget: Text(
        getText(lang, 'tut_skip'),
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      alignSkip: Alignment.topRight,
      onFinish: proceed,
      onSkip: () {
        abbruch(context);
        return true; 
      },
      onClickTarget: (_) => proceed(),
      onClickOverlay: (_) => proceed(),
    );

    tutorial.show(context: context);
  }

  // 4. Detail-Tutorial[cite: 8]
  static Future<void> zeigeDetailTutorial({
    required BuildContext context,
    required GlobalKey downloadKey,
    required GlobalKey printKey,
    GlobalKey? infoKey,
    GlobalKey? backKey,
  }) async {
    if (!isTutorialActive) return;
    FocusManager.instance.primaryFocus?.unfocus();

    await _sperreQuerformat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      void startTutorial() {
        if (!context.mounted || !isTutorialActive) return;
        final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;
        late TutorialCoachMark tutorial;

        bool isEnded = false;
        void beenden() {
          if (isEnded) return;
          isEnded = true;
          tutorial.finish();
          if (context.mounted && Navigator.canPop(context)) {
            TutorialHelper.forcePopFlag = true;
            Navigator.pop(context);
            TutorialHelper.forcePopFlag = false;
          }
        }

        final targets = <TargetFocus>[];

        if (infoKey != null) {
          targets.add(
            TargetFocus(
              identify: "info_target",
              keyTarget: infoKey,
              shape: ShapeLightFocus.RRect,
              radius: 12,
              contents: [
                TargetContent(
                  align: ContentAlign.bottom,
                  builder: (context, controller) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getText(lang, 'tut_detail_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getText(lang, 'tut_detail_info_desc'),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        targets.addAll([
          TargetFocus(
            identify: "download_target",
            keyTarget: downloadKey,
            shape: ShapeLightFocus.Circle,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getText(lang, 'tut_download_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getText(lang, 'tut_download_desc'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TargetFocus(
            identify: "print_target",
            keyTarget: printKey,
            shape: ShapeLightFocus.Circle,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getText(lang, 'tut_print_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getText(lang, 'tut_print_desc'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]);

        if (backKey != null) {
          targets.add(
            TargetFocus(
              identify: "back_target",
              keyTarget: backKey,
              shape: ShapeLightFocus.Circle,
              contents: [
                TargetContent(
                  align: ContentAlign.bottom,
                  builder: (context, controller) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getText(lang, 'tut_back_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getText(lang, 'tut_back_desc'),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        tutorial = TutorialCoachMark(
          targets: targets,
          colorShadow: Colors.black,
          opacityShadow: 0.8,
          skipWidget: Text(
            getText(lang, 'tut_skip'),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          alignSkip: Alignment.bottomRight,
          onFinish: beenden,
          onSkip: () {
            abbruch(context);
            return true;
          },
        );

        tutorial.show(context: context);
      }

      final route = ModalRoute.of(context);
      final animation = route?.animation;

      if (animation != null && animation.status != AnimationStatus.completed) {
        void handler(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            animation.removeStatusListener(handler);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              startTutorial();
            });
          }
        }
        animation.addStatusListener(handler);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          startTutorial();
        });
      }
    });
  }

  // 5. Hauptscreen: Bearbeiten, Löschen und Glocke[cite: 8]
  static Future<void> zeigeHomeBearbeitenLoeschenGlockeTutorial({
    required BuildContext context,
    required GlobalKey editButtonKey,
    required GlobalKey deleteButtonKey,
    required GlobalKey notificationsKey,
    required Function() onOpenExpiry,
  }) async {
    if (!isTutorialActive) return;
    FocusManager.instance.primaryFocus?.unfocus();

    await _sperreQuerformat();
    if (!context.mounted) return;
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;
    late TutorialCoachMark tutorial;

    bool proceedDone = false;
    void proceed() {
      if (proceedDone) return;
      proceedDone = true;
      tutorial.finish();
      onOpenExpiry();
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: "edit_target",
        keyTarget: editButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText(lang, 'tut_edit_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  getText(lang, 'tut_edit_desc'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "delete_target",
        keyTarget: deleteButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText(lang, 'tut_del_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  getText(lang, 'tut_del_desc'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "bell_target",
        keyTarget: notificationsKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText(lang, 'tut_bell_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  getText(lang, 'tut_bell_desc'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
    ];

    void handleNext(TargetFocus target) {
      if (target.identify == "bell_target") {
        proceed();
      }
    }

    tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      skipWidget: Text(
        getText(lang, 'tut_skip'),
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      alignSkip: Alignment.topRight,
      onFinish: proceed,
      onSkip: () {
        abbruch(context);
        return true; 
      },
      onClickTarget: handleNext,
      onClickOverlay: handleNext,
    );

    tutorial.show(context: context);
  }

  // 6. Expiry-Tutorial[cite: 8]
  static Future<void> zeigeExpiryTutorial({
    required BuildContext context,
    required GlobalKey activeTabKey,
    required GlobalKey expiredTabKey,
    GlobalKey? eintragKey,
    GlobalKey? backKey,
  }) async {
    if (!isTutorialActive) return;
    FocusManager.instance.primaryFocus?.unfocus();

    await _sperreQuerformat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      void startTutorial() {
        if (!context.mounted || !isTutorialActive) return;
        final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;
        late TutorialCoachMark tutorial;

        bool isEnded = false;
        void beenden() {
          if (isEnded) return;
          isEnded = true;
          tutorial.finish();
          if (context.mounted && Navigator.canPop(context)) {
            TutorialHelper.forcePopFlag = true;
            Navigator.pop(context);
            TutorialHelper.forcePopFlag = false;
          }
        }

        final targets = <TargetFocus>[
          TargetFocus(
            identify: "active_tab_target",
            keyTarget: activeTabKey,
            shape: ShapeLightFocus.RRect,
            radius: 8,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getText(lang, 'tut_exp_active_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getText(lang, 'tut_exp_active_desc'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TargetFocus(
            identify: "expired_tab_target",
            keyTarget: expiredTabKey,
            shape: ShapeLightFocus.RRect,
            radius: 8,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getText(lang, 'tut_exp_expired_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getText(lang, 'tut_exp_expired_desc'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ];

        if (eintragKey != null) {
          targets.add(
            TargetFocus(
              identify: "eintrag_target",
              keyTarget: eintragKey,
              shape: ShapeLightFocus.RRect,
              radius: 12,
              contents: [
                TargetContent(
                  align: ContentAlign.bottom,
                  builder: (context, controller) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getText(lang, 'tut_exp_entry_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getText(lang, 'tut_exp_entry_desc'),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (backKey != null) {
          targets.add(
            TargetFocus(
              identify: "expiry_back_target",
              keyTarget: backKey,
              shape: ShapeLightFocus.Circle,
              contents: [
                TargetContent(
                  align: ContentAlign.bottom,
                  builder: (context, controller) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getText(lang, 'tut_back_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getText(lang, 'tut_back_desc'),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        tutorial = TutorialCoachMark(
          targets: targets,
          colorShadow: Colors.black,
          opacityShadow: 0.8,
          skipWidget: Text(
            getText(lang, 'tut_skip'),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          alignSkip: Alignment.topRight,
          onFinish: beenden,
          onSkip: () {
            abbruch(context);
            return true;
          },
        );

        tutorial.show(context: context);
      }

      final route = ModalRoute.of(context);
      final animation = route?.animation;

      if (animation != null && animation.status != AnimationStatus.completed) {
        void handler(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            animation.removeStatusListener(handler);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              startTutorial();
            });
          }
        }
        animation.addStatusListener(handler);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          startTutorial();
        });
      }
    });
  }

  // 7. Hauptscreen: Einstellungen erklären[cite: 8]
  static Future<void> zeigeHomeSettingsUndEndeTutorial({
    required BuildContext context,
    required GlobalKey settingsKey,
    required GlobalKey hauptBildschirmKey,
    required Function() onTutorialFinished,
  }) async {
    if (!isTutorialActive) return;
    FocusManager.instance.primaryFocus?.unfocus();

    await _sperreQuerformat();
    if (!context.mounted) return;
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;
    late TutorialCoachMark tutorial;

    bool beendetGestartet = false;
    void beenden() {
      if (beendetGestartet) return;
      beendetGestartet = true;
      tutorial.finish();
      isTutorialActive = false;
      _freigebenOrientierung();
      onTutorialFinished();
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: "settings_target",
        keyTarget: settingsKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText(lang, 'tut_set_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  getText(lang, 'tut_set_desc'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "end_target",
        keyTarget: hauptBildschirmKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText(lang, 'tut_set_end_title'), 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  getText(lang, 'tut_set_end_desc'), 
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    tutorial = TutorialCoachMark(
      targets: targets, 
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      skipWidget: Text(
        getText(lang, 'tut_skip'), 
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      alignSkip: Alignment.topRight,
      onFinish: beenden,
      onSkip: () {
        abbruch(context);
        return true;
      },
    );

    tutorial.show(context: context);
  }
}