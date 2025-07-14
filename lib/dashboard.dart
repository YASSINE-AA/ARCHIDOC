import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform, File, Directory;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:login/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:login/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

const String companyLogo = 'assets/archidoc.png';

class MainPage extends StatefulWidget {
  final String username;
  final DatabaseHelper database;
  const MainPage({super.key, required this.username, required this.database});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _searchController = TextEditingController();
  int selectedIndex = 0;
  String search = '';
  String? scannedColonne;
  String? scannedCaisse;
  List<Map<String, dynamic>> archives = [];
  bool isLoading = true;

  String? _currentScan;
  bool _isEntry = true;
  List<Map<String, dynamic>> _movements = [];

  @override
  void initState() {
    super.initState();
    _loadArchives();
    _loadMovements();
  }

  Future<void> _loadArchives() async {
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      final results = await widget.database.getAllArchives();
      if (!mounted) return;

      setState(() {
        archives = results;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load archives: $e')));
    }
  }

  Future<void> _loadMovements() async {
    try {
      final results = await widget.database.getRecentMovements();
      if (mounted) {
        setState(() {
          _movements = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load movements: $e')));
      }
    }
  }

  Future<void> _sendEmailWithAttachment({
    required String filePath,
    required String subject,
    required String body,
  }) async {
    try {
      await dotenv.load();
      final username = dotenv.env['GMAIL_USER'];
      final password = dotenv.env['GMAIL_PASSWORD'];

      if (username == null || password == null) {
        throw Exception('Email credentials not configured');
      }

      final file = File(filePath);
      final attachment = FileAttachment(file)
        ..location = Location.inline
        ..fileName = path.basename(filePath);

      final message = Message()
        ..from = Address(username, 'ARCHIDOC GESTION ARCHIVES')
        ..recipients.add('yassineahmedali02@gmail.com')
        ..subject = subject
        ..text = body
        ..attachments.add(attachment);

      final smtpServer = gmail(username, password);

      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }

  Future<void> exportToCsv() async {
    try {
      List<List<String>> csvData = [
        ['Colonne', 'Caisse', 'Date'],
        ...archives.map(
          (row) => [
            row['colonne']?.toString() ?? '',
            row['caisse']?.toString() ?? '',
            row['date']?.toString() ?? '',
          ],
        ),
      ];

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'archives_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final path = '${directory.path}/$fileName';
      await File(path).writeAsString(csv);
      final downloadsDir = Directory('/storage/emulated/0/Download');

      if (Platform.isAndroid) {
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        await File(path).copy('${downloadsDir.path}/$fileName');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported to: $path'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'SEND EMAIL',
              onPressed: () => _sendEmailWithAttachment(
                filePath: '${downloadsDir.path}/$fileName',
                subject:
                    'Archives Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                body:
                    'Please find attached the exported archives data.\n\n'
                    'File: $fileName\n'
                    'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> exportMovementsToCsv() async {
    try {
      final movements = await widget.database.getAllMovements();

      List<List<String>> csvData = [
        ['Type', 'Code', 'Date'],
        ...movements.map(
          (row) => [
            row['type']?.toString() ?? '',
            row['code']?.toString() ?? '',
            row['movement_date']?.toString() ?? '',
          ],
        ),
      ];

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/movements_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      await File(path).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Movements CSV exported to: $path'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'SEND EMAIL',
              onPressed: () => _sendEmailWithAttachment(
                filePath: path,
                subject:
                    'Movements Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                body:
                    'Please find attached the exported movements data.\n\n'
                    'File path: $path\n'
                    'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> purgeArchives() async {
    try {
      await _loadArchives();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archives purged successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Purge failed: $e')));
      }
    }
  }

  Future<void> purgeMovements() async {
    try {
      await widget.database.purgeMovements();
      await _loadMovements();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movements purged successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Purge failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredArchives = archives.where((entry) {
      return entry.values.any(
        (value) =>
            value.toString().toLowerCase().contains(search.toLowerCase()),
      );
    }).toList();

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isPortrait
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Image.asset(companyLogo, height: 40),
                  const SizedBox(width: 10),
                  const Text('ARCHIDOC', style: TextStyle(color: Colors.black)),
                ],
              ),
              actions: [_buildUserProfile()],
            )
          : null,
      body: isPortrait
          ? _buildPortraitLayout(filteredArchives)
          : _buildLandscapeLayout(filteredArchives),
      bottomNavigationBar: isPortrait ? _buildBottomNavBar() : null,
      drawer: isPortrait ? null : _buildSidebar(),
    );
  }

  Widget _buildPortraitLayout(List<Map<String, dynamic>> filteredArchives) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (selectedIndex == 0) ...[
              _buildSummaryCards(),
              const SizedBox(height: 16),
              _buildHeader(false),
              const SizedBox(height: 16),
            ],
            _buildCurrentPage(filteredArchives),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(List<Map<String, dynamic>> filteredArchives) {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Image.asset(companyLogo, height: 50),
                  ),
                  if (selectedIndex == 0) ...[
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildHeader(true),
                    const SizedBox(height: 16),
                  ],
                  Expanded(child: _buildCurrentPage(filteredArchives)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPage(List<Map<String, dynamic>> filteredArchives) {
    switch (selectedIndex) {
      case 0:
        return _buildArchivesPage(filteredArchives);
      case 1:
        return _bonsEntreeSortiePage();
      case 2:
        return _localisationPage();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.blue,
      currentIndex: selectedIndex,
      onTap: (index) {
        if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AuthentificationWidget(),
            ),
          );
        } else {
          setState(() => selectedIndex = index);
        }
      },
      items: const [
        BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.archive),
          label: 'Archives',
        ),
        BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.inventory),
          label: 'Bons',
        ),
        BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.location_on),
          label: 'Localisation',
        ),
        BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Text(
              widget.username[0],
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.username, style: TextStyle(color: Colors.black)),
              const Text(
                'Admin',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              children: [
                Image.asset(companyLogo, height: 50),
                const SizedBox(height: 10),
                Text(
                  widget.username,
                  style: const TextStyle(color: Colors.white),
                ),
                const Text('Admin', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          _buildNavItem(Icons.archive, 'Archives', 0),
          _buildNavItem(Icons.inventory, 'Bons d\'Entrée/Sortie', 1),
          _buildNavItem(Icons.location_on, 'Localisation', 2),
          const Divider(),
          _buildNavItem(Icons.logout, 'Logout', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: TextStyle(color: Colors.black)),
      selected: selectedIndex == index,
      onTap: () {
        if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AuthentificationWidget(),
            ),
          );
        } else {
          setState(() => selectedIndex = index);
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _summaryCard(
            icon: Icons.grid_on,
            title: 'Colonnes',
            value: archives.length.toString(),
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          _summaryCard(
            icon: Icons.folder,
            title: 'Caisses',
            value: archives.length.toString(),
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          _summaryCard(
            icon: Icons.compare_arrows,
            title: 'Mouvements',
            value: _movements.length.toString(),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Row(
      children: [
        const Text(
          'Archives',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: isWide ? 300 : MediaQuery.of(context).size.width * 0.5,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => search = value),
          ),
        ),
      ],
    );
  }

  Widget _buildArchivesPage(List<Map<String, dynamic>> filteredArchives) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: exportToCsv,
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: purgeArchives,
              icon: const Icon(Icons.delete),
              label: const Text('Purge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => selectedIndex = 2),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        isLoading
            ? const CircularProgressIndicator()
            : filteredArchives.isEmpty
            ? const Text(
                'No archives found',
                style: TextStyle(color: Colors.black),
              )
            : _buildArchivesList(filteredArchives),
      ],
    );
  }

  Widget _buildArchivesList(List<Map<String, dynamic>> archives) {
    return Card(
      color: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: archives.length,
        itemBuilder: (context, index) {
          final entry = archives[index];
          return ListTile(
            title: Text(
              'Colonne: ${entry['colonne']}',
              style: TextStyle(color: Colors.black),
            ),
            subtitle: Text(
              'Caisse: ${entry['caisse']}',
              style: TextStyle(color: Colors.black54),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () => _showArchiveOptions(entry),
            ),
          );
        },
      ),
    );
  }

  void _showArchiveOptions(Map<String, dynamic> archive) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.black),
              title: const Text('Edit', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                _editArchive(archive);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.black),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteArchive(archive);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editArchive(Map<String, dynamic> archive) async {
    final colonneController = TextEditingController(
      text: archive['colonne']?.toString(),
    );
    final caisseController = TextEditingController(
      text: archive['caisse']?.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Archive',
          style: TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colonneController,
              decoration: const InputDecoration(
                labelText: 'Colonne',
                labelStyle: TextStyle(color: Colors.black),
              ),
              style: TextStyle(color: Colors.black),
            ),
            TextField(
              controller: caisseController,
              decoration: const InputDecoration(
                labelText: 'Caisse',
                labelStyle: TextStyle(color: Colors.black),
              ),
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await widget.database.updateArchive(
                  archive['id'],
                  colonneController.text,
                  caisseController.text,
                );
                await _loadArchives();
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Edit failed: $e')));
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArchive(Map<String, dynamic> archive) async {
    try {
      await widget.database.deleteArchive(archive['id']);
      await _loadArchives();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Archive deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Widget _bonsEntreeSortiePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: exportMovementsToCsv,
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: purgeMovements,
                icon: const Icon(Icons.delete),
                label: const Text('Purge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Entrée'),
                  selected: _isEntry,
                  onSelected: (selected) {
                    setState(() {
                      _isEntry = selected;
                      _currentScan = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Sortie'),
                  selected: !_isEntry,
                  onSelected: (selected) {
                    setState(() {
                      _isEntry = !selected;
                      _currentScan = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    _isEntry ? 'Entrée d\'Archive' : 'Sortie d\'Archive',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(text: _currentScan),
                    decoration: InputDecoration(
                      hintText: 'Code archive',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          setState(() {
                            _currentScan =
                                'ARCH-${DateTime.now().millisecondsSinceEpoch}';
                          });
                        },
                      ),
                    ),
                    onChanged: (value) => setState(() => _currentScan = value),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _currentScan == null || _currentScan!.isEmpty
                        ? null
                        : () async {
                            try {
                              await widget.database.insertMovement(
                                _isEntry ? 'Entrée' : 'Sortie',
                                _currentScan!,
                              );
                              await _loadMovements();
                              setState(() {
                                _currentScan = null;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    child: Text(
                      _isEntry ? 'Enregistrer Entrée' : 'Enregistrer Sortie',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Derniers Mouvements',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (_movements.isEmpty)
            const Center(child: Text('Aucun mouvement enregistré'))
          else
            Column(
              children: _movements
                  .map(
                    (movement) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          movement['type'] == 'Entrée'
                              ? Icons.input
                              : Icons.output,
                          color: movement['type'] == 'Entrée'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(movement['code']),
                        subtitle: Text(
                          '${movement['type']} • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(movement['movement_date']))}',
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _localisationPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Archive',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildScanField(
              'Colonne',
              scannedColonne,
              () => _simulateScan('Colonne'),
            ),
            const SizedBox(height: 16),
            _buildScanField(
              'Caisse',
              scannedCaisse,
              scannedColonne == null ? null : () => _simulateScan('Caisse'),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.grey),
                ),
                onPressed: (scannedColonne != null && scannedCaisse != null)
                    ? _addScannedArchive
                    : null,
                child: const Text('Add Archive'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Existing Archives:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (archives.isEmpty)
              const Center(
                child: Text(
                  'No archives found',
                  style: TextStyle(color: Colors.black),
                ),
              )
            else
              Column(
                children: archives
                    .take(5)
                    .map(
                      (entry) => ListTile(
                        title: Text(
                          'Colonne: ${entry['colonne']}',
                          style: TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          'Caisse: ${entry['caisse']}',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanField(String label, String? value, VoidCallback? onScan) {
    final TextEditingController controller = TextEditingController(text: value);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: label,
                  hintText: 'Enter $label',
                ),
                onChanged: (text) {
                  setState(() {
                    if (label == 'Colonne') {
                      scannedColonne = text;
                    } else if (label == 'Caisse') {
                      scannedCaisse = text;
                    }
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
              onPressed: onScan,
            ),
          ],
        ),
      ),
    );
  }

  void _simulateScan(String type) {
    setState(() {
      if (type == 'Colonne') {
        scannedColonne = 'C${DateTime.now().second}';
      } else if (type == 'Caisse') {
        scannedCaisse = 'BX${DateTime.now().millisecond}';
      }
    });
  }

  Future<void> _addScannedArchive() async {
    if (scannedColonne == null || scannedCaisse == null) return;

    try {
      await widget.database.insertArchive(scannedColonne!, scannedCaisse!);
      await _loadArchives();
      setState(() {
        scannedColonne = null;
        scannedCaisse = null;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archive added successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    }
  }
}
