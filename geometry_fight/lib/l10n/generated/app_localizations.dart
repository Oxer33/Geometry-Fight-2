import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @petNameSlower.
  ///
  /// In it, this message translates to:
  /// **'RALLENTATORE'**
  String get petNameSlower;

  /// No description provided for @petNameBomber.
  ///
  /// In it, this message translates to:
  /// **'BOMBARDIERE'**
  String get petNameBomber;

  /// No description provided for @petNameRepulsor.
  ///
  /// In it, this message translates to:
  /// **'REPULSORE'**
  String get petNameRepulsor;

  /// No description provided for @skinDescMagma.
  ///
  /// In it, this message translates to:
  /// **'Roccia fusa incandescente — bagliore di lava'**
  String get skinDescMagma;

  /// No description provided for @skinDescFrost.
  ///
  /// In it, this message translates to:
  /// **'Ghiaccio cristallino bianco-azzurro'**
  String get skinDescFrost;

  /// No description provided for @skinDescToxic.
  ///
  /// In it, this message translates to:
  /// **'Verde acido radioattivo luminoso'**
  String get skinDescToxic;

  /// No description provided for @skinDescObsidian.
  ///
  /// In it, this message translates to:
  /// **'Ossidiana nera con riflessi viola'**
  String get skinDescObsidian;

  /// No description provided for @skinDescSolar.
  ///
  /// In it, this message translates to:
  /// **'Oro solare brillante e accecante'**
  String get skinDescSolar;

  /// No description provided for @skinDescAbyss.
  ///
  /// In it, this message translates to:
  /// **'Profondità abissale cangiante blu-teal'**
  String get skinDescAbyss;

  /// No description provided for @skinDescCosmos.
  ///
  /// In it, this message translates to:
  /// **'Nebulosa viola-rosa che fluisce'**
  String get skinDescCosmos;

  /// No description provided for @skinDescChrome.
  ///
  /// In it, this message translates to:
  /// **'Cromo metallico riflettente'**
  String get skinDescChrome;

  /// No description provided for @skinDescEmerald.
  ///
  /// In it, this message translates to:
  /// **'Smeraldo verde brillante'**
  String get skinDescEmerald;

  /// No description provided for @skinDescSunset.
  ///
  /// In it, this message translates to:
  /// **'Tramonto arancio-magenta sfumato'**
  String get skinDescSunset;

  /// No description provided for @skinDescSingularity.
  ///
  /// In it, this message translates to:
  /// **'Buco nero: disco d\'accrescimento orbitante + lente gravitazionale'**
  String get skinDescSingularity;

  /// No description provided for @skinDescSupernova.
  ///
  /// In it, this message translates to:
  /// **'Stella che collassa: nucleo bianco-oro + raggi pulsanti'**
  String get skinDescSupernova;

  /// No description provided for @skinDescStarforge.
  ///
  /// In it, this message translates to:
  /// **'Forgia stellare: scafo viola con campo di stelle scintillanti'**
  String get skinDescStarforge;

  /// No description provided for @skinDescTempest.
  ///
  /// In it, this message translates to:
  /// **'Tempesta: fulmini ramificati che avvolgono lo scafo'**
  String get skinDescTempest;

  /// No description provided for @skinDescSpectrum.
  ///
  /// In it, this message translates to:
  /// **'Rifrazione prismatica totale: schegge arcobaleno orbitanti'**
  String get skinDescSpectrum;

  /// No description provided for @skinDescHellfire.
  ///
  /// In it, this message translates to:
  /// **'Inferno: fiamme che lambiscono lo scafo + braci ascendenti'**
  String get skinDescHellfire;

  /// No description provided for @skinDescGlacier.
  ///
  /// In it, this message translates to:
  /// **'Ghiacciaio: scafo cristallino + schegge di ghiaccio + bagliore freddo'**
  String get skinDescGlacier;

  /// No description provided for @skinDescPlague.
  ///
  /// In it, this message translates to:
  /// **'Biorischio tossico: acido gocciolante + bolle gorgoglianti'**
  String get skinDescPlague;

  /// No description provided for @skinDescPhantom.
  ///
  /// In it, this message translates to:
  /// **'Spettro quantico: copie sfasate RGB che si separano'**
  String get skinDescPhantom;

  /// No description provided for @skinDescCelestial.
  ///
  /// In it, this message translates to:
  /// **'Aurora celeste: nastri di luce che fluiscono attorno allo scafo'**
  String get skinDescCelestial;

  /// No description provided for @trailDescEmber.
  ///
  /// In it, this message translates to:
  /// **'Braci ardenti rosso-arancio'**
  String get trailDescEmber;

  /// No description provided for @trailDescFrostbite.
  ///
  /// In it, this message translates to:
  /// **'Schegge di gelo bianco-azzurro'**
  String get trailDescFrostbite;

  /// No description provided for @trailDescVenom.
  ///
  /// In it, this message translates to:
  /// **'Veleno verde acido pulsante'**
  String get trailDescVenom;

  /// No description provided for @trailDescShadow.
  ///
  /// In it, this message translates to:
  /// **'Ombra scura con scintille viola'**
  String get trailDescShadow;

  /// No description provided for @trailDescSolarflare.
  ///
  /// In it, this message translates to:
  /// **'Brillamento oro-bianco accecante'**
  String get trailDescSolarflare;

  /// No description provided for @trailDescOceanic.
  ///
  /// In it, this message translates to:
  /// **'Onde blu-teal profonde'**
  String get trailDescOceanic;

  /// No description provided for @trailDescStarfield.
  ///
  /// In it, this message translates to:
  /// **'Stelle bianche su scia notturna'**
  String get trailDescStarfield;

  /// No description provided for @trailDescChromatic.
  ///
  /// In it, this message translates to:
  /// **'Aberrazione RGB velocissima'**
  String get trailDescChromatic;

  /// No description provided for @trailDescJade.
  ///
  /// In it, this message translates to:
  /// **'Giada verde brillante'**
  String get trailDescJade;

  /// No description provided for @trailDescDusk.
  ///
  /// In it, this message translates to:
  /// **'Crepuscolo arancio → magenta'**
  String get trailDescDusk;

  /// No description provided for @trailDescEventhorizon.
  ///
  /// In it, this message translates to:
  /// **'Particelle risucchiate in spirale verso un nucleo nero'**
  String get trailDescEventhorizon;

  /// No description provided for @trailDescNovablast.
  ///
  /// In it, this message translates to:
  /// **'Esplosioni di luce bianco-oro lungo la scia'**
  String get trailDescNovablast;

  /// No description provided for @trailDescCosmicdust.
  ///
  /// In it, this message translates to:
  /// **'Polvere stellare scintillante viola-blu'**
  String get trailDescCosmicdust;

  /// No description provided for @trailDescThunderbolt.
  ///
  /// In it, this message translates to:
  /// **'Fulmini ramificati elettrici che saltano'**
  String get trailDescThunderbolt;

  /// No description provided for @trailDescPrismflow.
  ///
  /// In it, this message translates to:
  /// **'Nastro arcobaleno rifratto che scorre'**
  String get trailDescPrismflow;

  /// No description provided for @trailDescMagmaflow.
  ///
  /// In it, this message translates to:
  /// **'Lava fusa con crepe incandescenti + braci'**
  String get trailDescMagmaflow;

  /// No description provided for @trailDescCryostorm.
  ///
  /// In it, this message translates to:
  /// **'Bufera di ghiaccio: schegge cristalline + gelo'**
  String get trailDescCryostorm;

  /// No description provided for @trailDescAcidspill.
  ///
  /// In it, this message translates to:
  /// **'Acido tossico gorgogliante con gocce'**
  String get trailDescAcidspill;

  /// No description provided for @trailDescWraith.
  ///
  /// In it, this message translates to:
  /// **'Scie spettrali sfumate che si separano'**
  String get trailDescWraith;

  /// No description provided for @trailDescStardust.
  ///
  /// In it, this message translates to:
  /// **'Polvere di stelle scintillante multicolore'**
  String get trailDescStardust;

  /// No description provided for @petDescSlower.
  ///
  /// In it, this message translates to:
  /// **'Crea un campo di rallentamento davanti alla navicella: i nemici che entrano nel campo si muovono al rallentatore.'**
  String get petDescSlower;

  /// No description provided for @petDescBomber.
  ///
  /// In it, this message translates to:
  /// **'Sgancia mine esplosive attorno al player: detonano al contatto coi nemici o a fine vita, infliggendo danno ad area.'**
  String get petDescBomber;

  /// No description provided for @petDescRepulsor.
  ///
  /// In it, this message translates to:
  /// **'Campo di forza che respinge i nemici vicini al player: nessun danno, puro controllo difensivo (opposto del Black Hole).'**
  String get petDescRepulsor;

  /// No description provided for @modeDescArenaShrink.
  ///
  /// In it, this message translates to:
  /// **'L\'arena si restringe nel tempo: lo spazio per schivare svanisce. Resisti il più a lungo possibile!'**
  String get modeDescArenaShrink;

  /// Application title shown in OS task switcher
  ///
  /// In it, this message translates to:
  /// **'Geometry Fight 2'**
  String get appTitle;

  /// No description provided for @menuPlay.
  ///
  /// In it, this message translates to:
  /// **'GIOCA'**
  String get menuPlay;

  /// No description provided for @menuShop.
  ///
  /// In it, this message translates to:
  /// **'SHOP'**
  String get menuShop;

  /// No description provided for @menuStore.
  ///
  /// In it, this message translates to:
  /// **'NEGOZIO'**
  String get menuStore;

  /// No description provided for @menuSettings.
  ///
  /// In it, this message translates to:
  /// **'IMPOSTAZIONI'**
  String get menuSettings;

  /// No description provided for @menuStats.
  ///
  /// In it, this message translates to:
  /// **'STATISTICHE'**
  String get menuStats;

  /// No description provided for @menuAchievements.
  ///
  /// In it, this message translates to:
  /// **'TROFEI'**
  String get menuAchievements;

  /// No description provided for @menuAchievementsAlt.
  ///
  /// In it, this message translates to:
  /// **'ACHIEVEMENT'**
  String get menuAchievementsAlt;

  /// No description provided for @menuLeaderboard.
  ///
  /// In it, this message translates to:
  /// **'CLASSIFICA'**
  String get menuLeaderboard;

  /// No description provided for @menuQuit.
  ///
  /// In it, this message translates to:
  /// **'ESCI'**
  String get menuQuit;

  /// No description provided for @diffEasy.
  ///
  /// In it, this message translates to:
  /// **'FACILE'**
  String get diffEasy;

  /// No description provided for @diffNormal.
  ///
  /// In it, this message translates to:
  /// **'NORMALE'**
  String get diffNormal;

  /// No description provided for @diffHard.
  ///
  /// In it, this message translates to:
  /// **'DIFFICILE'**
  String get diffHard;

  /// No description provided for @diffNightmare.
  ///
  /// In it, this message translates to:
  /// **'INCUBO'**
  String get diffNightmare;

  /// No description provided for @diffNext.
  ///
  /// In it, this message translates to:
  /// **'AVANTI'**
  String get diffNext;

  /// No description provided for @diffTitle.
  ///
  /// In it, this message translates to:
  /// **'DIFFICOLTÀ'**
  String get diffTitle;

  /// No description provided for @diffScoreMultiplier.
  ///
  /// In it, this message translates to:
  /// **'score'**
  String get diffScoreMultiplier;

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'IMPOSTAZIONI'**
  String get settingsTitle;

  /// No description provided for @settingsAudio.
  ///
  /// In it, this message translates to:
  /// **'AUDIO'**
  String get settingsAudio;

  /// No description provided for @settingsGameplay.
  ///
  /// In it, this message translates to:
  /// **'GAMEPLAY'**
  String get settingsGameplay;

  /// No description provided for @settingsMusic.
  ///
  /// In it, this message translates to:
  /// **'MUSICA'**
  String get settingsMusic;

  /// No description provided for @settingsSfx.
  ///
  /// In it, this message translates to:
  /// **'EFFETTI'**
  String get settingsSfx;

  /// No description provided for @settingsSfxLong.
  ///
  /// In it, this message translates to:
  /// **'EFFETTI SONORI'**
  String get settingsSfxLong;

  /// No description provided for @settingsVibration.
  ///
  /// In it, this message translates to:
  /// **'VIBRAZIONE'**
  String get settingsVibration;

  /// No description provided for @settingsShowFps.
  ///
  /// In it, this message translates to:
  /// **'MOSTRA FPS'**
  String get settingsShowFps;

  /// No description provided for @settingsLanguage.
  ///
  /// In it, this message translates to:
  /// **'LINGUA'**
  String get settingsLanguage;

  /// No description provided for @settingsCrashLogs.
  ///
  /// In it, this message translates to:
  /// **'CRASH LOGS'**
  String get settingsCrashLogs;

  /// No description provided for @settingsReset.
  ///
  /// In it, this message translates to:
  /// **'RESET DATI'**
  String get settingsReset;

  /// No description provided for @settingsDangerZone.
  ///
  /// In it, this message translates to:
  /// **'ZONA PERICOLOSA'**
  String get settingsDangerZone;

  /// No description provided for @settingsTestDebug.
  ///
  /// In it, this message translates to:
  /// **'TEST / DEBUG'**
  String get settingsTestDebug;

  /// No description provided for @settingsAddCredits.
  ///
  /// In it, this message translates to:
  /// **'+100K CREDITI'**
  String get settingsAddCredits;

  /// No description provided for @settingsResetPurchases.
  ///
  /// In it, this message translates to:
  /// **'RESET ACQUISTI'**
  String get settingsResetPurchases;

  /// No description provided for @settingsPurchasesReset.
  ///
  /// In it, this message translates to:
  /// **'Acquisti resettati!'**
  String get settingsPurchasesReset;

  /// No description provided for @settingsCreditsAdded.
  ///
  /// In it, this message translates to:
  /// **'+100K crediti! Totale: {total}'**
  String settingsCreditsAdded(int total);

  /// No description provided for @settingsCrashLogsTitle.
  ///
  /// In it, this message translates to:
  /// **'CRASH LOGS ({count})'**
  String settingsCrashLogsTitle(int count);

  /// No description provided for @settingsNoCrash.
  ///
  /// In it, this message translates to:
  /// **'Nessun crash registrato.\nSe il gioco crasha, apparirà qui.'**
  String get settingsNoCrash;

  /// No description provided for @settingsCopy.
  ///
  /// In it, this message translates to:
  /// **'COPIA'**
  String get settingsCopy;

  /// No description provided for @settingsDelete.
  ///
  /// In it, this message translates to:
  /// **'CANCELLA'**
  String get settingsDelete;

  /// No description provided for @settingsLogsCopied.
  ///
  /// In it, this message translates to:
  /// **'Logs copiati'**
  String get settingsLogsCopied;

  /// No description provided for @shopTitle.
  ///
  /// In it, this message translates to:
  /// **'SHOP'**
  String get shopTitle;

  /// No description provided for @shopGoldInsufficient.
  ///
  /// In it, this message translates to:
  /// **'Gold insufficiente!'**
  String get shopGoldInsufficient;

  /// No description provided for @shopEquip.
  ///
  /// In it, this message translates to:
  /// **'EQUIPAGGIA'**
  String get shopEquip;

  /// No description provided for @shopEquipped.
  ///
  /// In it, this message translates to:
  /// **'EQUIPAGGIATO'**
  String get shopEquipped;

  /// No description provided for @shopBuy.
  ///
  /// In it, this message translates to:
  /// **'ACQUISTA'**
  String get shopBuy;

  /// No description provided for @shopMaxLevel.
  ///
  /// In it, this message translates to:
  /// **'MAX'**
  String get shopMaxLevel;

  /// No description provided for @shopTabWeapons.
  ///
  /// In it, this message translates to:
  /// **'ARMI'**
  String get shopTabWeapons;

  /// No description provided for @shopTabSkins.
  ///
  /// In it, this message translates to:
  /// **'SKIN'**
  String get shopTabSkins;

  /// No description provided for @shopTabTrails.
  ///
  /// In it, this message translates to:
  /// **'SCIE'**
  String get shopTabTrails;

  /// No description provided for @shopTabPets.
  ///
  /// In it, this message translates to:
  /// **'PET'**
  String get shopTabPets;

  /// No description provided for @shopTabUpgrades.
  ///
  /// In it, this message translates to:
  /// **'UPGRADE'**
  String get shopTabUpgrades;

  /// No description provided for @shopTabModes.
  ///
  /// In it, this message translates to:
  /// **'MODALITÀ'**
  String get shopTabModes;

  /// No description provided for @shopPurchased.
  ///
  /// In it, this message translates to:
  /// **'Acquistato!'**
  String get shopPurchased;

  /// No description provided for @shopLocked.
  ///
  /// In it, this message translates to:
  /// **'BLOCCATO'**
  String get shopLocked;

  /// No description provided for @shopCost.
  ///
  /// In it, this message translates to:
  /// **'COSTO'**
  String get shopCost;

  /// No description provided for @shopLevel.
  ///
  /// In it, this message translates to:
  /// **'LIVELLO'**
  String get shopLevel;

  /// No description provided for @shopScrollMore.
  ///
  /// In it, this message translates to:
  /// **'Scorri per altro'**
  String get shopScrollMore;

  /// No description provided for @loadoutTitle.
  ///
  /// In it, this message translates to:
  /// **'PREPARAZIONE'**
  String get loadoutTitle;

  /// No description provided for @loadoutWeapon.
  ///
  /// In it, this message translates to:
  /// **'ARMA'**
  String get loadoutWeapon;

  /// No description provided for @loadoutPet.
  ///
  /// In it, this message translates to:
  /// **'PET'**
  String get loadoutPet;

  /// No description provided for @loadoutLocked.
  ///
  /// In it, this message translates to:
  /// **'Sblocca questa arma nello SHOP'**
  String get loadoutLocked;

  /// No description provided for @loadoutPetLocked.
  ///
  /// In it, this message translates to:
  /// **'Sblocca questo pet nello SHOP'**
  String get loadoutPetLocked;

  /// No description provided for @loadoutStart.
  ///
  /// In it, this message translates to:
  /// **'AVVIA PARTITA'**
  String get loadoutStart;

  /// No description provided for @loadoutPetNone.
  ///
  /// In it, this message translates to:
  /// **'NESSUNO'**
  String get loadoutPetNone;

  /// No description provided for @shopAlreadyMax.
  ///
  /// In it, this message translates to:
  /// **'{name} già al massimo!'**
  String shopAlreadyMax(String name);

  /// No description provided for @shopUpgradedToLevel.
  ///
  /// In it, this message translates to:
  /// **'{name} LIV {level}'**
  String shopUpgradedToLevel(String name, int level);

  /// No description provided for @shopLevelOf.
  ///
  /// In it, this message translates to:
  /// **'LIV {current} / {max}'**
  String shopLevelOf(int current, int max);

  /// No description provided for @shopBadgeNew.
  ///
  /// In it, this message translates to:
  /// **'NEW'**
  String get shopBadgeNew;

  /// No description provided for @shopBadgeUnlocked.
  ///
  /// In it, this message translates to:
  /// **'SBLOCCATO'**
  String get shopBadgeUnlocked;

  /// No description provided for @shopBuyWithCost.
  ///
  /// In it, this message translates to:
  /// **'ACQUISTA {cost}g'**
  String shopBuyWithCost(int cost);

  /// No description provided for @shopTapNodeForDetails.
  ///
  /// In it, this message translates to:
  /// **'TOCCA UN NODO PER VEDERE I DETTAGLI'**
  String get shopTapNodeForDetails;

  /// No description provided for @modeTitle.
  ///
  /// In it, this message translates to:
  /// **'MODALITÀ'**
  String get modeTitle;

  /// No description provided for @modeSelectTitle.
  ///
  /// In it, this message translates to:
  /// **'SELEZIONA MODALITÀ'**
  String get modeSelectTitle;

  /// No description provided for @modeEndless.
  ///
  /// In it, this message translates to:
  /// **'INFINITO'**
  String get modeEndless;

  /// No description provided for @modeBossRush.
  ///
  /// In it, this message translates to:
  /// **'BOSS RUSH'**
  String get modeBossRush;

  /// No description provided for @modeSurvival.
  ///
  /// In it, this message translates to:
  /// **'SOPRAVVIVENZA'**
  String get modeSurvival;

  /// No description provided for @modeChallenge.
  ///
  /// In it, this message translates to:
  /// **'SFIDA'**
  String get modeChallenge;

  /// No description provided for @modeClassic.
  ///
  /// In it, this message translates to:
  /// **'CLASSICA'**
  String get modeClassic;

  /// No description provided for @modePacifist.
  ///
  /// In it, this message translates to:
  /// **'PACIFISTA'**
  String get modePacifist;

  /// No description provided for @modeTimeAttack.
  ///
  /// In it, this message translates to:
  /// **'ATTACCO A TEMPO'**
  String get modeTimeAttack;

  /// No description provided for @modeZen.
  ///
  /// In it, this message translates to:
  /// **'ZEN'**
  String get modeZen;

  /// No description provided for @modeTunnel.
  ///
  /// In it, this message translates to:
  /// **'TUNNEL'**
  String get modeTunnel;

  /// No description provided for @modeDailyChallenge.
  ///
  /// In it, this message translates to:
  /// **'SFIDA GIORNALIERA'**
  String get modeDailyChallenge;

  /// No description provided for @modeWaves.
  ///
  /// In it, this message translates to:
  /// **'WAVES'**
  String get modeWaves;

  /// No description provided for @modeGravityInferno.
  ///
  /// In it, this message translates to:
  /// **'GRAVITY INFERNO'**
  String get modeGravityInferno;

  /// No description provided for @modeSnake.
  ///
  /// In it, this message translates to:
  /// **'SNAKE'**
  String get modeSnake;

  /// No description provided for @modeArenaShrink.
  ///
  /// In it, this message translates to:
  /// **'ARENA RIDOTTA'**
  String get modeArenaShrink;

  /// No description provided for @splashSkip.
  ///
  /// In it, this message translates to:
  /// **'SKIP'**
  String get splashSkip;

  /// No description provided for @splashTapToStart.
  ///
  /// In it, this message translates to:
  /// **'TOCCA PER INIZIARE'**
  String get splashTapToStart;

  /// No description provided for @modifiersTitle.
  ///
  /// In it, this message translates to:
  /// **'MODIFICATORI'**
  String get modifiersTitle;

  /// No description provided for @modifiersConfirm.
  ///
  /// In it, this message translates to:
  /// **'CONFERMA'**
  String get modifiersConfirm;

  /// No description provided for @back.
  ///
  /// In it, this message translates to:
  /// **'INDIETRO'**
  String get back;

  /// No description provided for @play.
  ///
  /// In it, this message translates to:
  /// **'GIOCA'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In it, this message translates to:
  /// **'PAUSA'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In it, this message translates to:
  /// **'RIPRENDI'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In it, this message translates to:
  /// **'RICOMINCIA'**
  String get restart;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'RIPROVA'**
  String get retry;

  /// No description provided for @quit.
  ///
  /// In it, this message translates to:
  /// **'ESCI'**
  String get quit;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'CHIUDI'**
  String get close;

  /// No description provided for @next.
  ///
  /// In it, this message translates to:
  /// **'AVANTI'**
  String get next;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @yes.
  ///
  /// In it, this message translates to:
  /// **'SÌ'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In it, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'CONFERMA'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'ANNULLA'**
  String get cancel;

  /// No description provided for @continueAction.
  ///
  /// In it, this message translates to:
  /// **'CONTINUA'**
  String get continueAction;

  /// No description provided for @score.
  ///
  /// In it, this message translates to:
  /// **'PUNTEGGIO'**
  String get score;

  /// No description provided for @wave.
  ///
  /// In it, this message translates to:
  /// **'ONDATA'**
  String get wave;

  /// No description provided for @lives.
  ///
  /// In it, this message translates to:
  /// **'VITE'**
  String get lives;

  /// No description provided for @level.
  ///
  /// In it, this message translates to:
  /// **'LIVELLO'**
  String get level;

  /// No description provided for @gold.
  ///
  /// In it, this message translates to:
  /// **'GOLD'**
  String get gold;

  /// No description provided for @geoms.
  ///
  /// In it, this message translates to:
  /// **'GEOMS'**
  String get geoms;

  /// No description provided for @best.
  ///
  /// In it, this message translates to:
  /// **'BEST'**
  String get best;

  /// No description provided for @kills.
  ///
  /// In it, this message translates to:
  /// **'KILLS'**
  String get kills;

  /// No description provided for @timeLabel.
  ///
  /// In it, this message translates to:
  /// **'TIME'**
  String get timeLabel;

  /// No description provided for @highScore.
  ///
  /// In it, this message translates to:
  /// **'RECORD'**
  String get highScore;

  /// No description provided for @newRun.
  ///
  /// In it, this message translates to:
  /// **'NUOVO RUN'**
  String get newRun;

  /// No description provided for @gameOver.
  ///
  /// In it, this message translates to:
  /// **'GAME OVER'**
  String get gameOver;

  /// No description provided for @newRecord.
  ///
  /// In it, this message translates to:
  /// **'NUOVO RECORD!'**
  String get newRecord;

  /// No description provided for @victory.
  ///
  /// In it, this message translates to:
  /// **'VITTORIA'**
  String get victory;

  /// No description provided for @achievementsTitle.
  ///
  /// In it, this message translates to:
  /// **'TROFEI'**
  String get achievementsTitle;

  /// No description provided for @achievementUnlocked.
  ///
  /// In it, this message translates to:
  /// **'Trofeo Sbloccato!'**
  String get achievementUnlocked;

  /// No description provided for @achievementCategoryCombat.
  ///
  /// In it, this message translates to:
  /// **'COMBATTIMENTO'**
  String get achievementCategoryCombat;

  /// No description provided for @achievementCategoryScore.
  ///
  /// In it, this message translates to:
  /// **'PUNTEGGIO'**
  String get achievementCategoryScore;

  /// No description provided for @achievementCategoryProgress.
  ///
  /// In it, this message translates to:
  /// **'PROGRESSO'**
  String get achievementCategoryProgress;

  /// No description provided for @achievementCategoryMastery.
  ///
  /// In it, this message translates to:
  /// **'MAESTRIA'**
  String get achievementCategoryMastery;

  /// No description provided for @achievementCategorySpecial.
  ///
  /// In it, this message translates to:
  /// **'SPECIALI'**
  String get achievementCategorySpecial;

  /// No description provided for @leaderboardTitle.
  ///
  /// In it, this message translates to:
  /// **'CLASSIFICA'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessun punteggio ancora'**
  String get leaderboardEmpty;

  /// No description provided for @statsTitle.
  ///
  /// In it, this message translates to:
  /// **'STATISTICHE'**
  String get statsTitle;

  /// No description provided for @summaryTitle.
  ///
  /// In it, this message translates to:
  /// **'RIEPILOGO'**
  String get summaryTitle;

  /// No description provided for @dailyRewardTitle.
  ///
  /// In it, this message translates to:
  /// **'DAILY REWARD'**
  String get dailyRewardTitle;

  /// No description provided for @dailyRewardGeoms.
  ///
  /// In it, this message translates to:
  /// **'+{amount} GEOM'**
  String dailyRewardGeoms(int amount);

  /// No description provided for @dailyRewardStreakOne.
  ///
  /// In it, this message translates to:
  /// **'Streak: {count} giorno'**
  String dailyRewardStreakOne(int count);

  /// No description provided for @dailyRewardStreakMany.
  ///
  /// In it, this message translates to:
  /// **'Streak: {count} giorni'**
  String dailyRewardStreakMany(int count);

  /// No description provided for @settingsResetTitle.
  ///
  /// In it, this message translates to:
  /// **'RESET DATI'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetWarning.
  ///
  /// In it, this message translates to:
  /// **'Tutti i progressi, upgrade e acquisti verranno cancellati.'**
  String get settingsResetWarning;

  /// No description provided for @settingsResetButton.
  ///
  /// In it, this message translates to:
  /// **'RESET'**
  String get settingsResetButton;

  /// No description provided for @settingsResetAllData.
  ///
  /// In it, this message translates to:
  /// **'RESET ALL DATA'**
  String get settingsResetAllData;

  /// No description provided for @badgeKiller.
  ///
  /// In it, this message translates to:
  /// **'KILLER'**
  String get badgeKiller;

  /// No description provided for @badgeMassacre.
  ///
  /// In it, this message translates to:
  /// **'MASSACRO'**
  String get badgeMassacre;

  /// No description provided for @badgePersistent.
  ///
  /// In it, this message translates to:
  /// **'PERSISTENTE'**
  String get badgePersistent;

  /// No description provided for @badgeVeteran.
  ///
  /// In it, this message translates to:
  /// **'VETERANO'**
  String get badgeVeteran;

  /// No description provided for @badgeBossHunter.
  ///
  /// In it, this message translates to:
  /// **'BOSS HUNTER'**
  String get badgeBossHunter;

  /// No description provided for @badgeRegicide.
  ///
  /// In it, this message translates to:
  /// **'REGICIDA'**
  String get badgeRegicide;

  /// No description provided for @newAchievementBanner.
  ///
  /// In it, this message translates to:
  /// **'★ NUOVO ACHIEVEMENT! ★'**
  String get newAchievementBanner;

  /// No description provided for @columnDate.
  ///
  /// In it, this message translates to:
  /// **'DATA'**
  String get columnDate;

  /// No description provided for @leaderboardRecords.
  ///
  /// In it, this message translates to:
  /// **'{count} REC'**
  String leaderboardRecords(int count);

  /// No description provided for @leaderboardNoRecord.
  ///
  /// In it, this message translates to:
  /// **'NESSUN RECORD'**
  String get leaderboardNoRecord;

  /// No description provided for @leaderboardEmptyHint.
  ///
  /// In it, this message translates to:
  /// **'Gioca in questa modalità\nper entrare in classifica!'**
  String get leaderboardEmptyHint;

  /// No description provided for @statsSectionGeneral.
  ///
  /// In it, this message translates to:
  /// **'GENERALE'**
  String get statsSectionGeneral;

  /// No description provided for @statsSectionCombat.
  ///
  /// In it, this message translates to:
  /// **'COMBATTIMENTO'**
  String get statsSectionCombat;

  /// No description provided for @statsSectionRecords.
  ///
  /// In it, this message translates to:
  /// **'RECORD'**
  String get statsSectionRecords;

  /// No description provided for @statsSectionAchievements.
  ///
  /// In it, this message translates to:
  /// **'ACHIEVEMENT'**
  String get statsSectionAchievements;

  /// No description provided for @statsSectionScoresByMode.
  ///
  /// In it, this message translates to:
  /// **'PUNTEGGI PER MODALITÀ'**
  String get statsSectionScoresByMode;

  /// No description provided for @statsGamesPlayed.
  ///
  /// In it, this message translates to:
  /// **'Partite giocate'**
  String get statsGamesPlayed;

  /// No description provided for @statsTotalPlaytime.
  ///
  /// In it, this message translates to:
  /// **'Tempo totale'**
  String get statsTotalPlaytime;

  /// No description provided for @statsTotalGoldEarned.
  ///
  /// In it, this message translates to:
  /// **'Gold totale guadagnato'**
  String get statsTotalGoldEarned;

  /// No description provided for @statsCurrentGold.
  ///
  /// In it, this message translates to:
  /// **'Gold attuale'**
  String get statsCurrentGold;

  /// No description provided for @statsEnemiesKilled.
  ///
  /// In it, this message translates to:
  /// **'Nemici uccisi'**
  String get statsEnemiesKilled;

  /// No description provided for @statsBossesDefeated.
  ///
  /// In it, this message translates to:
  /// **'Boss sconfitti'**
  String get statsBossesDefeated;

  /// No description provided for @statsBombsUsed.
  ///
  /// In it, this message translates to:
  /// **'Bombe usate'**
  String get statsBombsUsed;

  /// No description provided for @statsPowerUpsCollected.
  ///
  /// In it, this message translates to:
  /// **'Power-up raccolti'**
  String get statsPowerUpsCollected;

  /// No description provided for @statsGeomsCollected.
  ///
  /// In it, this message translates to:
  /// **'Geom raccolti'**
  String get statsGeomsCollected;

  /// No description provided for @statsBestScore.
  ///
  /// In it, this message translates to:
  /// **'Punteggio migliore'**
  String get statsBestScore;

  /// No description provided for @statsHighestWave.
  ///
  /// In it, this message translates to:
  /// **'Wave più alta'**
  String get statsHighestWave;

  /// No description provided for @statsMaxMultiplier.
  ///
  /// In it, this message translates to:
  /// **'Moltiplicatore massimo'**
  String get statsMaxMultiplier;

  /// No description provided for @statsMaxSessionKills.
  ///
  /// In it, this message translates to:
  /// **'Max kill in una partita'**
  String get statsMaxSessionKills;

  /// No description provided for @statsMaxPerfectStreak.
  ///
  /// In it, this message translates to:
  /// **'Max wave perfette'**
  String get statsMaxPerfectStreak;

  /// No description provided for @statsAchievementsUnlocked.
  ///
  /// In it, this message translates to:
  /// **'Sbloccati'**
  String get statsAchievementsUnlocked;

  /// No description provided for @summaryNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get summaryNone;

  /// No description provided for @summaryScoreMultiplierTitle.
  ///
  /// In it, this message translates to:
  /// **'MOLTIPLICATORE PUNTEGGIO'**
  String get summaryScoreMultiplierTitle;

  /// No description provided for @summaryDifficultyRow.
  ///
  /// In it, this message translates to:
  /// **'Difficoltà'**
  String get summaryDifficultyRow;

  /// No description provided for @summaryModifiersRow.
  ///
  /// In it, this message translates to:
  /// **'Modificatori'**
  String get summaryModifiersRow;

  /// No description provided for @summaryTotal.
  ///
  /// In it, this message translates to:
  /// **'TOTALE'**
  String get summaryTotal;

  /// No description provided for @summaryActiveModifiers.
  ///
  /// In it, this message translates to:
  /// **'{count} attivi · ×{mult} score'**
  String summaryActiveModifiers(int count, String mult);

  /// No description provided for @languageItalian.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageEnglish.
  ///
  /// In it, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In it, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In it, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In it, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languagePortuguese.
  ///
  /// In it, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageChinese.
  ///
  /// In it, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageJapanese.
  ///
  /// In it, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageRussian.
  ///
  /// In it, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @modifiersMaxActive.
  ///
  /// In it, this message translates to:
  /// **'MAX {count} MODIFICATORI'**
  String modifiersMaxActive(int count);

  /// No description provided for @modifiersScoreLabel.
  ///
  /// In it, this message translates to:
  /// **'Score x{mult}'**
  String modifiersScoreLabel(String mult);

  /// No description provided for @modifiersActiveCount.
  ///
  /// In it, this message translates to:
  /// **'Attivi: {count}/{max}'**
  String modifiersActiveCount(int count, int max);

  /// No description provided for @hudBossWave.
  ///
  /// In it, this message translates to:
  /// **'BOSS WAVE {wave}'**
  String hudBossWave(int wave);

  /// No description provided for @hudWaveNumber.
  ///
  /// In it, this message translates to:
  /// **'WAVE {wave}'**
  String hudWaveNumber(int wave);

  /// No description provided for @hudPerfectWave.
  ///
  /// In it, this message translates to:
  /// **'WAVE PERFETTA!'**
  String get hudPerfectWave;

  /// No description provided for @hudPerfectBonus.
  ///
  /// In it, this message translates to:
  /// **'+10 GEOMI BONUS'**
  String get hudPerfectBonus;

  /// No description provided for @hudEnemiesRemaining.
  ///
  /// In it, this message translates to:
  /// **'{count} NEMICI'**
  String hudEnemiesRemaining(int count);

  /// No description provided for @hudBoost2x.
  ///
  /// In it, this message translates to:
  /// **'2x BOOST'**
  String get hudBoost2x;

  /// No description provided for @powerUpRapidFire.
  ///
  /// In it, this message translates to:
  /// **'RAPID FIRE'**
  String get powerUpRapidFire;

  /// No description provided for @powerUpOverdrive.
  ///
  /// In it, this message translates to:
  /// **'OVERDRIVE'**
  String get powerUpOverdrive;

  /// No description provided for @powerUpMagnet.
  ///
  /// In it, this message translates to:
  /// **'MAGNETE'**
  String get powerUpMagnet;

  /// No description provided for @powerUpTimeSlow.
  ///
  /// In it, this message translates to:
  /// **'TIME SLOW'**
  String get powerUpTimeSlow;

  /// No description provided for @powerUpSpreadShot.
  ///
  /// In it, this message translates to:
  /// **'SPREAD SHOT'**
  String get powerUpSpreadShot;

  /// No description provided for @powerUpFirePower.
  ///
  /// In it, this message translates to:
  /// **'FIRE POWER'**
  String get powerUpFirePower;

  /// No description provided for @tutorialTitle.
  ///
  /// In it, this message translates to:
  /// **'COME GIOCARE'**
  String get tutorialTitle;

  /// No description provided for @tutorialLeftJoystick.
  ///
  /// In it, this message translates to:
  /// **'JOYSTICK SINISTRO'**
  String get tutorialLeftJoystick;

  /// No description provided for @tutorialLeftJoystickDesc.
  ///
  /// In it, this message translates to:
  /// **'Muovi la navicella'**
  String get tutorialLeftJoystickDesc;

  /// No description provided for @tutorialRightJoystick.
  ///
  /// In it, this message translates to:
  /// **'JOYSTICK DESTRO'**
  String get tutorialRightJoystick;

  /// No description provided for @tutorialRightJoystickDesc.
  ///
  /// In it, this message translates to:
  /// **'Mira e spara automaticamente'**
  String get tutorialRightJoystickDesc;

  /// No description provided for @tutorialBomb.
  ///
  /// In it, this message translates to:
  /// **'BOMBA'**
  String get tutorialBomb;

  /// No description provided for @tutorialBombDesc.
  ///
  /// In it, this message translates to:
  /// **'Distrugge tutti i nemici vicini'**
  String get tutorialBombDesc;

  /// No description provided for @tutorialGeoms.
  ///
  /// In it, this message translates to:
  /// **'GEOMI'**
  String get tutorialGeoms;

  /// No description provided for @tutorialGeomsDesc.
  ///
  /// In it, this message translates to:
  /// **'Raccoglili per punti e upgrade'**
  String get tutorialGeomsDesc;

  /// No description provided for @tutorialPowerUp.
  ///
  /// In it, this message translates to:
  /// **'POWER-UP'**
  String get tutorialPowerUp;

  /// No description provided for @tutorialPowerUpDesc.
  ///
  /// In it, this message translates to:
  /// **'Potenziamenti temporanei'**
  String get tutorialPowerUpDesc;

  /// No description provided for @tutorialTapToStart.
  ///
  /// In it, this message translates to:
  /// **'TOCCA PER INIZIARE'**
  String get tutorialTapToStart;

  /// No description provided for @skinNameClassic.
  ///
  /// In it, this message translates to:
  /// **'Classic'**
  String get skinNameClassic;

  /// No description provided for @skinDescClassic.
  ///
  /// In it, this message translates to:
  /// **'La navicella originale cyan'**
  String get skinDescClassic;

  /// No description provided for @skinNameStealth.
  ///
  /// In it, this message translates to:
  /// **'Stealth'**
  String get skinNameStealth;

  /// No description provided for @skinDescStealth.
  ///
  /// In it, this message translates to:
  /// **'Nera con bordi rossi — stile furtivo'**
  String get skinDescStealth;

  /// No description provided for @skinNameCrystal.
  ///
  /// In it, this message translates to:
  /// **'Crystal'**
  String get skinNameCrystal;

  /// No description provided for @skinDescCrystal.
  ///
  /// In it, this message translates to:
  /// **'Diamante prismatico — riflessi arcobaleno'**
  String get skinDescCrystal;

  /// No description provided for @skinNameGhost.
  ///
  /// In it, this message translates to:
  /// **'Ghost'**
  String get skinNameGhost;

  /// No description provided for @skinDescGhost.
  ///
  /// In it, this message translates to:
  /// **'Semi-trasparente con scia di particelle'**
  String get skinDescGhost;

  /// No description provided for @skinNameOmega.
  ///
  /// In it, this message translates to:
  /// **'Omega'**
  String get skinNameOmega;

  /// No description provided for @skinDescOmega.
  ///
  /// In it, this message translates to:
  /// **'Stella a 4 punte dorata — forma unica'**
  String get skinDescOmega;

  /// No description provided for @skinNamePhoenix.
  ///
  /// In it, this message translates to:
  /// **'Phoenix'**
  String get skinNamePhoenix;

  /// No description provided for @skinDescPhoenix.
  ///
  /// In it, this message translates to:
  /// **'Ali di fuoco con piume di brace — rinasce dalle ceneri'**
  String get skinDescPhoenix;

  /// No description provided for @skinNameCyber.
  ///
  /// In it, this message translates to:
  /// **'Cyber'**
  String get skinNameCyber;

  /// No description provided for @skinDescCyber.
  ///
  /// In it, this message translates to:
  /// **'Mesh circuiti neon verde — overlay digitale animato'**
  String get skinDescCyber;

  /// No description provided for @skinNameVoidwalker.
  ///
  /// In it, this message translates to:
  /// **'Voidwalker'**
  String get skinNameVoidwalker;

  /// No description provided for @skinDescVoidwalker.
  ///
  /// In it, this message translates to:
  /// **'Nucleo viola sospeso nel vuoto — alone etereo'**
  String get skinDescVoidwalker;

  /// No description provided for @skinNameAurora.
  ///
  /// In it, this message translates to:
  /// **'Aurora'**
  String get skinNameAurora;

  /// No description provided for @skinDescAurora.
  ///
  /// In it, this message translates to:
  /// **'Boreale: ciano/rosa/verde che fluiscono'**
  String get skinDescAurora;

  /// No description provided for @skinNameTactical.
  ///
  /// In it, this message translates to:
  /// **'Tactical'**
  String get skinNameTactical;

  /// No description provided for @skinDescTactical.
  ///
  /// In it, this message translates to:
  /// **'Corazza militare grigio/blu — placche corazzate'**
  String get skinDescTactical;

  /// No description provided for @skinNamePrism.
  ///
  /// In it, this message translates to:
  /// **'Prism'**
  String get skinNamePrism;

  /// No description provided for @skinDescPrism.
  ///
  /// In it, this message translates to:
  /// **'Cristallo poligonale — rifrazione arcobaleno multipla'**
  String get skinDescPrism;

  /// No description provided for @skinNameTron.
  ///
  /// In it, this message translates to:
  /// **'Tron'**
  String get skinNameTron;

  /// No description provided for @skinDescTron.
  ///
  /// In it, this message translates to:
  /// **'Body nero con linee neon ciano — circuit grid digitale'**
  String get skinDescTron;

  /// No description provided for @skinNameSamurai.
  ///
  /// In it, this message translates to:
  /// **'Samurai'**
  String get skinNameSamurai;

  /// No description provided for @skinDescSamurai.
  ///
  /// In it, this message translates to:
  /// **'Corazza nera con dettagli oro/rosso — onore e battaglia'**
  String get skinDescSamurai;

  /// No description provided for @skinNameRosegold.
  ///
  /// In it, this message translates to:
  /// **'RoseGold'**
  String get skinNameRosegold;

  /// No description provided for @skinDescRosegold.
  ///
  /// In it, this message translates to:
  /// **'Metallico rosa-oro — eleganza moderna'**
  String get skinDescRosegold;

  /// No description provided for @skinNameNinja.
  ///
  /// In it, this message translates to:
  /// **'Ninja'**
  String get skinNameNinja;

  /// No description provided for @skinDescNinja.
  ///
  /// In it, this message translates to:
  /// **'Grigio ombra con accenti shuriken — silenzioso e letale'**
  String get skinDescNinja;

  /// No description provided for @skinNameGlitch.
  ///
  /// In it, this message translates to:
  /// **'Glitch'**
  String get skinNameGlitch;

  /// No description provided for @skinDescGlitch.
  ///
  /// In it, this message translates to:
  /// **'RGB chromatic shift — aberration animata'**
  String get skinDescGlitch;

  /// No description provided for @trailNameNormal.
  ///
  /// In it, this message translates to:
  /// **'Normal'**
  String get trailNameNormal;

  /// No description provided for @trailDescNormal.
  ///
  /// In it, this message translates to:
  /// **'Scia cyan standard'**
  String get trailDescNormal;

  /// No description provided for @trailNameFire.
  ///
  /// In it, this message translates to:
  /// **'Fire'**
  String get trailNameFire;

  /// No description provided for @trailDescFire.
  ///
  /// In it, this message translates to:
  /// **'Particelle di fuoco dietro la nave'**
  String get trailDescFire;

  /// No description provided for @trailNameIce.
  ///
  /// In it, this message translates to:
  /// **'Ice'**
  String get trailNameIce;

  /// No description provided for @trailDescIce.
  ///
  /// In it, this message translates to:
  /// **'Cristalli di ghiaccio scintillanti'**
  String get trailDescIce;

  /// No description provided for @trailNamePlasma.
  ///
  /// In it, this message translates to:
  /// **'Plasma'**
  String get trailNamePlasma;

  /// No description provided for @trailDescPlasma.
  ///
  /// In it, this message translates to:
  /// **'Energia plasma viola pulsante'**
  String get trailDescPlasma;

  /// No description provided for @trailNameRainbow.
  ///
  /// In it, this message translates to:
  /// **'Rainbow'**
  String get trailNameRainbow;

  /// No description provided for @trailDescRainbow.
  ///
  /// In it, this message translates to:
  /// **'Colori che cambiano continuamente'**
  String get trailDescRainbow;

  /// No description provided for @trailNameComet.
  ///
  /// In it, this message translates to:
  /// **'Comet'**
  String get trailNameComet;

  /// No description provided for @trailDescComet.
  ///
  /// In it, this message translates to:
  /// **'Testa luminosa con coda che si spegne lentamente'**
  String get trailDescComet;

  /// No description provided for @trailNameInferno.
  ///
  /// In it, this message translates to:
  /// **'Inferno'**
  String get trailNameInferno;

  /// No description provided for @trailDescInferno.
  ///
  /// In it, this message translates to:
  /// **'Fuoco multi-strato con braci che schizzano'**
  String get trailDescInferno;

  /// No description provided for @trailNameVoid.
  ///
  /// In it, this message translates to:
  /// **'Void'**
  String get trailNameVoid;

  /// No description provided for @trailDescVoid.
  ///
  /// In it, this message translates to:
  /// **'Vortice oscuro che risucchia particelle viola'**
  String get trailDescVoid;

  /// No description provided for @trailNameQuantum.
  ///
  /// In it, this message translates to:
  /// **'Quantum'**
  String get trailNameQuantum;

  /// No description provided for @trailDescQuantum.
  ///
  /// In it, this message translates to:
  /// **'Particelle accoppiate in superposizione cromatica'**
  String get trailDescQuantum;

  /// No description provided for @trailNameGalaxy.
  ///
  /// In it, this message translates to:
  /// **'Galaxy'**
  String get trailNameGalaxy;

  /// No description provided for @trailDescGalaxy.
  ///
  /// In it, this message translates to:
  /// **'Stelle che spiraleggiano con polvere cosmica'**
  String get trailDescGalaxy;

  /// No description provided for @trailNameLightning.
  ///
  /// In it, this message translates to:
  /// **'Lightning'**
  String get trailNameLightning;

  /// No description provided for @trailDescLightning.
  ///
  /// In it, this message translates to:
  /// **'Archi elettrici a zigzag tra i punti scia'**
  String get trailDescLightning;

  /// No description provided for @trailNameNebula.
  ///
  /// In it, this message translates to:
  /// **'Nebula'**
  String get trailNameNebula;

  /// No description provided for @trailDescNebula.
  ///
  /// In it, this message translates to:
  /// **'Nuvola spaziale ciano/magenta che pulsa'**
  String get trailDescNebula;

  /// No description provided for @trailNamePrism.
  ///
  /// In it, this message translates to:
  /// **'Prism'**
  String get trailNamePrism;

  /// No description provided for @trailDescPrism.
  ///
  /// In it, this message translates to:
  /// **'Spettro completo che scorre lungo la scia'**
  String get trailDescPrism;

  /// No description provided for @trailNameHologram.
  ///
  /// In it, this message translates to:
  /// **'Hologram'**
  String get trailNameHologram;

  /// No description provided for @trailDescHologram.
  ///
  /// In it, this message translates to:
  /// **'RGB chromatic aberration in stile glitch'**
  String get trailDescHologram;

  /// No description provided for @trailNameBiolume.
  ///
  /// In it, this message translates to:
  /// **'Biolumin'**
  String get trailNameBiolume;

  /// No description provided for @trailDescBiolume.
  ///
  /// In it, this message translates to:
  /// **'Bioluminescenza acquatica verde/ciano'**
  String get trailDescBiolume;

  /// No description provided for @trailNameNeonpulse.
  ///
  /// In it, this message translates to:
  /// **'NeonPulse'**
  String get trailNameNeonpulse;

  /// No description provided for @trailDescNeonpulse.
  ///
  /// In it, this message translates to:
  /// **'Anelli neon expanding bianco-ciano'**
  String get trailDescNeonpulse;

  /// No description provided for @weaponNameBasic.
  ///
  /// In it, this message translates to:
  /// **'Basic Gun'**
  String get weaponNameBasic;

  /// No description provided for @weaponDescBasic.
  ///
  /// In it, this message translates to:
  /// **'Doppia fila di proiettili gialli paralleli — affidabile e preciso.'**
  String get weaponDescBasic;

  /// No description provided for @weaponNameTriple.
  ///
  /// In it, this message translates to:
  /// **'Triple Shot'**
  String get weaponNameTriple;

  /// No description provided for @weaponDescTriple.
  ///
  /// In it, this message translates to:
  /// **'3 proiettili bianchi ravvicinati — fuoco concentrato.'**
  String get weaponDescTriple;

  /// No description provided for @weaponNameSpread.
  ///
  /// In it, this message translates to:
  /// **'Spread Shot'**
  String get weaponNameSpread;

  /// No description provided for @weaponDescSpread.
  ///
  /// In it, this message translates to:
  /// **'5 proiettili arancioni a ventaglio stretto — ottimo vs gruppi.'**
  String get weaponDescSpread;

  /// No description provided for @weaponNameRicochet.
  ///
  /// In it, this message translates to:
  /// **'Ricochet'**
  String get weaponNameRicochet;

  /// No description provided for @weaponDescRicochet.
  ///
  /// In it, this message translates to:
  /// **'Ventaglio di 3 colpi verdi ad alto danno che rimbalzano 2 volte sui muri.'**
  String get weaponDescRicochet;

  /// No description provided for @weaponNameHoming.
  ///
  /// In it, this message translates to:
  /// **'Homing'**
  String get weaponNameHoming;

  /// No description provided for @weaponDescHoming.
  ///
  /// In it, this message translates to:
  /// **'5 missili che inseguono bersagli distinti — esplodono al muro.'**
  String get weaponDescHoming;

  /// No description provided for @weaponNamePlasma.
  ///
  /// In it, this message translates to:
  /// **'Plasma'**
  String get weaponNamePlasma;

  /// No description provided for @weaponDescPlasma.
  ///
  /// In it, this message translates to:
  /// **'Orb viola lento con AoE esplosiva — devasta boss e gruppi.'**
  String get weaponDescPlasma;

  /// No description provided for @weaponNameLaser.
  ///
  /// In it, this message translates to:
  /// **'Laser'**
  String get weaponNameLaser;

  /// No description provided for @weaponDescLaser.
  ///
  /// In it, this message translates to:
  /// **'Raggio rosso continuo — taglia tutto ciò che tocca.'**
  String get weaponDescLaser;

  /// No description provided for @weaponNameGauss.
  ///
  /// In it, this message translates to:
  /// **'Gauss Cannon'**
  String get weaponNameGauss;

  /// No description provided for @weaponDescGauss.
  ///
  /// In it, this message translates to:
  /// **'Colpo viola con aspirazione gravitazionale 1s — raggruppa i nemici per colpirli tutti.'**
  String get weaponDescGauss;

  /// No description provided for @weaponNameChain.
  ///
  /// In it, this message translates to:
  /// **'Chain Lightning'**
  String get weaponNameChain;

  /// No description provided for @weaponDescChain.
  ///
  /// In it, this message translates to:
  /// **'Fulmine elettrico rimbalza tra 5 nemici — perfetto vs gruppi.'**
  String get weaponDescChain;

  /// No description provided for @modeDescClassic.
  ///
  /// In it, this message translates to:
  /// **'100 wave con boss ogni 10 — il modo standard'**
  String get modeDescClassic;

  /// No description provided for @modeDescBossRush.
  ///
  /// In it, this message translates to:
  /// **'Solo boss, uno dopo l\'altro — niente mob'**
  String get modeDescBossRush;

  /// No description provided for @modeDescSurvival.
  ///
  /// In it, this message translates to:
  /// **'Wave infinite sempre più difficili — quanto resisti?'**
  String get modeDescSurvival;

  /// No description provided for @modeDescTimeAttack.
  ///
  /// In it, this message translates to:
  /// **'3 minuti: fai più punti possibile prima che scada'**
  String get modeDescTimeAttack;

  /// No description provided for @modeDescZenMode.
  ///
  /// In it, this message translates to:
  /// **'Vite infinite — gioca senza stress, esplora tutto'**
  String get modeDescZenMode;

  /// No description provided for @modeDescTunnel.
  ///
  /// In it, this message translates to:
  /// **'Scorrimento laterale in un tunnel infinito'**
  String get modeDescTunnel;

  /// No description provided for @modeDescPacifist.
  ///
  /// In it, this message translates to:
  /// **'Niente colpi! Sopravvivi con i Gate (GW Pacifism)'**
  String get modeDescPacifist;

  /// No description provided for @modeDescWaves.
  ///
  /// In it, this message translates to:
  /// **'Solo triangoli rossi cardinali. Rari buchi neri. Dodge puro.'**
  String get modeDescWaves;

  /// No description provided for @modeDescGravityInferno.
  ///
  /// In it, this message translates to:
  /// **'Tanti buchi neri + pochi mob misti. Niente boss. Caos gravitazionale.'**
  String get modeDescGravityInferno;

  /// No description provided for @modeDescSnake.
  ///
  /// In it, this message translates to:
  /// **'Lascia una scia letale. Nessun\'arma, niente boss, niente powerup.'**
  String get modeDescSnake;

  /// No description provided for @upgradeFirepower.
  ///
  /// In it, this message translates to:
  /// **'FIREPOWER'**
  String get upgradeFirepower;

  /// No description provided for @upgradeFirepowerDesc.
  ///
  /// In it, this message translates to:
  /// **'+5% danno per livello (max +25%)'**
  String get upgradeFirepowerDesc;

  /// No description provided for @upgradeFireRate.
  ///
  /// In it, this message translates to:
  /// **'FIRE RATE'**
  String get upgradeFireRate;

  /// No description provided for @upgradeFireRateDesc.
  ///
  /// In it, this message translates to:
  /// **'+5% cadenza per livello (max +25%)'**
  String get upgradeFireRateDesc;

  /// No description provided for @upgradeSpeed.
  ///
  /// In it, this message translates to:
  /// **'SPEED'**
  String get upgradeSpeed;

  /// No description provided for @upgradeSpeedDesc.
  ///
  /// In it, this message translates to:
  /// **'+5% velocità per livello (max +25%)'**
  String get upgradeSpeedDesc;

  /// No description provided for @upgradeShield.
  ///
  /// In it, this message translates to:
  /// **'SHIELD'**
  String get upgradeShield;

  /// No description provided for @upgradeShieldDesc.
  ///
  /// In it, this message translates to:
  /// **'Scudo post-morte: 5s → 10s → 15s → 20s → 25s'**
  String get upgradeShieldDesc;

  /// No description provided for @upgradeLives.
  ///
  /// In it, this message translates to:
  /// **'LIVES'**
  String get upgradeLives;

  /// No description provided for @upgradeLivesDesc.
  ///
  /// In it, this message translates to:
  /// **'Vite iniziali: 3 → 4 → 5'**
  String get upgradeLivesDesc;

  /// No description provided for @upgradeBombs.
  ///
  /// In it, this message translates to:
  /// **'RAGGIO BOMBA'**
  String get upgradeBombs;

  /// No description provided for @upgradeBombsDesc.
  ///
  /// In it, this message translates to:
  /// **'+raggio esplosione per livello (L0 metà arena, L10 arena intera)'**
  String get upgradeBombsDesc;

  /// No description provided for @upgradeMagnet.
  ///
  /// In it, this message translates to:
  /// **'MAGNET'**
  String get upgradeMagnet;

  /// No description provided for @upgradeMagnetDesc.
  ///
  /// In it, this message translates to:
  /// **'+10px raggio magnete per livello (max +50px)'**
  String get upgradeMagnetDesc;

  /// No description provided for @upgradeXpBoost.
  ///
  /// In it, this message translates to:
  /// **'XP BOOST'**
  String get upgradeXpBoost;

  /// No description provided for @upgradeXpBoostDesc.
  ///
  /// In it, this message translates to:
  /// **'+10% GoldGeom per livello (max +50%)'**
  String get upgradeXpBoostDesc;

  /// No description provided for @petNameAttack.
  ///
  /// In it, this message translates to:
  /// **'ATTACCO'**
  String get petNameAttack;

  /// No description provided for @petDescAttack.
  ///
  /// In it, this message translates to:
  /// **'Segue il player + spara raffiche extra. Doppia la firepower.'**
  String get petDescAttack;

  /// No description provided for @petNameCollect.
  ///
  /// In it, this message translates to:
  /// **'RACCOLTA'**
  String get petNameCollect;

  /// No description provided for @petDescCollect.
  ///
  /// In it, this message translates to:
  /// **'Vola libero raccoglie geoms a distanza. Boost economy.'**
  String get petDescCollect;

  /// No description provided for @petNameSweep.
  ///
  /// In it, this message translates to:
  /// **'SWEEP'**
  String get petNameSweep;

  /// No description provided for @petDescSweep.
  ///
  /// In it, this message translates to:
  /// **'Orbita il player, instakill nemico al tocco.'**
  String get petDescSweep;

  /// No description provided for @petNameDefend.
  ///
  /// In it, this message translates to:
  /// **'DIFESA'**
  String get petNameDefend;

  /// No description provided for @petDescDefend.
  ///
  /// In it, this message translates to:
  /// **'Segue retro player, spara nella direzione opposta.'**
  String get petDescDefend;

  /// No description provided for @petNameSnipe.
  ///
  /// In it, this message translates to:
  /// **'SNIPE'**
  String get petNameSnipe;

  /// No description provided for @petDescSnipe.
  ///
  /// In it, this message translates to:
  /// **'Orbita lento + laser al nemico più vicino ogni 1.5s.'**
  String get petDescSnipe;

  /// No description provided for @petNameRam.
  ///
  /// In it, this message translates to:
  /// **'RAM'**
  String get petNameRam;

  /// No description provided for @petDescRam.
  ///
  /// In it, this message translates to:
  /// **'Insegue + si schianta sul nemico più vicino. Cooldown 1s.'**
  String get petDescRam;

  /// No description provided for @petNamePhoenix.
  ///
  /// In it, this message translates to:
  /// **'PHOENIX'**
  String get petNamePhoenix;

  /// No description provided for @petDescPhoenix.
  ///
  /// In it, this message translates to:
  /// **'Auto-revive una volta per run + 2s di invincibilità.'**
  String get petDescPhoenix;

  /// No description provided for @petNameBlackHole.
  ///
  /// In it, this message translates to:
  /// **'BUCO NERO'**
  String get petNameBlackHole;

  /// No description provided for @petDescBlackHole.
  ///
  /// In it, this message translates to:
  /// **'Pozzo gravitazionale: trascina i nemici entro 150px.'**
  String get petDescBlackHole;

  /// No description provided for @petNameEmpDrone.
  ///
  /// In it, this message translates to:
  /// **'EMP DRONE'**
  String get petNameEmpDrone;

  /// No description provided for @petDescEmpDrone.
  ///
  /// In it, this message translates to:
  /// **'Pulse stun nemici entro 250px ogni 8s (0.5s di stordimento).'**
  String get petDescEmpDrone;

  /// No description provided for @petNameTacticalSpotter.
  ///
  /// In it, this message translates to:
  /// **'OSSERVATORE TATTICO'**
  String get petNameTacticalSpotter;

  /// No description provided for @petDescTacticalSpotter.
  ///
  /// In it, this message translates to:
  /// **'Slow-mo 0.5s quando il player è in salute critica. CD 6s.'**
  String get petDescTacticalSpotter;

  /// No description provided for @weaponStatDmg.
  ///
  /// In it, this message translates to:
  /// **'DMG'**
  String get weaponStatDmg;

  /// No description provided for @weaponStatRate.
  ///
  /// In it, this message translates to:
  /// **'CAD'**
  String get weaponStatRate;

  /// No description provided for @weaponStatRange.
  ///
  /// In it, this message translates to:
  /// **'PORT'**
  String get weaponStatRange;

  /// No description provided for @weaponStatBullets.
  ///
  /// In it, this message translates to:
  /// **'PROIETT'**
  String get weaponStatBullets;

  /// No description provided for @weaponStatSpread.
  ///
  /// In it, this message translates to:
  /// **'DISPER'**
  String get weaponStatSpread;

  /// No description provided for @weaponStatBounce.
  ///
  /// In it, this message translates to:
  /// **'RIMB'**
  String get weaponStatBounce;

  /// No description provided for @weaponStatTrack.
  ///
  /// In it, this message translates to:
  /// **'AGG'**
  String get weaponStatTrack;

  /// No description provided for @weaponStatBlast.
  ///
  /// In it, this message translates to:
  /// **'ESPL'**
  String get weaponStatBlast;

  /// No description provided for @weaponStatAoe.
  ///
  /// In it, this message translates to:
  /// **'AOE'**
  String get weaponStatAoe;

  /// No description provided for @weaponStatPierce.
  ///
  /// In it, this message translates to:
  /// **'PERF'**
  String get weaponStatPierce;

  /// No description provided for @weaponStatLen.
  ///
  /// In it, this message translates to:
  /// **'LUNG'**
  String get weaponStatLen;

  /// No description provided for @weaponStatPull.
  ///
  /// In it, this message translates to:
  /// **'ASP'**
  String get weaponStatPull;

  /// No description provided for @weaponStatJumps.
  ///
  /// In it, this message translates to:
  /// **'SALTI'**
  String get weaponStatJumps;

  /// No description provided for @weaponStatTick.
  ///
  /// In it, this message translates to:
  /// **'tick'**
  String get weaponStatTick;

  /// No description provided for @weaponRateMed.
  ///
  /// In it, this message translates to:
  /// **'MED'**
  String get weaponRateMed;

  /// No description provided for @weaponRateFast.
  ///
  /// In it, this message translates to:
  /// **'VELOCE'**
  String get weaponRateFast;

  /// No description provided for @weaponRateSlow.
  ///
  /// In it, this message translates to:
  /// **'LENTO'**
  String get weaponRateSlow;

  /// No description provided for @weaponRateCont.
  ///
  /// In it, this message translates to:
  /// **'CONT'**
  String get weaponRateCont;

  /// No description provided for @modNoneCard.
  ///
  /// In it, this message translates to:
  /// **'NESSUN MODIFICATORE'**
  String get modNoneCard;

  /// No description provided for @modNoneCardDesc.
  ///
  /// In it, this message translates to:
  /// **'Gioca senza modificatori attivi.'**
  String get modNoneCardDesc;

  /// No description provided for @modeLockedSnack.
  ///
  /// In it, this message translates to:
  /// **'Sblocca nello SHOP'**
  String get modeLockedSnack;

  /// No description provided for @modNameGlassCannon.
  ///
  /// In it, this message translates to:
  /// **'CANNONE DI VETRO'**
  String get modNameGlassCannon;

  /// No description provided for @modDescGlassCannon.
  ///
  /// In it, this message translates to:
  /// **'3x danno, ma 1 sola vita. Nessuna invincibilità.'**
  String get modDescGlassCannon;

  /// No description provided for @modNameBulletHell.
  ///
  /// In it, this message translates to:
  /// **'BULLET HELL'**
  String get modNameBulletHell;

  /// No description provided for @modDescBulletHell.
  ///
  /// In it, this message translates to:
  /// **'I nemici sparano il doppio più velocemente.'**
  String get modDescBulletHell;

  /// No description provided for @modNameSpeedDemon.
  ///
  /// In it, this message translates to:
  /// **'SPEED DEMON'**
  String get modNameSpeedDemon;

  /// No description provided for @modDescSpeedDemon.
  ///
  /// In it, this message translates to:
  /// **'Tutto si muove 1.5x più veloce (player e nemici).'**
  String get modDescSpeedDemon;

  /// No description provided for @modNameNoPowerups.
  ///
  /// In it, this message translates to:
  /// **'PURISTA'**
  String get modNameNoPowerups;

  /// No description provided for @modDescNoPowerups.
  ///
  /// In it, this message translates to:
  /// **'Nessun power-up durante la partita.'**
  String get modDescNoPowerups;

  /// No description provided for @modNameFogOfWar.
  ///
  /// In it, this message translates to:
  /// **'NEBBIA DI GUERRA'**
  String get modNameFogOfWar;

  /// No description provided for @modDescFogOfWar.
  ///
  /// In it, this message translates to:
  /// **'Visibilità ridotta. Solo l\'area vicina è visibile.'**
  String get modDescFogOfWar;

  /// No description provided for @modNameTinyArena.
  ///
  /// In it, this message translates to:
  /// **'ARENA PICCOLA'**
  String get modNameTinyArena;

  /// No description provided for @modDescTinyArena.
  ///
  /// In it, this message translates to:
  /// **'Arena ridotta del 50%. Meno spazio per schivare.'**
  String get modDescTinyArena;

  /// No description provided for @modNameOneShot.
  ///
  /// In it, this message translates to:
  /// **'ONE SHOT'**
  String get modNameOneShot;

  /// No description provided for @modDescOneShot.
  ///
  /// In it, this message translates to:
  /// **'Tutti i nemici muoiono con 1 colpo. Ma anche tu.'**
  String get modDescOneShot;

  /// No description provided for @modNameChaos.
  ///
  /// In it, this message translates to:
  /// **'CAOS TOTALE'**
  String get modNameChaos;

  /// No description provided for @modDescChaos.
  ///
  /// In it, this message translates to:
  /// **'Power-up random ogni 10 secondi automaticamente.'**
  String get modDescChaos;

  /// No description provided for @modNameGiantMode.
  ///
  /// In it, this message translates to:
  /// **'GIGANTE'**
  String get modNameGiantMode;

  /// No description provided for @modDescGiantMode.
  ///
  /// In it, this message translates to:
  /// **'Tutto è 2x più grande. Nemici, proiettili, tutto.'**
  String get modDescGiantMode;

  /// No description provided for @modNameRicochetWorld.
  ///
  /// In it, this message translates to:
  /// **'RIMBALZO TOTALE'**
  String get modNameRicochetWorld;

  /// No description provided for @modDescRicochetWorld.
  ///
  /// In it, this message translates to:
  /// **'Tutti i proiettili rimbalzano 5 volte.'**
  String get modDescRicochetWorld;

  /// No description provided for @modNameInfiniteBombs.
  ///
  /// In it, this message translates to:
  /// **'BOMBER'**
  String get modNameInfiniteBombs;

  /// No description provided for @modDescInfiniteBombs.
  ///
  /// In it, this message translates to:
  /// **'Bombe infinite! Ma niente armi.'**
  String get modDescInfiniteBombs;

  /// No description provided for @modNameMagnetKing.
  ///
  /// In it, this message translates to:
  /// **'RE MAGNETE'**
  String get modNameMagnetKing;

  /// No description provided for @modDescMagnetKing.
  ///
  /// In it, this message translates to:
  /// **'Raggio magnete enorme. I geom volano verso di te.'**
  String get modDescMagnetKing;

  /// No description provided for @gameOverBossLabel.
  ///
  /// In it, this message translates to:
  /// **'BOSS'**
  String get gameOverBossLabel;

  /// No description provided for @gameOverGoldGeoms.
  ///
  /// In it, this message translates to:
  /// **'GOLD GEOMS'**
  String get gameOverGoldGeoms;

  /// No description provided for @achKills100Name.
  ///
  /// In it, this message translates to:
  /// **'Primo Sangue'**
  String get achKills100Name;

  /// No description provided for @achKills100Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 100 nemici in totale'**
  String get achKills100Desc;

  /// No description provided for @achKills1000Name.
  ///
  /// In it, this message translates to:
  /// **'Sterminatore'**
  String get achKills1000Name;

  /// No description provided for @achKills1000Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 1.000 nemici in totale'**
  String get achKills1000Desc;

  /// No description provided for @achKills10000Name.
  ///
  /// In it, this message translates to:
  /// **'Genocida Geometrico'**
  String get achKills10000Name;

  /// No description provided for @achKills10000Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 10.000 nemici in totale'**
  String get achKills10000Desc;

  /// No description provided for @achKills100000Name.
  ///
  /// In it, this message translates to:
  /// **'Leggenda'**
  String get achKills100000Name;

  /// No description provided for @achKills100000Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 100.000 nemici in totale'**
  String get achKills100000Desc;

  /// No description provided for @achKillsSession200Name.
  ///
  /// In it, this message translates to:
  /// **'Furia Cieca'**
  String get achKillsSession200Name;

  /// No description provided for @achKillsSession200Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 200 nemici in una partita'**
  String get achKillsSession200Desc;

  /// No description provided for @achKillsSession500Name.
  ///
  /// In it, this message translates to:
  /// **'Massacro'**
  String get achKillsSession500Name;

  /// No description provided for @achKillsSession500Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 500 nemici in una partita'**
  String get achKillsSession500Desc;

  /// No description provided for @achKillsSession1000Name.
  ///
  /// In it, this message translates to:
  /// **'Apocalisse'**
  String get achKillsSession1000Name;

  /// No description provided for @achKillsSession1000Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 1000 nemici in una partita'**
  String get achKillsSession1000Desc;

  /// No description provided for @achBosses10Name.
  ///
  /// In it, this message translates to:
  /// **'Ammazza Boss'**
  String get achBosses10Name;

  /// No description provided for @achBosses10Desc.
  ///
  /// In it, this message translates to:
  /// **'Sconfiggi 10 boss in totale'**
  String get achBosses10Desc;

  /// No description provided for @achBosses50Name.
  ///
  /// In it, this message translates to:
  /// **'Regicida'**
  String get achBosses50Name;

  /// No description provided for @achBosses50Desc.
  ///
  /// In it, this message translates to:
  /// **'Sconfiggi 50 boss in totale'**
  String get achBosses50Desc;

  /// No description provided for @achBosses100Name.
  ///
  /// In it, this message translates to:
  /// **'Sterminatore Reale'**
  String get achBosses100Name;

  /// No description provided for @achBosses100Desc.
  ///
  /// In it, this message translates to:
  /// **'Sconfiggi 100 boss in totale'**
  String get achBosses100Desc;

  /// No description provided for @achBossSession5Name.
  ///
  /// In it, this message translates to:
  /// **'Caccia Reale'**
  String get achBossSession5Name;

  /// No description provided for @achBossSession5Desc.
  ///
  /// In it, this message translates to:
  /// **'Sconfiggi 5 boss in una partita'**
  String get achBossSession5Desc;

  /// No description provided for @achBombs50Name.
  ///
  /// In it, this message translates to:
  /// **'Artificiere'**
  String get achBombs50Name;

  /// No description provided for @achBombs50Desc.
  ///
  /// In it, this message translates to:
  /// **'Usa 50 bombe in totale'**
  String get achBombs50Desc;

  /// No description provided for @achBombs500Name.
  ///
  /// In it, this message translates to:
  /// **'Demolitore'**
  String get achBombs500Name;

  /// No description provided for @achBombs500Desc.
  ///
  /// In it, this message translates to:
  /// **'Usa 500 bombe in totale'**
  String get achBombs500Desc;

  /// No description provided for @achScore100kName.
  ///
  /// In it, this message translates to:
  /// **'Sei Cifre'**
  String get achScore100kName;

  /// No description provided for @achScore100kDesc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi 100.000 punti'**
  String get achScore100kDesc;

  /// No description provided for @achScore1mName.
  ///
  /// In it, this message translates to:
  /// **'Milionario'**
  String get achScore1mName;

  /// No description provided for @achScore1mDesc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi 1.000.000 punti'**
  String get achScore1mDesc;

  /// No description provided for @achScore10mName.
  ///
  /// In it, this message translates to:
  /// **'Re dei Punti'**
  String get achScore10mName;

  /// No description provided for @achScore10mDesc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi 10.000.000 punti'**
  String get achScore10mDesc;

  /// No description provided for @achScore100mName.
  ///
  /// In it, this message translates to:
  /// **'Centurione'**
  String get achScore100mName;

  /// No description provided for @achScore100mDesc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi 100.000.000 punti'**
  String get achScore100mDesc;

  /// No description provided for @achScore1bName.
  ///
  /// In it, this message translates to:
  /// **'Miliardario'**
  String get achScore1bName;

  /// No description provided for @achScore1bDesc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi 1.000.000.000 punti'**
  String get achScore1bDesc;

  /// No description provided for @achMultiplier100Name.
  ///
  /// In it, this message translates to:
  /// **'Combo x100'**
  String get achMultiplier100Name;

  /// No description provided for @achMultiplier100Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi un moltiplicatore di 100x'**
  String get achMultiplier100Desc;

  /// No description provided for @achMultiplier500Name.
  ///
  /// In it, this message translates to:
  /// **'Combo x500'**
  String get achMultiplier500Name;

  /// No description provided for @achMultiplier500Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi un moltiplicatore di 500x'**
  String get achMultiplier500Desc;

  /// No description provided for @achMultiplier1000Name.
  ///
  /// In it, this message translates to:
  /// **'Combo x1000'**
  String get achMultiplier1000Name;

  /// No description provided for @achMultiplier1000Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi un moltiplicatore di 1000x'**
  String get achMultiplier1000Desc;

  /// No description provided for @achMultiplier5000Name.
  ///
  /// In it, this message translates to:
  /// **'Combo Divina'**
  String get achMultiplier5000Name;

  /// No description provided for @achMultiplier5000Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi un moltiplicatore di 5000x'**
  String get achMultiplier5000Desc;

  /// No description provided for @achGeoms10000Name.
  ///
  /// In it, this message translates to:
  /// **'Collezionista'**
  String get achGeoms10000Name;

  /// No description provided for @achGeoms10000Desc.
  ///
  /// In it, this message translates to:
  /// **'Raccogli 10.000 geom in totale'**
  String get achGeoms10000Desc;

  /// No description provided for @achGeoms100000Name.
  ///
  /// In it, this message translates to:
  /// **'Avaro Geometrico'**
  String get achGeoms100000Name;

  /// No description provided for @achGeoms100000Desc.
  ///
  /// In it, this message translates to:
  /// **'Raccogli 100.000 geom in totale'**
  String get achGeoms100000Desc;

  /// No description provided for @achWave20Name.
  ///
  /// In it, this message translates to:
  /// **'Persistente'**
  String get achWave20Name;

  /// No description provided for @achWave20Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi wave 20'**
  String get achWave20Desc;

  /// No description provided for @achWave50Name.
  ///
  /// In it, this message translates to:
  /// **'Veterano'**
  String get achWave50Name;

  /// No description provided for @achWave50Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi wave 50'**
  String get achWave50Desc;

  /// No description provided for @achWave100Name.
  ///
  /// In it, this message translates to:
  /// **'Centenario'**
  String get achWave100Name;

  /// No description provided for @achWave100Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi wave 100'**
  String get achWave100Desc;

  /// No description provided for @achWave200Name.
  ///
  /// In it, this message translates to:
  /// **'Inarrestabile'**
  String get achWave200Name;

  /// No description provided for @achWave200Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi wave 200 (Survival/Tunnel)'**
  String get achWave200Desc;

  /// No description provided for @achPerfectWaves5Name.
  ///
  /// In it, this message translates to:
  /// **'Intoccabile'**
  String get achPerfectWaves5Name;

  /// No description provided for @achPerfectWaves5Desc.
  ///
  /// In it, this message translates to:
  /// **'Completa 5 wave perfette consecutive'**
  String get achPerfectWaves5Desc;

  /// No description provided for @achPerfectWaves10Name.
  ///
  /// In it, this message translates to:
  /// **'Fantasma'**
  String get achPerfectWaves10Name;

  /// No description provided for @achPerfectWaves10Desc.
  ///
  /// In it, this message translates to:
  /// **'Completa 10 wave perfette consecutive'**
  String get achPerfectWaves10Desc;

  /// No description provided for @achPerfectWaves20Name.
  ///
  /// In it, this message translates to:
  /// **'Divinità'**
  String get achPerfectWaves20Name;

  /// No description provided for @achPerfectWaves20Desc.
  ///
  /// In it, this message translates to:
  /// **'Completa 20 wave perfette consecutive'**
  String get achPerfectWaves20Desc;

  /// No description provided for @achClassicNormalName.
  ///
  /// In it, this message translates to:
  /// **'Classicista'**
  String get achClassicNormalName;

  /// No description provided for @achClassicNormalDesc.
  ///
  /// In it, this message translates to:
  /// **'Completa Classica in Normale'**
  String get achClassicNormalDesc;

  /// No description provided for @achClassicHardName.
  ///
  /// In it, this message translates to:
  /// **'Duro a Morire'**
  String get achClassicHardName;

  /// No description provided for @achClassicHardDesc.
  ///
  /// In it, this message translates to:
  /// **'Completa Classica in Difficile'**
  String get achClassicHardDesc;

  /// No description provided for @achClassicNightmareName.
  ///
  /// In it, this message translates to:
  /// **'Incubo Vivente'**
  String get achClassicNightmareName;

  /// No description provided for @achClassicNightmareDesc.
  ///
  /// In it, this message translates to:
  /// **'Completa Classica in Incubo'**
  String get achClassicNightmareDesc;

  /// No description provided for @achAllModesName.
  ///
  /// In it, this message translates to:
  /// **'Tuttofare'**
  String get achAllModesName;

  /// No description provided for @achAllModesDesc.
  ///
  /// In it, this message translates to:
  /// **'Gioca in tutte le 6 modalità'**
  String get achAllModesDesc;

  /// No description provided for @achBossRush10Name.
  ///
  /// In it, this message translates to:
  /// **'Cacciatore di Boss'**
  String get achBossRush10Name;

  /// No description provided for @achBossRush10Desc.
  ///
  /// In it, this message translates to:
  /// **'Raggiungi boss 10 in Boss Rush'**
  String get achBossRush10Desc;

  /// No description provided for @achGames10Name.
  ///
  /// In it, this message translates to:
  /// **'Giocatore'**
  String get achGames10Name;

  /// No description provided for @achGames10Desc.
  ///
  /// In it, this message translates to:
  /// **'Gioca 10 partite'**
  String get achGames10Desc;

  /// No description provided for @achGames100Name.
  ///
  /// In it, this message translates to:
  /// **'Appassionato'**
  String get achGames100Name;

  /// No description provided for @achGames100Desc.
  ///
  /// In it, this message translates to:
  /// **'Gioca 100 partite'**
  String get achGames100Desc;

  /// No description provided for @achGames500Name.
  ///
  /// In it, this message translates to:
  /// **'Dipendente'**
  String get achGames500Name;

  /// No description provided for @achGames500Desc.
  ///
  /// In it, this message translates to:
  /// **'Gioca 500 partite'**
  String get achGames500Desc;

  /// No description provided for @achGold10000Name.
  ///
  /// In it, this message translates to:
  /// **'Paperone'**
  String get achGold10000Name;

  /// No description provided for @achGold10000Desc.
  ///
  /// In it, this message translates to:
  /// **'Accumula 10.000 Gold Geom'**
  String get achGold10000Desc;

  /// No description provided for @achGold50000Name.
  ///
  /// In it, this message translates to:
  /// **'Magnate'**
  String get achGold50000Name;

  /// No description provided for @achGold50000Desc.
  ///
  /// In it, this message translates to:
  /// **'Accumula 50.000 Gold Geom'**
  String get achGold50000Desc;

  /// No description provided for @achAllUpgradesName.
  ///
  /// In it, this message translates to:
  /// **'Potenziato al Massimo'**
  String get achAllUpgradesName;

  /// No description provided for @achAllUpgradesDesc.
  ///
  /// In it, this message translates to:
  /// **'Compra tutti gli upgrade'**
  String get achAllUpgradesDesc;

  /// No description provided for @achPowerups100Name.
  ///
  /// In it, this message translates to:
  /// **'Drogato di Power-Up'**
  String get achPowerups100Name;

  /// No description provided for @achPowerups100Desc.
  ///
  /// In it, this message translates to:
  /// **'Raccogli 100 power-up'**
  String get achPowerups100Desc;

  /// No description provided for @achWavesWave20Name.
  ///
  /// In it, this message translates to:
  /// **'Schivatore'**
  String get achWavesWave20Name;

  /// No description provided for @achWavesWave20Desc.
  ///
  /// In it, this message translates to:
  /// **'Waves mode: raggiungi wave 20'**
  String get achWavesWave20Desc;

  /// No description provided for @achWavesWave50Name.
  ///
  /// In it, this message translates to:
  /// **'Maestro del Dodge'**
  String get achWavesWave50Name;

  /// No description provided for @achWavesWave50Desc.
  ///
  /// In it, this message translates to:
  /// **'Waves mode: raggiungi wave 50'**
  String get achWavesWave50Desc;

  /// No description provided for @achGravityWave15Name.
  ///
  /// In it, this message translates to:
  /// **'Astrofisico'**
  String get achGravityWave15Name;

  /// No description provided for @achGravityWave15Desc.
  ///
  /// In it, this message translates to:
  /// **'Gravity Inferno: raggiungi wave 15'**
  String get achGravityWave15Desc;

  /// No description provided for @achPacifistCombo15Name.
  ///
  /// In it, this message translates to:
  /// **'Pacifista Pro'**
  String get achPacifistCombo15Name;

  /// No description provided for @achPacifistCombo15Desc.
  ///
  /// In it, this message translates to:
  /// **'Pacifist: combo gate 15+'**
  String get achPacifistCombo15Desc;

  /// No description provided for @achTimeAttack500kName.
  ///
  /// In it, this message translates to:
  /// **'Cronometrista'**
  String get achTimeAttack500kName;

  /// No description provided for @achTimeAttack500kDesc.
  ///
  /// In it, this message translates to:
  /// **'Time Attack: 500k score'**
  String get achTimeAttack500kDesc;

  /// No description provided for @achDailyStreak7Name.
  ///
  /// In it, this message translates to:
  /// **'Devoto Giornaliero'**
  String get achDailyStreak7Name;

  /// No description provided for @achDailyStreak7Desc.
  ///
  /// In it, this message translates to:
  /// **'Riscatta il daily reward 7 giorni di fila'**
  String get achDailyStreak7Desc;

  /// No description provided for @achDailyStreak30Name.
  ///
  /// In it, this message translates to:
  /// **'Fedele Mensile'**
  String get achDailyStreak30Name;

  /// No description provided for @achDailyStreak30Desc.
  ///
  /// In it, this message translates to:
  /// **'Riscatta il daily reward 30 giorni di fila'**
  String get achDailyStreak30Desc;

  /// No description provided for @achGaussKills500Name.
  ///
  /// In it, this message translates to:
  /// **'Maestro Gauss'**
  String get achGaussKills500Name;

  /// No description provided for @achGaussKills500Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 500 nemici con Gauss Cannon'**
  String get achGaussKills500Desc;

  /// No description provided for @achChainKills500Name.
  ///
  /// In it, this message translates to:
  /// **'Tempesta'**
  String get achChainKills500Name;

  /// No description provided for @achChainKills500Desc.
  ///
  /// In it, this message translates to:
  /// **'Uccidi 500 nemici con Chain Lightning'**
  String get achChainKills500Desc;

  /// No description provided for @achAllWeaponsName.
  ///
  /// In it, this message translates to:
  /// **'Armaiolo'**
  String get achAllWeaponsName;

  /// No description provided for @achAllWeaponsDesc.
  ///
  /// In it, this message translates to:
  /// **'Sblocca tutte le armi'**
  String get achAllWeaponsDesc;

  /// No description provided for @achAllSkinsName.
  ///
  /// In it, this message translates to:
  /// **'Fashionista'**
  String get achAllSkinsName;

  /// No description provided for @achAllSkinsDesc.
  ///
  /// In it, this message translates to:
  /// **'Sblocca tutte le skin'**
  String get achAllSkinsDesc;

  /// No description provided for @achAllTrailsName.
  ///
  /// In it, this message translates to:
  /// **'Collezione Cosmica'**
  String get achAllTrailsName;

  /// No description provided for @achAllTrailsDesc.
  ///
  /// In it, this message translates to:
  /// **'Sblocca tutti i trail'**
  String get achAllTrailsDesc;

  /// No description provided for @achAllPetsName.
  ///
  /// In it, this message translates to:
  /// **'Domatore'**
  String get achAllPetsName;

  /// No description provided for @achAllPetsDesc.
  ///
  /// In it, this message translates to:
  /// **'Sblocca tutti i pet'**
  String get achAllPetsDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
