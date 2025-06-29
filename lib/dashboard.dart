import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

const String company_logo = 'assets/archidoc.png';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _searchController = TextEditingController();
  int selectedIndex = 0;
  String search = '';

  // For scanning new archive location parts:
  String? scannedRangee;
  String? scannedColonne;
  String? scannedCaisse;

  final List<Map<String, String>> archives = [
    {'rangee': 'A1', 'colonne': 'C1', 'caisse': 'BX001'},
    {'rangee': 'A1', 'colonne': 'C2', 'caisse': 'BX002'},
    {'rangee': 'B2', 'colonne': 'C3', 'caisse': 'BX003'},
    {'rangee': 'B2', 'colonne': 'C4', 'caisse': 'BX004'},
    {'rangee': 'C3', 'colonne': 'C5', 'caisse': 'BX005'},
  ];

  final List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    pages.addAll([
      const Center(child: Text('Dashboard Page')),
      _archivesPage(),
      const Center(child: Text('Reports Page')),
      const Center(child: Text('Settings Page')),
      const Center(child: Text('Help Center Page')),
      const Center(child: Text('Logout Page')),
      _bonsEntreeSortiePage(),
      _localisationPage(),
    ]);
  }

  Future<void> exportToCsv(List<Map<String, String>> data) async {
    List<List<String>> csvData = [
      ['Rangee', 'Colonne', 'Caisse'],
      ...data.map((row) => [row['rangee']!, row['colonne']!, row['caisse']!]),
    ];

    String csv = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/archives_export.csv';
    final file = File(path);
    await file.writeAsString(csv);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported to: $path'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredArchives = archives.where((entry) {
      return entry.values.any(
        (value) => value.toLowerCase().contains(search.toLowerCase()),
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
                  // Top row with summary cards and user profile
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

                  // Show archive header (title + search) only if on Archives page
                  if (selectedIndex == 1) ...[
                    _buildHeader(isWide),
                    const SizedBox(height: 16),
                  ],

                  // Page content or archive data table
                  Expanded(
                    child: selectedIndex == 1
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'John Doe',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text('Admin', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                      company_logo,
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
                _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.archive, 'Archives', 1),
                _buildNavItem(Icons.analytics, 'Reports', 2),
                _buildNavItem(Icons.settings, 'Settings', 3),
                const Divider(height: 1),
                _buildNavItem(Icons.help_outline, 'Help Center', 4),
                _buildNavItem(Icons.logout, 'Logout', 5),
                const Divider(height: 1),
                _buildNavItem(Icons.inventory, 'Bons d\'Entrée/Sortie', 6),
                _buildNavItem(Icons.location_on, 'Localisation', 7),
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
      onTap: () => setState(() => selectedIndex = index),
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _summaryCard(
            icon: Icons.view_list,
            title: 'Rangees',
            value: '12',
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          _summaryCard(
            icon: Icons.grid_on,
            title: 'Colonnes',
            value: '45',
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          _summaryCard(
            icon: Icons.folder,
            title: 'Caisses',
            value: '108',
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
          'Archive Inventory',
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
              hintText: 'Search by rangee, colonne, or caisse',
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

  Widget _buildDataTableCard(List<Map<String, String>> filteredArchives) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => exportToCsv(filteredArchives),
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                    child: Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        'Rangee',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
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
                          Expanded(flex: 2, child: Text(entry['rangee'] ?? '')),
                          Expanded(
                            flex: 2,
                            child: Text(entry['colonne'] ?? ''),
                          ),
                          Expanded(flex: 3, child: Text(entry['caisse'] ?? '')),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
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

  // Archives page widget with full content (search + table)
  Widget _archivesPage() {
    final filteredArchives = archives.where((entry) {
      return entry.values.any(
        (value) => value.toLowerCase().contains(search.toLowerCase()),
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

  // Bons d'Entree / Sortie page placeholder
  Widget _bonsEntreeSortiePage() {
    return Center(
      child: Text(
        'Page Bons d\'Entrée / Sortie',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Localisation page with barcode scanning simulation and archive adding
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
          // Show scanned values or buttons to "scan"
          _barcodeScanStep(
            label: 'Rangee',
            scannedValue: scannedRangee,
            onScan: () => _simulateScan('Rangee'),
          ),
          const SizedBox(height: 16),
          _barcodeScanStep(
            label: 'Colonne',
            scannedValue: scannedColonne,
            onScan: scannedRangee == null
                ? null
                : () => _simulateScan('Colonne'),
          ),
          const SizedBox(height: 16),
          _barcodeScanStep(
            label: 'Caisse',
            scannedValue: scannedCaisse,
            onScan: (scannedRangee == null || scannedColonne == null)
                ? null
                : () => _simulateScan('Caisse'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed:
                (scannedRangee != null &&
                    scannedColonne != null &&
                    scannedCaisse != null)
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
            child: ListView.builder(
              itemCount: archives.length,
              itemBuilder: (context, index) {
                final entry = archives[index];
                return ListTile(
                  title: Text(
                    'Rangee: ${entry['rangee']}, Colonne: ${entry['colonne']}, Caisse: ${entry['caisse']}',
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
    // This simulates scanning a barcode by just opening a dialog to enter text.
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
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
                    if (type == 'Rangee') {
                      scannedRangee = value;
                      scannedColonne = null;
                      scannedCaisse = null;
                    } else if (type == 'Colonne') {
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

  void _addScannedArchive() {
    if (scannedRangee != null &&
        scannedColonne != null &&
        scannedCaisse != null) {
      final exists = archives.any(
        (entry) =>
            entry['rangee'] == scannedRangee &&
            entry['colonne'] == scannedColonne &&
            entry['caisse'] == scannedCaisse,
      );

      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cette archive existe déjà.')),
        );
      } else {
        setState(() {
          archives.add({
            'rangee': scannedRangee!,
            'colonne': scannedColonne!,
            'caisse': scannedCaisse!,
          });
          scannedRangee = null;
          scannedColonne = null;
          scannedCaisse = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archive ajoutée avec succès!')),
        );
      }
    }
  }
}
