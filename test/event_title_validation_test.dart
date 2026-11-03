import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_scheduler/screens/event_form_screen.dart';

void main() {
  testWidgets(
    'event titles need at least five Unicode code points and one letter',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EventFormScreen()),
      );

      final titleField = find.byType(TextFormField).first;
      final form = tester.state<FormState>(find.byType(Form));

      await tester.enterText(titleField, '0');
      expect(form.validate(), isFalse);

      await tester.enterText(titleField, '////');
      expect(form.validate(), isFalse);

      await tester.enterText(titleField, "XA'");
      expect(form.validate(), isFalse);

      await tester.enterText(titleField, 'Task');
      expect(form.validate(), isFalse);

      await tester.enterText(titleField, 'Task1');
      expect(form.validate(), isTrue);

      await tester.enterText(titleField, '12345');
      expect(form.validate(), isFalse);

      await tester.enterText(titleField, 'हिन्दी');
      expect(form.validate(), isTrue);

      await tester.enterText(titleField, '大阪会議');
      expect(form.validate(), isFalse);

      await tester.enterText(titleField, '大阪会議予定');
      expect(form.validate(), isTrue);
    },
  );
}
