import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login/dashboard.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

final dbHelper = DatabaseHelper.instance;

Future<void> initializeApp() async {
  // Initialize database and insert default data
  final db = await dbHelper.database;

  // Print database info after initialization
  print('===== DATABASE INITIALIZED =====');
  print('Database path: ${(await getDatabasesPath())}/archidoc.db');

  // Print users
  final users = await db.query('users');
  print('Users:');
  for (final user in users) {
    print('  ${user['username']} (ID: ${user['id']})');
  }

  // Print archives
  final archives = await db.query('archives');
  print('Archives:');
  for (final archive in archives) {
    print('  ${archive['rangee']}-${archive['colonne']}: ${archive['caisse']}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp(); // Initialize database before running app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'ARCHIDOC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthentificationWidget(),
        '/main': (context) => MainPage(username: '', database: dbHelper),
      },
    );
  }
}

class AuthentificationWidget extends StatefulWidget {
  const AuthentificationWidget({super.key});

  @override
  State<AuthentificationWidget> createState() => _AuthentificationWidgetState();
}

class _AuthentificationWidgetState extends State<AuthentificationWidget> {
  bool _passwordVisible = false;
  bool _rememberMe = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Future<void> _authenticate() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez entrer un nom d\'utilisateur et un mot de passe',
          ),
        ),
      );
      return;
    }

    final user = await dbHelper.getUser(username);

    if (user == null || user['password'] != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom d\'utilisateur ou mot de passe incorrect'),
        ),
      );
      return;
    }

    // Print database info after successful login
    print('\n===== AFTER LOGIN =====');
    final archives = await dbHelper.getAllArchives();
    print('Total archives: ${archives.length}');
    for (final archive in archives) {
      print(
        '  ${archive['rangee']}-${archive['colonne']}: ${archive['caisse']}',
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(username: username, database: dbHelper),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and title
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/archidoc.png',
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ARCHIDOC',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gestion des archives',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nom d\'utilisateur',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Remember me checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      const Text('Se souvenir de moi'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Mot de passe oublié?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: const Text(
                        'CONNEXION',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
