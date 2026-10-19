import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/auth/presentation/pages/auth_page.dart';
import 'package:traviato/features/auth/presentation/pages/guest_landing_page.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/auth/presentation/widgets/confirm_email_card.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_auth_repository.dart';

Widget _auth(FakeAuthRepository repo, Locale locale, AuthMode mode) =>
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: localizedApp(
        locale: locale,
        home: AuthPage(initialMode: mode),
      ),
    );

void main() {
  group('guest landing', () {
    testWidgets('renders in Russian with the split headline', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          locale: const Locale('ru'),
          home: const GuestLandingPage(),
        ),
      );
      await tester.pump();

      expect(find.text('ХРАНИТЕЛЬ ВАШИХ ВОСПОМИНАНИЙ'), findsOneWidget);
      expect(find.text('Каждое воспоминание —'), findsOneWidget);
      expect(find.text('бережно сохранено.'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('RU'), findsOneWidget); // language chip (1d)
      expect(find.text('Свадьбы'), findsOneWidget);
      expect(find.text('ДО'), findsOneWidget);
      expect(find.text('Семейная поездка в Токио'), findsOneWidget);
      expect(find.text('9 ДНЕЙ · 214 ФОТО'), findsOneWidget);
      expect(find.text('1 ДЕНЬ · 42 ФОТО'), findsOneWidget);
      expect(find.text('Начните сохранять свои моменты'), findsOneWidget);
    });

    for (final locale in const [Locale('en'), Locale('ru')]) {
      testWidgets('lays out without overflow at 360pt in '
          '${locale.languageCode}', (tester) async {
        setScreenSize(tester);
        await tester.pumpWidget(
          localizedApp(locale: locale, home: const GuestLandingPage()),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('auth page', () {
    testWidgets('signup form and validation read in Russian', (tester) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        _auth(repo, const Locale('ru'), AuthMode.signup),
      );

      expect(find.text('Начните свою'), findsOneWidget);
      expect(find.text('ИМЯ'), findsOneWidget);
      expect(find.text('Создать аккаунт'), findsOneWidget);
      expect(find.textContaining('10 звёзд', findRichText: true), findsWidgets);
      expect(find.text('Продолжить с Google'), findsOneWidget);

      await tester.tap(find.text('Создать аккаунт'));
      await tester.pump();

      expect(find.text('Введите имя.'), findsOneWidget);
      expect(find.text('Введите email.'), findsOneWidget);
      expect(find.text('Придумайте пароль.'), findsOneWidget);
    });

    for (final locale in const [Locale('en'), Locale('ru')]) {
      testWidgets('lays out without overflow at 360pt in '
          '${locale.languageCode}', (tester) async {
        setScreenSize(tester);
        final repo = FakeAuthRepository();
        addTearDown(repo.dispose);
        await tester.pumpWidget(_auth(repo, locale, AuthMode.signup));

        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('confirm-email card keeps the email bold inside the sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: localizedApp(
          locale: const Locale('ru'),
          home: Scaffold(
            body: ConfirmEmailCard(
              email: 'anna@example.com',
              onBackToLogin: () {},
              onUseDifferentEmail: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Проверьте почту'), findsOneWidget);
    expect(
      find.textContaining(
        'Мы отправили ссылку для подтверждения на anna@example.com.',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });
}
