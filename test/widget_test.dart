import 'package:flutter_test/flutter_test.dart';
import 'package:mood_studios_mobile/app.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const MoodStudiosApp());
    expect(find.text('Mood Studios'), findsWidgets);
  });
}
