import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'db_helper.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  File? _selectedImage;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _residence = TextEditingController();
  final _hobbies = TextEditingController();
  final _family = TextEditingController();
  final _discussion = TextEditingController();

  Future<void> _pickImage(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 75);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final target = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final file = await File(picked.path).copy(target);
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final item = ContactModel(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      photoPath: _selectedImage?.path,
      company: _company.text.trim(),
      residence: _residence.text.trim(),
      hobbies: _hobbies.text.trim(),
      familyNotes: _family.text.trim(),
      lastMetDate: DateTime.now().toIso8601String().substring(0, 10),
      lastDiscussion: _discussion.text.trim(),
    );

    await DBHelper.instance.insertContact(item);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Connection'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.camera_alt, size: 36, color: Color(0xFF6C5CE7))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _company, decoration: const InputDecoration(labelText: 'Company / Workplace', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _residence, decoration: const InputDecoration(labelText: 'Residence / City', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _hobbies, decoration: const InputDecoration(labelText: 'Hobbies & Interests', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _family, decoration: const InputDecoration(labelText: 'Family (Spouse, kids, pets)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _discussion, maxLines: 3, decoration: const InputDecoration(labelText: 'What did you discuss?', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _save,
              child: const Text('Save to WeMet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
