import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import './powersync.dart';
import './widgets/lists_page.dart';
import './widgets/login_page.dart';
import './widgets/query_widget.dart';
import './widgets/signup_page.dart';
import './widgets/status_app_bar.dart';
import './migrations/full_text_search_setup.dart';

void main() async {
  // Log info from PowerSync
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print(
          '[${record.loggerName}] ${record.level.name}: ${record.time}: ${record.message}');

      if (record.error != null) {
        print(record.error);
      }
      if (record.stackTrace != null) {
        print(record.stackTrace);
      }
    }
  });

  WidgetsFlutterBinding
      .ensureInitialized(); //required to get sqlite filepath from path_provider before UI has initialized
  await openDatabase();
  db.execute('PRAGMA recursive_triggers = TRUE');
  // This is where you can add more migrations to generate FTS tables that correspond to the tables in your schema
  // and populate them with the data you would like to search on
  migrations
    ..add(createFtsMigration(
        migrationVersion: 1,
        tableName: 'lists',
        columns: ['name'],
        tokenizationMethod: 'porter unicode61'))
    ..add(createFtsMigration(
      migrationVersion: 2,
      tableName: 'todos',
      columns: ['description', 'list_id'],
    ));
  await migrations.migrate(db);

  final loggedIn = isLoggedIn();
  runApp(MyApp(loggedIn: loggedIn));
}

const defaultQuery = 'SELECT * from todos';

const listsPage = ListsPage();
const homePage = listsPage;

const sqlConsolePage = Scaffold(
    appBar: StatusAppBar(title: 'SQL Console'),
    body: QueryWidget(defaultQuery: defaultQuery));

const loginPage = LoginPage();

const signupPage = SignupPage();

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'PowerSync Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: loggedIn ? homePage : loginPage);
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage(
      {super.key,
      required this.title,
      required this.content,
      this.floatingActionButton});

  final String title;
  final Widget content;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StatusAppBar(title: title),
      body: Center(child: content),
      floatingActionButton: floatingActionButton,
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(''),
            ),
            ListTile(
              title: const Text('SQL Console'),
              onTap: () {
                var navigator = Navigator.of(context);
                navigator.pop();

                navigator.push(MaterialPageRoute(
                  builder: (context) => sqlConsolePage,
                ));
              },
            ),
            ListTile(
              title: const Text('Sign Out'),
              onTap: () async {
                var navigator = Navigator.of(context);
                navigator.pop();
                await logout();

                navigator.pushReplacement(MaterialPageRoute(
                  builder: (context) => loginPage,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
