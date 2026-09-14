import 'package:url_launcher/url_launcher.dart';
import 'db_helper.dart';

class LauncherUtils {
  static Future<void> makeCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openWhatsApp(String phoneNumber, {String message = ''}) async {
    String clean = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) clean = '91$clean';

    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$clean?text=$encodedMessage';
    final uri = Uri.parse(url);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> sendContactDossierViaWhatsApp(ContactModel person) async {
    final buffer = StringBuffer();
    buffer.writeln('🤝 *WeMet Connection Profile*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Name:* ${person.name}');
    if (person.company?.isNotEmpty ?? false) buffer.writeln('🏢 *Work:* ${person.company}');
    if (person.residence?.isNotEmpty ?? false) buffer.writeln('📍 *Residence:* ${person.residence}');
    if (person.phone?.isNotEmpty ?? false) buffer.writeln('📞 *Phone:* ${person.phone}');
    if (person.hobbies?.isNotEmpty ?? false) buffer.writeln('🎾 *Hobbies:* ${person.hobbies}');
    if (person.familyNotes?.isNotEmpty ?? false) buffer.writeln('👨‍👩‍👧 *Family:* ${person.familyNotes}');
    if (person.lastDiscussion?.isNotEmpty ?? false) {
      buffer.writeln('💬 *Discussion Notes:* ${person.lastDiscussion}');
    }
    buffer.writeln('🗓️ *Met on:* ${person.lastMetDate ?? "N/A"}');

    if (person.phone != null && person.phone!.isNotEmpty) {
      await openWhatsApp(person.phone!, message: buffer.toString());
    }
  }
}
