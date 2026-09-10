import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
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
          onFinish: () => _navigateTo("auth"),
        );
      case "auth":
      case "signup":
        return AuthScreen(
          key: const ValueKey("auth"),
          onNavigate: (screen) {
            if (screen == "signup") {
              _navigateTo("login");
            } else {
              _navigateTo(screen);
            }
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
          onLogout: () {
            setState(() {
              _userRole = "candidate";
              _currentScreen = "auth";
            });
          },
        );
    }
  }
}
