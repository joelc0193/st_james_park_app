// Import the necessary packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/user_upload_page.dart';
import 'user_upload_page_test.mocks.dart';

@GenerateMocks([FirestoreService])
void main() {
  // Create the mock objects
  late MockFirestoreService mockFirestoreService;

  setUp(() {
    // Instantiate the mock objects before each test
    mockFirestoreService = MockFirestoreService();
  });

  testWidgets('Submitting form calls FirestoreService',
      (WidgetTester tester) async {
    // Arrange: Set up the mock to return a specific result when called
    when(mockFirestoreService.uploadText(any)).thenAnswer((_) async => true);
    when(mockFirestoreService.updateAdminNumbers(any))
        .thenAnswer((_) async => true);
    when(mockFirestoreService.uploadImage(any))
        .thenAnswer((_) async => 'image_url');

    // Act: Create the UserUploadPage and pump it into the widget tester
    await tester.pumpWidget(MaterialApp(
      home: Provider<FirestoreService>(
        create: (_) => mockFirestoreService,
        child: UserUploadPage(),
      ),
    ));

    // Find the text fields and enter text
    var textFieldFinder = find.byType(TextFormField);
    expect(textFieldFinder, findsWidgets); // Make sure we found the text fields

    // Enter text into each text field
    for (var i = 0; i < textFieldFinder.evaluate().length; i++) {
      await tester.enterText(textFieldFinder.at(i), 'Test text $i');
    }

    // Find the checkboxes and check them
    var checkboxFinder = find.byType(CheckboxListTile);
    expect(checkboxFinder, findsWidgets); // Make sure we found the checkboxes

    // Check each checkbox
    for (var i = 0; i < checkboxFinder.evaluate().length; i++) {
      await tester.tap(checkboxFinder.at(i));
    }

    // Call pumpAndSettle to start any animations and simulate them completing
    await tester.pumpAndSettle();

    // Find the submit button and tap it
    var submitButton = find.text('Submit');
    await tester.tap(submitButton);

    // Call pumpAndSettle again to start any animations and simulate them completing
    await tester.pumpAndSettle();

    // Assert: Check that the method was called on the mock
    verify(mockFirestoreService.uploadText(any)).called(1);
    verify(mockFirestoreService.updateAdminNumbers(any)).called(1);
    verify(mockFirestoreService.uploadImage(any)).called(1);
  });

  // TODO: Add more tests for other methods and behaviors
}
