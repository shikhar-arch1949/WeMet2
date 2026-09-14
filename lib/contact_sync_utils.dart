import 'package:flutter_contacts/flutter_contacts.dart';
import 'db_helper.dart';

class ContactSyncUtils {
  static Future<int> syncDeviceContacts() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) return 0;

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withAccounts: true,
    );

    final existing = await DBHelper.instance.searchContacts('');
    final existingPhones = existing
        .map((c) => c.phone?.replaceAll(RegExp(r'[^0-9]'), ''))
        .where((p) => p != null && p.isNotEmpty)
        .toSet();

    int imported = 0;
    for (var c in contacts) {
      if (c.phones.isEmpty) continue;
      final rawPhone = c.phones.first.number;
      final clean = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

      if (clean.isNotEmpty && !existingPhones.contains(clean)) {
        final newPerson = ContactModel(
          name: c.displayName.isNotEmpty ? c.displayName : 'Unknown',
          phone: rawPhone,
          email: c.emails.isNotEmpty ? c.emails.first.address : null,
          company: c.organizations.isNotEmpty ? c.organizations.first.company : null,
          lastMetDate: DateTime.now().toIso8601String().substring(0, 10),
          lastDiscussion: 'Imported from phone address book',
        );

        await DBHelper.instance.insertContact(newPerson);
        existingPhones.add(clean);
        imported++;
      }
    }
    return imported;
  }
}
