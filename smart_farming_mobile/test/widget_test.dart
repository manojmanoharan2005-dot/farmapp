import 'package:flutter_test/flutter_test.dart';

import 'package:smart_farming_mobile/app.dart';

void main() {
  testWidgets('renders landing page', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartFarmingMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Farming Assistant'), findsWidgets);
  });
}
