import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/manage_metadata_screen.dart';
import 'features/transactions/quick_add_sheet.dart';
import 'firebase_options.dart';
import 'providers/finance_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable unlimited offline persistence for instant local writes + auto cloud sync
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  await NotificationService.instance.init();

  runApp(const ProviderScope(child: FinFlowApp()));
}

class FinFlowApp extends ConsumerStatefulWidget {
  const FinFlowApp({super.key});

  @override
  ConsumerState<FinFlowApp> createState() => _FinFlowAppState();
}

class _FinFlowAppState extends ConsumerState<FinFlowApp> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(financeRepositoryProvider).seedDefaultsIfEmpty());
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onDueTap: () => setState(() => _tabIndex = 1)),
      const RemindersScreen(),
      const ReportsScreen(),
      const ManageMetadataScreen(),
    ];

    return MaterialApp(
      title: 'FinFlow',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Builder(
        builder: (navContext) => Scaffold(
          body: IndexedStack(index: _tabIndex, children: screens),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: navContext,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const QuickAddTransactionSheet(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Log'),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.alarm_outlined), selectedIcon: Icon(Icons.alarm), label: 'Reminders'),
              NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Reports'),
              NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Setup'),
            ],
          ),
        ),
      ),
    );
  }
}