import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ContactModel {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? photoPath;
  final String? company;
  final String? residence;
  final String? familyNotes;
  final String? hobbies;
  final String? lastMetDate;
  final String? lastDiscussion;

  ContactModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.photoPath,
    this.company,
    this.residence,
    this.familyNotes,
    this.hobbies,
    this.lastMetDate,
    this.lastDiscussion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'photo_path': photoPath,
    'company': company,
    'residence': residence,
    'family_notes': familyNotes,
    'hobbies': hobbies,
    'last_met_date': lastMetDate,
    'last_discussion': lastDiscussion,
  };

  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
    id: map['id'],
    name: map['name'] ?? '',
    phone: map['phone'],
    email: map['email'],
    photoPath: map['photo_path'],
    company: map['company'],
    residence: map['residence'],
    familyNotes: map['family_notes'],
    hobbies: map['hobbies'],
    lastMetDate: map['last_met_date'],
    lastDiscussion: map['last_discussion'],
  );
}

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wemet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            photo_path TEXT,
            company TEXT,
            residence TEXT,
            family_notes TEXT,
            hobbies TEXT,
            last_met_date TEXT,
            last_discussion TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertContact(ContactModel contact) async {
    final db = await database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> mergeContacts(ContactModel primary, ContactModel duplicate) async {
    final db = await database;
    final mergedCompany = (primary.company?.isNotEmpty ?? false) ? primary.company : duplicate.company;
    final mergedPhone = (primary.phone?.isNotEmpty ?? false) ? primary.phone : duplicate.phone;
    final mergedEmail = (primary.email?.isNotEmpty ?? false) ? primary.email : duplicate.email;
    final mergedPhoto = (primary.photoPath?.isNotEmpty ?? false) ? primary.photoPath : duplicate.photoPath;
    final mergedResidence = (primary.residence?.isNotEmpty ?? false) ? primary.residence : duplicate.residence;

    final mergedHobbies = [primary.hobbies, duplicate.hobbies].where((e) => e != null && e.isNotEmpty).join(' | ');
    final mergedFamily = [primary.familyNotes, duplicate.familyNotes].where((e) => e != null && e.isNotEmpty).join(' | ');
    final mergedDiscussion = [primary.lastDiscussion, duplicate.lastDiscussion].where((e) => e != null && e.isNotEmpty).join('\n---\n');

    final updated = ContactModel(
      id: primary.id,
      name: primary.name,
      phone: mergedPhone,
      email: mergedEmail,
      photoPath: mergedPhoto,
      company: mergedCompany,
      residence: mergedResidence,
      hobbies: mergedHobbies,
      familyNotes: mergedFamily,
      lastMetDate: primary.lastMetDate ?? duplicate.lastMetDate,
      lastDiscussion: mergedDiscussion,
    );

    await db.transaction((txn) async {
      await txn.update('contacts', updated.toMap(), where: 'id = ?', whereArgs: [primary.id]);
      await txn.delete('contacts', where: 'id = ?', whereArgs: [duplicate.id]);
    });
  }

  Future<List<ContactModel>> searchContacts(String query) async {
    final db = await database;
    final cleanQuery = '%$query%';
    final results = await db.query(
      'contacts',
      where: '''
        name LIKE ? OR 
        company LIKE ? OR 
        hobbies LIKE ? OR 
        residence LIKE ? OR 
        family_notes LIKE ? OR 
        last_discussion LIKE ?
      ''',
      whereArgs: List.filled(6, cleanQuery),
      orderBy: 'id DESC',
    );
    return results.map((e) => ContactModel.fromMap(e)).toList();
  }
}
