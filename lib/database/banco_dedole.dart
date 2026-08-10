import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BancoDedole {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final caminho = join(
      await getDatabasesPath(),
      'dedole.db',
    );

    return await openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE palavras (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            palavra TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> adicionarPalavra(String palavra) async {
    final db = await database;

    await db.insert(
      'palavras',
      {
        'palavra': palavra,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> buscarPalavras() async {
    final db = await database;

    return await db.query(
      'palavras',
      orderBy: 'id DESC',
    );
  }

  static Future<void> excluirPalavra(int id) async {
    final db = await database;

    await db.delete(
      'palavras',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}