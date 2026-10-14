import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BancoDedole {
  static Database? _database;

  static Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  static Future<Database> _initDatabase() async {
    final caminho = join(await getDatabasesPath(), 'dedole.db');
    return openDatabase(
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
    await db.insert('palavras', {'palavra': palavra});
  }

  static Future<List<Map<String, dynamic>>> buscarPalavras() async {
    final db = await database;
    return db.query('palavras', orderBy: 'id DESC');
  }

  static Future<void> editarPalavra(int id, String palavra) async {
    final db = await database;
    await db.update('palavras', {'palavra': palavra},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> excluirPalavra(int id) async {
    final db = await database;
    await db.delete('palavras', where: 'id = ?', whereArgs: [id]);
  }
}
