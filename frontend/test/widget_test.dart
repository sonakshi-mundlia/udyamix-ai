import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/main.dart';
import 'package:frontend/providers/language_provider.dart';
import 'package:frontend/screens/login_screen.dart';

void main() {
  testWidgets('App loads Login screen when no token', (WidgetTester tester) async {
    // Mock language provider
    final languageProvider = LanguageProvider();
    await languageProvider.loadSavedLanguage();

    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>.value(
        value: languageProvider,
        child: const AppInitializer(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Login screen UI
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('Welcome'), findsOneWidget);
  });
}
