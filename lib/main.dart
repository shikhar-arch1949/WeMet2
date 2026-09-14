import 'dart:io';
import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'add_contact_screen.dart';
import 'launcher_utils.dart';
import 'contact_sync_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeMetApp());
}

class WeMetApp extends StatelessWidget {
  const WeMetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeMet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          primary: const Color(0xFF6C5CE7),
          secondary: const Color(0xFF00B894),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ContactModel> _contacts = [];
  String _searchQuery = '';
  bool _syncing = false;

  final List<Color> _badgeColors = [
    const Color(0xFF6C5CE7),
    const Color(0xFF00B894),
    const Color(0xFFFF7675),
    const Color(0xFF0984E3),
    const Color(0xFFE84393),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DBHelper.instance.searchContacts(_searchQuery);
    setState(() => _contacts = data);
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final count = await ContactSyncUtils.syncDeviceContacts();
    setState(() => _syncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00B894),
          content: Text('$count contacts imported from phone.'),
        ),
      );
      _load();
    }
  }

  void _showMergeDialog(ContactModel base) {
    ContactModel? target;
    final options = _contacts.where((c) => c.id != base.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Merge into ${base.name}'),
          content: DropdownButton<ContactModel>(
            isExpanded: true,
            hint: const Text('Select duplicate contact'),
            value: target,
            items: options.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
            onChanged: (val) => setDState(() => target = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white),
              onPressed: target == null
                  ? null
                  : () async {
                      await DBHelper.instance.mergeContacts(base, target!);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
              child: const Text('Merge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C5CE7),
        elevation: 0,
        title: const Text('WeMet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Sync Device Contacts',
            onPressed: _syncing ? null : _sync,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
                hintText: 'Search by name, hobby, company, discussion...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _load();
              },
            ),
          ),
          Expanded(
            child: _contacts.isEmpty
                ? const Center(child: Text('No connections found.\nTap + or Sync to add contacts.', textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, idx) {
                      final person = _contacts[idx];
                      final hasPhone = person.phone != null && person.phone!.trim().isNotEmpty;
                      final badgeColor = _badgeColors[idx % _badgeColors.length];

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: badgeColor,
                            backgroundImage: person.photoPath != null ? FileImage(File(person.photoPath!)) : null,
                            child: person.photoPath == null
                                ? Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                : null,
                          ),
                          title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            [person.company, person.hobbies].where((e) => e != null && e.isNotEmpty).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasPhone) ...[
                                IconButton(
                                  icon: const Icon(Icons.chat, color: Color(0xFF00B894)),
                                  tooltip: 'WhatsApp',
                                  onPressed: () => LauncherUtils.openWhatsApp(person.phone!),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone, color: Color(0xFF6C5CE7)),
                                  tooltip: 'Call',
                                  onPressed: () => LauncherUtils.makeCall(person.phone!),
                                ),
                              ],
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'merge') _showMergeDialog(person);
                                  if (val == 'delete') {
                                    DBHelper.instance.deleteContact(person.id!);
                                    _load();
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'merge', child: Text('Merge Duplicate')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete Contact', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _showDetailsDialog(context, person),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Connection'),
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContactScreen()));
          if (res == true) _load();
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, ContactModel person) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (person.photoPath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(person.photoPath!), height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 12),
              if (person.phone?.isNotEmpty ?? false) ...[
                Text('📞 Phone: ${person.phone}'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(38),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Push Dossier via WhatsApp'),
                  onPressed: () => LauncherUtils.sendContactDossierViaWhatsApp(person),
                ),
                const SizedBox(height: 8),
              ],
              if (person.company?.isNotEmpty ?? false) Text('🏢 Company: ${person.company}'),
              if (person.residence?.isNotEmpty ?? false) Text('📍 Location: ${person.residence}'),
              if (person.hobbies?.isNotEmpty ?? false) Text('🎾 Hobbies: ${person.hobbies}'),
              if (person.familyNotes?.isNotEmpty ?? false) Text('👨‍👩‍👧 Family: ${person.familyNotes}'),
              const Divider(height: 20),
              Text('💬 Last Met: ${person.lastMetDate ?? "N/A"}'),
              Text('Discussion: ${person.lastDiscussion ?? "No notes recorded"}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
