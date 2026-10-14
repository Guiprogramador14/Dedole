import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BancoDedole {
  static Database? _database;
  static Future<Database> get database async => _database ??= await _initDatabase();

  static Future<Database> _initDatabase() async {
    final caminho = join(await getDatabasesPath(), 'dedole.db');
    return openDatabase(
      caminho,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE palavras (id INTEGER PRIMARY KEY AUTOINCREMENT, palavra TEXT NOT NULL)');
        await _criarEstado(db);
        await _criarPreferencias(db);
      },
      onUpgrade: (db, anterior, novo) async {
        if (anterior < 2) await _criarEstado(db);
        if (anterior < 3) await _criarPreferencias(db);
      },
    );
  }

  static Future<void> _criarEstado(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS estado_fila (id INTEGER PRIMARY KEY CHECK(id = 1), itens TEXT NOT NULL, atual TEXT, ultima TEXT)');
  }

  static Future<void> _criarPreferencias(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS preferencias (chave TEXT PRIMARY KEY, valor TEXT NOT NULL)');
  }

  static Future<Map<String, String>> carregarPreferencias() async {
    final db = await database;
    final linhas = await db.query('preferencias');
    return {for (final linha in linhas) linha['chave'] as String: linha['valor'] as String};
  }

  static Future<void> salvarPreferencias(Map<String, String> valores) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final entrada in valores.entries) {
        await txn.insert('preferencias', {'chave': entrada.key, 'valor': entrada.value},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Apaga apenas as palavras cadastradas, não a fila ou as preferências.
  static Future<int> limparPalavras() async {
    final db = await database;
    return db.delete('palavras');
  }

  static Future<void> salvarFila(List<String> itens, String? atual, String? ultima) async {
    final db = await database;
    await db.insert('estado_fila', {
      'id': 1,
      'itens': jsonEncode(itens),
      'atual': atual,
      'ultima': ultima,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<({List<String> itens, String? atual, String? ultima})> carregarFila() async {
    final db = await database;
    final linhas = await db.query('estado_fila', where: 'id = ?', whereArgs: [1], limit: 1);
    if (linhas.isEmpty) return (itens: <String>[], atual: null, ultima: null);
    final linha = linhas.first;
    final valores = jsonDecode(linha['itens'] as String) as List<dynamic>;
    return (
      itens: valores.whereType<String>().toList(),
      atual: linha['atual'] as String?,
      ultima: linha['ultima'] as String?,
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
    await db.update('palavras', {'palavra': palavra}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> excluirPalavra(int id) async {
    final db = await database;
    await db.delete('palavras', where: 'id = ?', whereArgs: [id]);
  }
}
