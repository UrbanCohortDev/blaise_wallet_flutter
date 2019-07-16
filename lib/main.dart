import 'package:blaise_wallet_flutter/appstate_container.dart';
import 'package:blaise_wallet_flutter/localization.dart';
import 'package:blaise_wallet_flutter/service_locator.dart';
import 'package:blaise_wallet_flutter/ui/account/account.dart';
import 'package:blaise_wallet_flutter/ui/intro/intro_security_first.dart';
import 'package:blaise_wallet_flutter/ui/lockscreen/lock_screen.dart';
import 'package:blaise_wallet_flutter/ui/overview/overview.dart';
import 'package:blaise_wallet_flutter/ui/intro/intro_backup_confirm.dart';
import 'package:blaise_wallet_flutter/ui/intro/intro_decrypt_and_import_private_key.dart';
import 'package:blaise_wallet_flutter/ui/intro/intro_import_private_key.dart';
import 'package:blaise_wallet_flutter/ui/intro/intro_new_private_key.dart';
import 'package:blaise_wallet_flutter/ui/settings/contacts/contacts.dart';
import 'package:blaise_wallet_flutter/ui/settings/security.dart';
import 'package:blaise_wallet_flutter/ui/util/routes.dart';
import 'package:blaise_wallet_flutter/ui/util/text_styles.dart';
import 'package:blaise_wallet_flutter/ui/intro/intro_welcome.dart';
import 'package:blaise_wallet_flutter/util/sharedprefs_util.dart';
import 'package:blaise_wallet_flutter/util/vault.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oktoast/oktoast.dart';

void main() async {
  // Register services
  setupServiceLocator();
  // Run app
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(StateContainer(child: App()));
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        StateContainer.of(context).curTheme.statusBar);
    return OKToast(
      textStyle: AppStyles.snackbar(context),
      backgroundColor: StateContainer.of(context).curTheme.backgroundPrimary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Blaise',
        theme: ThemeData(
          dialogBackgroundColor:
              StateContainer.of(context).curTheme.backgroundPrimary,
          primaryColor: StateContainer.of(context).curTheme.primary,
          accentColor: StateContainer.of(context).curTheme.primary,
          backgroundColor:
              StateContainer.of(context).curTheme.backgroundPrimary,
          fontFamily: 'Metropolis',
          brightness: StateContainer.of(context).curTheme.brightness,
          splashColor: StateContainer.of(context).curTheme.primary30,
          highlightColor: StateContainer.of(context).curTheme.primary15,
        ),
        localizationsDelegates: [
          AppLocalizationsDelegate(StateContainer.of(context).curLanguage),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
              return NoTransitionRoute(
                builder: (context) => Splash(),
                settings: settings,
              );
            case '/lock_screen':
              if (settings.arguments != null &&
                  settings.arguments is TransitionOption &&
                  settings.arguments == TransitionOption.NONE) {
                return NoTransitionRoute(
                  builder: (context) => LockScreenPage(),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                builder: (context) => LockScreenPage(),
                settings: settings,
              );
            case '/intro_welcome':
              return NoTransitionRoute(
                builder: (context) => IntroWelcomePage(),
                settings: settings,
              );
            case '/intro_security_first':
              return MaterialPageRoute(
                builder: (context) => IntroSecurityFirstPage(),
                settings: settings,
              );
            case '/intro_new_private_key':
              return MaterialPageRoute(
                builder: (context) => IntroNewPrivateKeyPage(),
                settings: settings,
              );
            case '/intro_backup_confirm':
              return MaterialPageRoute(
                builder: (context) => IntroBackupConfirmPage(),
                settings: settings,
              );
            case '/intro_import_private_key':
              return MaterialPageRoute(
                builder: (context) => IntroImportPrivateKeyPage(),
                settings: settings,
              );
            case '/intro_decrypt_and_import_private_key':
              return MaterialPageRoute(
                builder: (context) => IntroDecryptAndImportPrivateKeyPage(
                    encryptedKey: settings.arguments),
                settings: settings,
              );
            case '/overview':
              if (settings.arguments != null &&
                  settings.arguments is TransitionOption &&
                  settings.arguments == TransitionOption.NONE) {
                return NoTransitionRoute(
                  builder: (context) => OverviewPage(),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                builder: (context) => OverviewPage(),
                settings: settings,
              );
            case '/account':
              return MaterialPageRoute(
                builder: (context) => AccountPage(account: settings.arguments),
                settings: settings,
              );
            case '/security':
              return MaterialPageRoute(
                builder: (context) => SecurityPage(),
                settings: settings,
              );
            case '/contacts':
              return MaterialPageRoute(
                builder: (context) => ContactsPage(account: settings.arguments),
                settings: settings,
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

/// Splash
/// Default page route that determines if user is logged in and routes them appropriately.
class Splash extends StatefulWidget {
  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> with WidgetsBindingObserver {
  bool _hasCheckedLoggedIn;
  Future checkLoggedIn() async {
    if (!_hasCheckedLoggedIn) {
      _hasCheckedLoggedIn = true;
      if (await sl.get<SharedPrefsUtil>().getFirstLaunch()) {
        await sl.get<SharedPrefsUtil>().deleteAll(firstLaunch: true);
        await sl.get<Vault>().deleteAll();
        await sl.get<SharedPrefsUtil>().setFirstLaunch();
        Navigator.of(context).pushReplacementNamed('/intro_welcome');
      } else if ((await sl.get<Vault>().getPrivateKey() != null) &&
          (await sl.get<SharedPrefsUtil>().getPrivateKeyBackedUp())) {
        if (await sl.get<SharedPrefsUtil>().getLock() || await sl.get<SharedPrefsUtil>().shouldLock()) {
          Navigator.of(context).pushReplacementNamed('/lock_screen', arguments: TransitionOption.NONE);
        } else {
          Navigator.of(context).pushReplacementNamed('/overview',
             arguments: TransitionOption.NONE);
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/intro_welcome');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hasCheckedLoggedIn = false;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => checkLoggedIn());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Account for user changing locale when leaving the app
    switch (state) {
      case AppLifecycleState.paused:
        super.didChangeAppLifecycleState(state);
        break;
      case AppLifecycleState.resumed:
        setLanguage();
        super.didChangeAppLifecycleState(state);
        break;
      default:
        super.didChangeAppLifecycleState(state);
        break;
    }
  }

  void setLanguage() {
    /*
    setState(() {
      StateContainer.of(context).deviceLocale = Localizations.localeOf(context);
    });
    sl.get<SharedPrefsUtil>().getLanguage().then((setting) {
      setState(() {
        StateContainer.of(context).updateLanguage(setting);
      });
    });*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StateContainer.of(context).curTheme.backgroundPrimary,
    );
  }
}
