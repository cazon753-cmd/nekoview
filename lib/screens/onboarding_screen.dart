import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      "title": "Welcome to NekoView",
      "desc": "A fast, ad-free client built to browse your favorite image boards smoothly.",
      "icon": "pets"
    },
    {
      "title": "Tailored Content Filters",
      "desc": "Control what you want to see. Adjust content ratings directly within the drawer settings.",
      "icon": "security"
    },
    {
      "title": "Development",
      "desc": "Help make NekoView better by contributing or reporting issues. New features will be added in future updates.",
      "icon": "checklist"
    }
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications(); 
  }

  Future<void> _initNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('launch_background');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      debugPrint('Initialization failed: $e');
    }
  }

  Future<void> _showReadyNotification() async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'nekoview_final_v3',
        'NekoView System',
        channelDescription: 'Important app readiness notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'launch_background',
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        0,
        'NekoView is ready!',
        'You are using the release version.',
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    
    if (Platform.isAndroid) {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      bool? granted = await androidImpl?.requestNotificationsPermission();
      
      if (granted == true) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    await _showReadyNotification();
    
    if (!mounted) { return; }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _slides[idx]['icon'] == 'pets' ? Icons.pets :
                          _slides[idx]['icon'] == 'security' ? Icons.security : Icons.checklist,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _slides[idx]['title']!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _slides[idx]['desc']!,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == idx ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == idx ? Theme.of(context).colorScheme.primary : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _currentPage == _slides.length - 1 
                      ? _finishOnboarding 
                      : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: Text(_currentPage == _slides.length - 1 ? "Get Started" : "Next"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}