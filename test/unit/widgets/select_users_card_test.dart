import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
import 'package:ctrim_app/pages/personal/select_users_page.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  User person({
    required String id,
    required String forname,
    required List<String> tagIDs,
  }) {
    return User(
      id: id,
      forname: forname,
      surname: 'Estareja',
      location: 'Belfast',
      authID: 'auth-$id',
      tagIDs: tagIDs,
    );
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    required double width,
    required List<User> users,
  }) async {
    final tags = [
      UserTag(id: 'worship', name: 'Worship Team', color: '#6B4EAA'),
      UserTag(id: 'speaker', name: 'Speaker', color: '#C46B2C'),
      UserTag(id: 'usher', name: 'Usher', color: '#3D5A80'),
      UserTag(id: 'kids', name: 'Kids Ministry', color: '#C45C7A'),
    ];
    final appContext = AppContext(
      prefInstance: prefs,
      cacheDir: null,
      appDir: null,
      allUsers: users,
      allTags: tags,
      user: User(
        id: 'me',
        forname: 'Pat',
        surname: 'Admin',
        location: 'Belfast',
        authID: 'me',
      ),
    );

    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppContext>.value(
        value: appContext,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.dark,
          ),
          home: SelectUsersPage(
            selectedUIDs: users.map((user) => user.id).toList(),
            preferServing: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wide picker card fits a person with tags', (tester) async {
    await pumpPicker(
      tester,
      width: 1200,
      users: [
        person(id: 'jean', forname: 'Jean', tagIDs: ['worship', 'speaker']),
      ],
    );
    expect(find.text('Jean Estareja'), findsOneWidget);
    expect(find.text('Worship Team'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide picker card fits a person with many tags', (tester) async {
    await pumpPicker(
      tester,
      width: 1200,
      users: [
        person(
          id: 'jean',
          forname: 'Jean',
          tagIDs: ['worship', 'speaker', 'usher', 'kids'],
        ),
      ],
    );
    expect(find.text('Jean Estareja'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow picker row fits a person with tags', (tester) async {
    await pumpPicker(
      tester,
      width: 400,
      users: [
        person(id: 'jean', forname: 'Jean', tagIDs: ['worship', 'speaker']),
      ],
    );
    expect(find.text('Jean Estareja'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
