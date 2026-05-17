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
  /// **'+1000 CREDITI'**
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
  /// **'+1000 crediti! Totale: {total}'**
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
