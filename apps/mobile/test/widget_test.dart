import 'package:flutter_test/flutter_test.dart';
import 'package:photographes_mobile/main.dart';

void main() {
  testWidgets('HomePage renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotographesApp());
    expect(find.text('Photographes.ci'), findsOneWidget);
  });
}
