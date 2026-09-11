import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_stamp_task/main.dart';

void main() {
  testWidgets('Home shows signature and watermark actions', (tester) async {
    await tester.pumpWidget(const PdfStampApp());
    expect(find.text('PDF Sign & Watermark'), findsOneWidget);
    expect(find.text('Signature'), findsOneWidget);
    expect(find.text('Watermark'), findsOneWidget);
  });
}
