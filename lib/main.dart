import 'package:flutter/material.dart';
import 'package:login/dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARCHIDOC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthentificationWidget(),
        '/main': (context) => const MainPage(),
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
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool passwordVisibility = false;
  bool checkboxListTileValue = true;
  final TextEditingController textController1 = TextEditingController();
  final TextEditingController textController2 = TextEditingController();

  @override
  void dispose() {
    textController1.dispose();
    textController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [],
          centerTitle: false,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional.center,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 670),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        0,
                        12,
                        0,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                12,
                                32,
                                0,
                                8,
                              ),
                              child: Text(
                                'ARCHIDOC',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                12,
                                0,
                                0,
                                12,
                              ),
                              child: Text(
                                'Gestion des archives.',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                12,
                                16,
                                0,
                              ),
                              child: TextFormField(
                                controller: textController1,
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'Nom d\'utilisation',
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedErrorBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                        0,
                                        16,
                                        16,
                                        8,
                                      ),
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                12,
                                16,
                                0,
                              ),
                              child: TextFormField(
                                controller: textController2,
                                autofocus: false,
                                obscureText: !passwordVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedErrorBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                        0,
                                        16,
                                        16,
                                        8,
                                      ),
                                  suffixIcon: InkWell(
                                    onTap: () => setState(
                                      () => passwordVisibility =
                                          !passwordVisibility,
                                    ),
                                    child: Icon(
                                      passwordVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Theme(
                              data: ThemeData(
                                unselectedWidgetColor: Colors.grey,
                              ),
                              child: CheckboxListTile(
                                value: checkboxListTileValue,
                                onChanged: (newValue) {
                                  setState(
                                    () => checkboxListTileValue = newValue!,
                                  );
                                },
                                title: const Text(
                                  'Se souvenir de ma session',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                tileColor: Colors.white,
                                activeColor: Colors.black,
                                checkColor: Colors.white,
                                dense: false,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                      16,
                                      0,
                                      16,
                                      0,
                                    ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!(MediaQuery.of(context).viewInsets.bottom > 0))
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        12,
                        16,
                        24,
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/main');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Authentifier',
                          style: TextStyle(fontSize: 18),
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

extension ListExtension<T> on List<T> {
  List<T> addToStart(T item) => [item, ...this];
  List<T> addToEnd(T item) => [...this, item];
  List<T> divide(T separator) {
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i != length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}
