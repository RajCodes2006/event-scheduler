import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_scheduler/screens/event_form_screen.dart';

void main() {
  testWidgets('event titles require a letter but support Unicode scripts',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EventFormScreen()),
    );

    final titleField = find.byType(TextFormField).first;
    final form = tester.state<FormState>(find.byType(Form));

    await tester.enterText(titleField, '0');
    expect(form.validate(), isFalse);

    await tester.enterText(titleField, '//');
    expect(form.validate(), isFalse);

    await tester.enterText(titleField, 'Project 0');
    expect(form.validate(), isTrue);

    await tester.enterText(titleField, 'गणित की परीक्षा');
    expect(form.validate(), isTrue);

    await tester.enterText(titleField, '大阪会議');
    expect(form.validate(), isTrue);
  });
}
