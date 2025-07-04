import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:login/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:login/database_helper.dart';

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
  int selectedIndex = 1;
  String search = '';
  String? scannedColonne;
  String? scannedCaisse;
  List<Map<String, dynamic>> archives = [];
  bool isLoading = true;
  final List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    pages.addAll([
      _archivesPage(),
      const Center(child: Text("test")),
      _bonsEntreeSortiePage(),
      _localisationPage(),
    ]);

    // Load archives immediately after widget initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArchives();
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du chargement des archives: $e')),
      );
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
      final directory = await getExternalStorageDirectory();
      if (directory == null)
        throw Exception('Impossible d\'accéder au stockage');

      final path =
          '${directory.path}/archives_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      await File(path).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV exporté vers: $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec de l\'export: $e')));
      }
    }
  }

  Future<void> purgeArchives() async {
    try {
      //await widget.database.purgeArchives();
      await _loadArchives();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archives purgées avec succès')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec de la purge: $e')));
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

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSummaryCards()),
                      const SizedBox(width: 16),
                      _buildUserProfile(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (selectedIndex == 1) ...[
                    _buildHeader(isWide),
                    const SizedBox(height: 16),
                  ],

                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : selectedIndex == 1
                        ? _buildDataTableCard(filteredArchives)
                        : pages[selectedIndex],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Text(
                'Admin',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: Colors.blue,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      companyLogo,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ARCHIDOC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(Icons.archive, 'Archives', 1),
                _buildNavItem(Icons.inventory, 'Bons d\'Entrée/Sortie', 2),
                _buildNavItem(Icons.location_on, 'Localisation', 3),
                const Divider(height: 1),
                _buildNavItem(Icons.logout, 'Déconnexion', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: selectedIndex == index ? Colors.blue : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selectedIndex == index ? Colors.blue : Colors.black87,
          fontWeight: selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      selected: selectedIndex == index,
      onTap: () {
        if (index == 4) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Archives',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(
          width: isWide ? 350 : 250,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par colonne ou caisse',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => setState(() => search = value.toLowerCase()),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTableCard(List<Map<String, dynamic>> filteredArchives) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: exportToCsv,
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: purgeArchives,
                    icon: const Icon(Icons.delete),
                    label: const Text('Purger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Colonne',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Caisse',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredArchives.isEmpty
                  ? const Center(child: Text('Aucune archive trouvée'))
                  : ListView.builder(
                      itemCount: filteredArchives.length,
                      itemBuilder: (context, index) {
                        final entry = filteredArchives[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    entry['colonne']?.toString() ?? '',
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    entry['caisse']?.toString() ?? '',
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(entry['date']?.toString() ?? ''),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showArchiveOptions(entry),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArchiveOptions(Map<String, dynamic> archive) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _editArchive(archive);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Supprimer'),
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
        title: const Text('Modifier Archive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colonneController,
              decoration: const InputDecoration(labelText: 'Colonne'),
            ),
            TextField(
              controller: caisseController,
              decoration: const InputDecoration(labelText: 'Caisse'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Échec de la modification: $e')),
                  );
                }
              }
            },
            child: const Text('Sauvegarder'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archive supprimée avec succès')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec de la suppression: $e')));
      }
    }
  }

  Widget _archivesPage() {
    final filteredArchives = archives.where((entry) {
      return entry.values.any(
        (value) =>
            value.toString().toLowerCase().contains(search.toLowerCase()),
      );
    }).toList();

    return Column(
      children: [
        _buildHeader(true),
        const SizedBox(height: 16),
        Expanded(child: _buildDataTableCard(filteredArchives)),
      ],
    );
  }

  Widget _bonsEntreeSortiePage() {
    return const Center(
      child: Text(
        'Page Bons d\'Entrée / Sortie',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _localisationPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Localisation & Ajout Archive',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _barcodeScanStep(
            label: 'Colonne',
            scannedValue: scannedColonne,
            onScan: () => _simulateScan('Colonne'),
          ),
          const SizedBox(height: 16),
          _barcodeScanStep(
            label: 'Caisse',
            scannedValue: scannedCaisse,
            onScan: scannedColonne == null
                ? null
                : () => _simulateScan('Caisse'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (scannedColonne != null && scannedCaisse != null)
                ? _addScannedArchive
                : null,
            child: const Text('Ajouter Archive'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Archives existantes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: archives.isEmpty
                ? const Center(child: Text('Aucune archive enregistrée'))
                : ListView.builder(
                    itemCount: archives.length,
                    itemBuilder: (context, index) {
                      final entry = archives[index];
                      return ListTile(
                        title: Text(
                          'Colonne: ${entry['colonne']}, Caisse: ${entry['caisse']}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _barcodeScanStep({
    required String label,
    String? scannedValue,
    VoidCallback? onScan,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${scannedValue ?? '-'}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        ElevatedButton(
          onPressed: onScan,
          child: Text(scannedValue == null ? 'Scanner $label' : 'Rescanner'),
        ),
      ],
    );
  }

  void _simulateScan(String type) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Scanner $type'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Entrez le code $type'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    if (type == 'Colonne') {
                      scannedColonne = value;
                      scannedCaisse = null;
                    } else if (type == 'Caisse') {
                      scannedCaisse = value;
                    }
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
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
          const SnackBar(content: Text('Archive ajoutée avec succès!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec de l\'ajout: $e')));
      }
    }
  }
}
