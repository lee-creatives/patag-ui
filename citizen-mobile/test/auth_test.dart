import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patag_citizen/app/theme.dart';
import 'package:patag_citizen/features/screens.dart';
import 'package:patag_citizen/core/api.dart';
void main(){
 test('account API fails before networking when no shared backend URL is configured',() async {
  expect(PatagStore.baseUrl,isEmpty);
  final client=PatagStore();
  await expectLater(client.call('/me'),throwsA(isA<Exception>().having((e)=>e.toString(),'message',contains('Configure API_URL'))));
  client.dispose();
 });
 testWidgets('registration validates each step and preserves identity when going back',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:patagTheme(),home:const AuthScreen('register')));
  await tester.tap(find.text('Continue'));await tester.pumpAndSettle();
  expect(find.text('Step 1 of 3 · About you'),findsOneWidget);
  await tester.enterText(find.byType(TextFormField).at(0),'Test Citizen');
  await tester.enterText(find.byType(TextFormField).at(1),'citizen@example.test');
  await tester.tap(find.text('Continue'));await tester.pumpAndSettle();
  expect(find.text('Step 2 of 3 · Your address'),findsOneWidget);
  await tester.enterText(find.byType(TextFormField).at(1),'Guinhawa');
  await tester.enterText(find.byType(TextFormField).at(2),'Malolos');
  await tester.enterText(find.byType(TextFormField).at(3),'Bulacan');
  await tester.scrollUntilVisible(find.text('Continue'), 250, scrollable: find.byType(Scrollable).first);await tester.tap(find.text('Continue'));await tester.pumpAndSettle();
  expect(find.text('Step 3 of 3 · Secure your account'),findsOneWidget);
  await tester.enterText(find.byType(TextFormField).first,'short');
  await tester.scrollUntilVisible(find.widgetWithText(FilledButton,'Create account'), 250, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.widgetWithText(FilledButton,'Create account'));await tester.pumpAndSettle();
  expect(find.text('Use 15 to 128 characters.'),findsOneWidget);
  await tester.scrollUntilVisible(find.text('Back'), 250, scrollable: find.byType(Scrollable).first);await tester.tap(find.text('Back'));await tester.pumpAndSettle();
  expect(tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller?.text,'Guinhawa');await tester.scrollUntilVisible(find.text('Back'), 250, scrollable: find.byType(Scrollable).first);await tester.tap(find.text('Back'));await tester.pumpAndSettle();expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller?.text,'Test Citizen');expect(tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller?.text,'citizen@example.test');expect(tester.takeException(),isNull);
 });
}
