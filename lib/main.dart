import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize API service and restore persisted JWT session
  await ApiService.instance.init();

  runApp(const TrabalhakiApp());
}

class TrabalhakiApp extends StatelessWidget {
  const TrabalhakiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trabalhaki',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  String _currentScreen = "splash";
  String _userRole = "candidate";

  @override
  void initState() {
    super.initState();
    if (ApiService.instance.isAuthenticated && ApiService.instance.currentUser != null) {
      _userRole = ApiService.instance.currentUser!.isCompany ? "company" : "candidate";
    }
  }

  void _navigateTo(String screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case "splash":
        return SplashScreen(
          key: const ValueKey("splash"),
          onFinish: () {
            if (ApiService.instance.isAuthenticated) {
              setState(() {
                _userRole = ApiService.instance.currentUser?.isCompany == true
                    ? "company"
                    : "candidate";
                _currentScreen = "main";
              });
            } else {
              _navigateTo("auth");
            }
          },
        );
      case "auth":
        return AuthScreen(
          key: const ValueKey("auth"),
          onNavigate: (screen) {
            _navigateTo(screen);
          },
        );
      case "signup":
        return SignupScreen(
          key: const ValueKey("signup"),
          onBack: () => _navigateTo("auth"),
          onSuccess: (role) {
            setState(() {
              _userRole = role;
              _currentScreen = "main";
            });
          },
        );
      case "login":
        return LoginScreen(
          key: const ValueKey("login"),
          onBack: () => _navigateTo("auth"),
          onLogin: (role) {
            setState(() {
              _userRole = role;
              _currentScreen = "main";
            });
          },
        );
      case "main":
      default:
        return MainScreen(
          key: ValueKey("main_$_userRole"),
          userRole: _userRole,
          onLogout: () async {
            await ApiService.instance.logout();
            setState(() {
              _userRole = "candidate";
              _currentScreen = "auth";
            });
          },
        );
    }
  }
}
