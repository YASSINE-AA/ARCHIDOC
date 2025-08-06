
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:login/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:login/database_helper.dart';
import 'dart:io';
import 'package:data_table_2/data_table_2.dart';

const String companyLogo = 'assets/archidoc.png';

class MainPage extends StatefulWidget {
  final String username;
  final String role;
  final DatabaseHelper database;
  const MainPage({super.key, required this.username, required this.role, required this.database});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bonCodeController = TextEditingController();
  int selectedIndex = 0;
  String search = '';
  String? scannedColonne;
  String? scannedCaisse;
  bool ajoutBonActif = false;
  List<Map<String, dynamic>> archives = [];
  bool isLoading = true;
  bool _loadingBons = false;

  String? _currentScan;
  bool _isEntry = true;
  List<Map<String, dynamic>> _bons = [];
  String? _currentBonNumber;
  String? _selectedBonId;

// Pagination variables
  int _archivesCurrentPage = 0;
  int _bonsCurrentPage = 0;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadArchives();
    _loadBons();
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
      print('Loaded archives: $archives');
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load archives: $e')));
    }
  }

  Future<void> _loadBons() async {
    if (!mounted) return;

    setState(() => _loadingBons = true);
    try {
      final results = await widget.database.getAllBons();
      if (!mounted) return;

      setState(() {
        _bons = results;
        _loadingBons = false;
        if (_selectedBonId != null) {
          final validBonIds = _bons.map((bon) => bon['id'].toString()).toSet();
          if (!validBonIds.contains(_selectedBonId)) {
            _selectedBonId = null;
            _currentBonNumber = null;
            ajoutBonActif = false;
          }
        }
      });
      print('Loaded bons: $results');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingBons = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bons: $e')),
      );
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
    } catch (e) {
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
      final fileName = 'archives_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final path = '${directory.path}/$fileName';
      await File(path).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported to: $path'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'SEND EMAIL',
              onPressed: () => _sendEmailWithAttachment(
                filePath: path,
                subject: 'Archives Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                body: 'Please find attached the exported archives data.\n\n'
                    'File: $fileName\n'
                    'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> exportBonsToCsv() async {
    try {
      final bons = await widget.database.getAllBons();

      List<List<String>> csvData = [
        ['Num Bon', 'Code Archive', 'Date'],
        ...bons.map(
              (row) => [
            '${row['type'] == 'Entrée' ? 'BET' : 'BST'}${row['bon_number']}/${row['bon_year']}',
            row['code']?.toString() ?? '',
            row['bon_date']?.toString() ?? '',
          ],
        ),
      ];

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/bons_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      await File(path).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bons CSV exported to: $path'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'SEND EMAIL',
              onPressed: () => _sendEmailWithAttachment(
                filePath: path,
                subject: 'Bons Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                body: 'Please find attached the exported bons data.\n\n'
                    'File path: $path\n'
                    'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> purgeArchives() async {
    try {
      await widget.database.purgeArchives();
      await _loadArchives();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archives purged successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purge failed: $e')));
      }
    }
  }

  Future<void> purgeBons() async {
    try {
      await widget.database.purgeBons();
      await _loadBons();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bons purged successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purge failed: $e')));
      }
    }
  }

  Future<void> _startNewBon() async {
    if (!mounted) return;

    setState(() => _loadingBons = true);
    try {
      final bonNumber = await widget.database.generateNextBonNumber(_isEntry ? 'Entrée' : 'Sortie');
      final year = DateTime.now().year.toString();
      final fullBonNumber = '${_isEntry ? 'BET' : 'BST'}$bonNumber/$year';

      final newBonId = await widget.database.insertBon(
        _isEntry ? 'Entrée' : 'Sortie',
        '',
        bonNumber,
        year,
      );

      await _loadBons();

      if (mounted) {
        setState(() {
          _currentBonNumber = fullBonNumber;
          _selectedBonId = newBonId.toString();
          ajoutBonActif = true;
          _loadingBons = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nouveau bon créé: $fullBonNumber')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBons = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du bon: $e')),
        );
      }
    }
  }

  Future<void> _handleBonCodeChange(String value) async {
    final code = value.trim();
    if (code.isEmpty || _currentBonNumber == null || _selectedBonId == null) return;

    try {
      final parts = _currentBonNumber!.split('/');
      final bonNumber = parts[0].substring(3);
      final bonYear = parts[1];

      await widget.database.insertBon(
        _isEntry ? 'Entrée' : 'Sortie',
        code,
        bonNumber,
        bonYear,
      );

      await _loadBons();
      if (mounted) {
        setState(() {
          _bonCodeController.clear();
          _currentScan = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Caisse $code ajoutée au bon $_currentBonNumber')),
        );
      }
      print('Added caisse $code to bon $_currentBonNumber');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
        );
      }
      print('Error adding caisse: $e');
    }
  }

  Widget _bonsEntreeSortiePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: exportBonsToCsv,
                  icon: const Icon(Icons.download),
                  label: const Text('CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _startNewBon,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau Bon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                if (widget.role == "admin" && _bons.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: purgeBons,
                    icon: const Icon(Icons.delete),
                    label: const Text('Purge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentBonNumber != null)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Bon en cours: $_currentBonNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_loadingBons)
              const Center(child: CircularProgressIndicator())
            else if (ajoutBonActif && _currentBonNumber != null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Entrée'),
                          selected: _isEntry,
                          selectedColor: Colors.green[100],
                          onSelected: (selected) {
                            setState(() {
                              _isEntry = selected;
                              _bonCodeController.clear();
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
                          selectedColor: Colors.red[100],
                          onSelected: (selected) {
                            setState(() {
                              _isEntry = !selected;
                              _bonCodeController.clear();
                              _currentScan = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            _isEntry ? 'Entrée d\'Archive' : 'Sortie d\'Archive',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bonCodeController,
                            keyboardType: TextInputType.text,
                            enableInteractiveSelection: false,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Code archive',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.qr_code),
                            ),
                            onChanged: _handleBonCodeChange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bons enregistrés',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildBonsDataTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getCaissesForBon(String bonNumber) async {
    try {
      final parts = bonNumber.split('/');
      if (parts.length != 2) {
        print('Invalid bon number format: $bonNumber');
        return [];
      }
      final bonNumberOnly = parts[0].substring(3);
      final bonYear = parts[1];

      final bons = await widget.database.getBonsByNumber(bonNumberOnly, bonYear);
      print('Bons fetched for $bonNumber: $bons');
      final caisseCodes = bons
          .map((bon) => bon['code']?.toString())
          .where((code) => code != null && code.isNotEmpty)
          .toSet()
          .toList();
      print('Caisse codes for $bonNumber: $caisseCodes');

      final caisses = <Map<String, dynamic>>[];
      for (var code in caisseCodes) {
        final matchingArchive = archives.firstWhere(
              (archive) => archive['caisse']?.toString() == code,
          orElse: () => {'colonne': 'N/A', 'caisse': code},
        );
        caisses.add(matchingArchive);
      }
      print('Matching caisses for $bonNumber: $caisses');
      return caisses;
    } catch (e) {
      if (mounted) {
        print('Error fetching caisses for bon $bonNumber: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des caisses: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _editBon(Map<String, dynamic> bon) async {
    final typeController = TextEditingController(text: bon['type']);
    bool isEntry = bon['type'] == 'Entrée';
    final bonNumber = '${bon['type'] == 'Entrée' ? 'BET' : 'BST'}${bon['bon_number']}/${bon['bon_year']}';
    List<Map<String, dynamic>> caisses = await _getCaissesForBon(bonNumber);
    final bonCodeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Modifier Bon: $bonNumber'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [

                        ],
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Caisses Associées',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: caisses.isEmpty
                            ? const Center(child: Text('Aucune caisse associée'))
                            : DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 300,
                          columns: const [
                            DataColumn2(label: Text('Colonne')),
                            DataColumn2(label: Text('Caisse')),
                            DataColumn2(label: Text('Actions')),
                          ],
                          rows: caisses.map((caisse) {
                            return DataRow(cells: [
                              DataCell(Text(caisse['colonne']?.toString() ?? 'N/A')),
                              DataCell(Text(caisse['caisse']?.toString() ?? '')),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      await _editCaisse(caisse, bon);
                                      final updatedCaisses = await _getCaissesForBon(bonNumber);
                                      setDialogState(() {
                                        caisses = updatedCaisses;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _deleteCaisseFromBon(caisse, bon);
                                      final updatedCaisses = await _getCaissesForBon(bonNumber);
                                      setDialogState(() {
                                        caisses = updatedCaisses;
                                      });
                                    },
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      final bons = await widget.database.getBonsByNumber(bon['bon_number'], bon['bon_year']);
                      for (var b in bons) {
                        await widget.database.updateBon(
                          b['id'],
                          typeController.text,
                          b['code'],
                          b['bon_number'],
                          b['bon_year'],
                        );
                      }
                      await _loadBons();
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bon modifié avec succès')),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors de la modification: $e')),
                        );
                      }
                      print('Error updating bon: $e');
                    }
                  },
                  child: const Text('Sauvegarder', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editCaisse(Map<String, dynamic> caisse, Map<String, dynamic> bon) async {
    final colonneController = TextEditingController(text: caisse['colonne']?.toString() ?? 'N/A');
    final caisseController = TextEditingController(text: caisse['caisse']?.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Modifier Caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colonneController,
            enableInteractiveSelection: false,
              decoration: const InputDecoration(labelText: 'Colonne'),
              enabled: caisse['id'] != null, // Disable if no archive entry
            ),
            TextField(
              enableInteractiveSelection: false,
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
// Update archive only if it exists
                if (caisse['id'] != null) {
                  await widget.database.updateArchive(
                    caisse['id'],
                    colonneController.text,
                    caisseController.text,
                  );
                }
// Update bon code if caisse code changed
                if (caisseController.text != caisse['caisse']) {
                  final bons = await widget.database.getBonsByNumber(bon['bon_number'], bon['bon_year']);
                  for (var b in bons) {
                    if (b['code'] == caisse['caisse']) {
                      await widget.database.updateBon(
                        b['id'],
                        b['type'],
                        caisseController.text,
                        b['bon_number'],
                        b['bon_year'],
                      );
                    }
                  }
                }
                await _loadBons();
                if (caisse['id'] != null) await _loadArchives();
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caisse modifiée avec succès')),
                );
                print('Updated caisse ${caisse['caisse']} to ${caisseController.text} for bon ${bon['bon_number']}/${bon['bon_year']}');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la modification: $e')),
                  );
                }
                print('Error editing caisse: $e');
              }
            },
            child: const Text('Sauvegarder', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCaisseFromBon(Map<String, dynamic> caisse, Map<String, dynamic> bon) async {
    try {
      final bons = await widget.database.getBonsByNumber(bon['bon_number'], bon['bon_year']);
      final matchingBon = bons.firstWhere(
            (b) => b['code'] == caisse['caisse'] && b['type'] == bon['type'],
        orElse: () => {},
      );

      if (matchingBon.isNotEmpty) {
        await widget.database.deleteBon(matchingBon['id']);
        await _loadBons();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caisse retirée du bon')),
          );
        }
        print('Deleted caisse ${caisse['caisse']} from bon ${bon['bon_number']}/${bon['bon_year']}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
      print('Error deleting caisse: $e');
    }
  }

  Future<void> _deleteBon(Map<String, dynamic> bon) async {
    try {
      final bons = await widget.database.getBonsByNumber(bon['bon_number'], bon['bon_year']);
      for (var b in bons) {
        await widget.database.deleteBon(b['id']);
      }
      await _loadBons();
      if (context.mounted) {
        setState(() {
          if (_selectedBonId == bon['id'].toString()) {
            _currentBonNumber = null;
            _selectedBonId = null;
            ajoutBonActif = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bon supprimé avec succès')),
        );
      }
      print('Deleted bon ${bon['bon_number']}/${bon['bon_year']}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
      print('Error deleting bon: $e');
    }
  }

  Widget _buildBonsDataTable() {
    if (_bons.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucun bon enregistré',
            style: TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: _startNewBon,
            child: const Text('Créer un nouveau bon'),
          ),
        ],
      );
    }

    final uniqueBons = <String, Map<String, dynamic>>{};
    for (var bon in _bons) {
      final key = '${bon['type']}${bon['bon_number']}/${bon['bon_year']}';
      if (!uniqueBons.containsKey(key)) {
        uniqueBons[key] = bon;
      }
    }

    final startIndex = _bonsCurrentPage * _rowsPerPage;
    final endIndex = (_bonsCurrentPage + 1) * _rowsPerPage;
    final paginatedBons = uniqueBons.values.toList().sublist(
      startIndex,
      endIndex > uniqueBons.length ? uniqueBons.length : endIndex,
    );

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 600,
            columns: [
              const DataColumn2(label: Text('Type')),
              const DataColumn2(label: Text('Numéro Bon')),
              const DataColumn2(label: Text('Date')),
              if (widget.role == "admin") const DataColumn2(label: Text('Actions')),
            ],
            rows: paginatedBons.map((bon) {
              final bonNumber = '${bon['type'] == 'Entrée' ? 'BET' : 'BST'}${bon['bon_number']}/${bon['bon_year']}';
              return DataRow(cells: [
                DataCell(Row(
                  children: [
                    Icon(
                      bon['type'] == 'Entrée' ? Icons.input : Icons.output,
                      color: bon['type'] == 'Entrée' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(bon['type']),
                  ],
                )),
                DataCell(Text(bonNumber)),
                DataCell(Text(
                  DateFormat('dd/MM HH:mm').format(DateTime.parse(bon['bon_date'])),
                )),
                if (widget.role == "admin")
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editBon(bon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBon(bon),
                      ),
                    ],
                  )),
              ]);
            }).toList(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _bonsCurrentPage > 0
                  ? () => setState(() => _bonsCurrentPage--)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page ${_bonsCurrentPage + 1}'),
            IconButton(
              onPressed: endIndex < uniqueBons.length
                  ? () => setState(() => _bonsCurrentPage++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
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
                side: const BorderSide(color: Colors.grey),
              ),
            ),
            if (widget.role == "admin")
              ElevatedButton.icon(
                onPressed: purgeArchives,
                icon: const Icon(Icons.delete),
                label: const Text('Purge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () => setState(() => selectedIndex = 2),
              icon: const Icon(Icons.add),
              label: const Text('Ajout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        isLoading
            ? const CircularProgressIndicator()
            : filteredArchives.isEmpty
            ? const Text('Pas d\'archives')
            : _buildArchivesDataTable(filteredArchives),
      ],
    );
  }

  Widget _buildArchivesDataTable(List<Map<String, dynamic>> filteredArchives) {
    final startIndex = _archivesCurrentPage * _rowsPerPage;
    final endIndex = (_archivesCurrentPage + 1) * _rowsPerPage;
    final paginatedArchives = filteredArchives.sublist(
      startIndex,
      endIndex > filteredArchives.length ? filteredArchives.length : endIndex,
    );

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 600,
            columns: [
              const DataColumn2(label: Text('Colonne')),
              const DataColumn2(label: Text('Caisse')),
              if (widget.role == "admin") const DataColumn2(label: Text('Actions')),
            ],
            rows: paginatedArchives.map((archive) {
              return DataRow(cells: [
                DataCell(Text(archive['colonne']?.toString() ?? '')),
                DataCell(Text(archive['caisse']?.toString() ?? '')),
                if (widget.role == "admin")
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editArchive(archive),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteArchive(archive),
                      ),
                    ],
                  )),
              ]);
            }).toList(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _archivesCurrentPage > 0
                  ? () => setState(() => _archivesCurrentPage--)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page ${_archivesCurrentPage + 1}'),
            IconButton(
              onPressed: endIndex < filteredArchives.length
                  ? () => setState(() => _archivesCurrentPage++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editArchive(Map<String, dynamic> archive) async {
    final colonneController = TextEditingController(text: archive['colonne']?.toString());
    final caisseController = TextEditingController(text: archive['caisse']?.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Modifier Archive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colonneController,
              decoration: const InputDecoration(labelText: 'Colonne'),
              enableInteractiveSelection: false, // Allows pasting and selection
            ),
            TextField(
              controller: caisseController,
              decoration: const InputDecoration(labelText: 'Caisse'),
                enableInteractiveSelection: false
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la modification: $e')));
                }
              }
            },
            child: const Text('Sauvegarder', style: TextStyle(color: Colors.blue)),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archive supprimée')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression: $e')));
      }
    }
  }

  Widget _localisationPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter Archive',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              scannedColonne == null ? null : () => _addScannedArchive(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Archives:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (archives.isEmpty)
              const Center(child: Text('Pas d\'archives'))
            else
              _buildArchivesDataTable(archives),
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
                readOnly: false,
                controller: controller,
                keyboardType: TextInputType.text,
                enableInteractiveSelection: false,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: label == "Colonne" ? const Icon(Icons.view_column) : const Icon(Icons.folder),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: label,
                  hintText: 'Enter $label',
                ),
                onChanged: (text) {
                  setState(() {
                    if (label == 'Colonne') {
                      scannedColonne = text;
                    } else if (label == 'Caisse') {
                      scannedCaisse = text;
                      if (onScan != null) onScan();
                    }
                  });
                },
              ),
            ),
            if (label == 'Colonne' && scannedColonne != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    scannedColonne = null;
                  });
                },
                icon: const Icon(Icons.clear),
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
      final filteredArchives = archives.where((entry) {
        return entry.values.any(
              (value) => value.toString().toLowerCase().contains(scannedCaisse!.toLowerCase()),
        );
      }).toList();

      if (filteredArchives.isEmpty) {
        await widget.database.insertArchive(scannedColonne!, scannedCaisse!);
        await _loadArchives();
        setState(() {
          scannedCaisse = null;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archive ajoutée avec succès!')),
          );
        }
      } else {
        setState(() {
          scannedCaisse = null;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archive existant!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ajout: $e')));
      }
    }
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
        return const Center(child: Text('Page non trouvée'));
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
          label: 'Déconnexion',
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
            backgroundColor: Colors.blue,
            child: Text(
              widget.username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.role),
              Text(
                widget.username,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              children: [
                Image.asset(companyLogo, height: 50),
                const SizedBox(height: 10),
                Text(
                  widget.username,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(widget.role, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          _buildNavItem(Icons.archive, 'Archives', 0),
          _buildNavItem(Icons.inventory, 'Bons d\'Entrée/Sortie', 1),
          _buildNavItem(Icons.location_on, 'Localisation', 2),
          const Divider(),
          _buildNavItem(Icons.logout, 'Déconnexion', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
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
            title: 'Bons',
            value: _bons.length.toString(),
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
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
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
        Text(
          selectedIndex == 0
              ? 'Archives'
              : selectedIndex == 1
              ? 'Bons'
              : 'Localisation',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (selectedIndex == 0)
          SizedBox(
            width: isWide ? 300 : MediaQuery.of(context).size.width * 0.5,
            child: TextField(
              controller: _searchController,

              decoration: InputDecoration(
                hintText: 'Recherche...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    final filteredArchives = archives.where((entry) {
      return entry.values.any(
            (value) => value.toString().toLowerCase().contains(search.toLowerCase()),
      );
    }).toList();

    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

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
            const Text('ARCHIDOC'),
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
}
