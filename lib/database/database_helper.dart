import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/flavor.dart';
import '../models/log.dart';
import '../models/log_with_flavor.dart';

/// Helper class for managing SQLite database operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Gets the database instance, creating it if it doesn't exist
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('monster_meter.db');
    return _database!;
  }

  /// Initializes the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE flavors ADD COLUMN image_path TEXT');
    }
  }

  /// Creates the database tables
  Future<void> _createDB(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE
      )
    ''');

    // Create flavors table
    await db.execute('''
      CREATE TABLE flavors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        ml INTEGER NOT NULL,
        caffeine_mg INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        image_path TEXT
      )
    ''');

    // Create logs table
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        flavor_id INTEGER NOT NULL,
        price_paid REAL NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (flavor_id) REFERENCES flavors (id)
      )
    ''');

    // Insert default user
    await db.insert('users', {'username': 'default_user'});

    // Insert some popular Monster Energy flavors with images
    final defaultFlavors = [
      {'name': 'Original', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/orginal-monster.webp'},
      {'name': 'Pipeline Punch', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/pipeline-punch.webp'},
      {'name': 'Pacific Punch', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/pacific-punch.webp'},
      {'name': 'Rio Punch', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/rio-punch.webp'},
      {'name': 'Mango Loco', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/mucho-loco.webp'},
      {'name': 'Zero Sugar Ultra', 'ml': 500, 'caffeine_mg': 140, 'is_active': 1, 'image_path': 'assets/images/flavors/Zero-sugar-ultra.webp'},
      {'name': 'Zero Sugar Ultra Rosa', 'ml': 500, 'caffeine_mg': 140, 'is_active': 1, 'image_path': 'assets/images/flavors/Zero-sugar-ultra-rosa.webp'},
      {'name': 'Aussie Lemonade', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/Aussie-lemonade.webp'},
      {'name': 'Peachy Keen', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/peachy-keen.webp'},
      {'name': 'The Doctor', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/The-doctor.webp'},
      {'name': 'Lando Norris', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/Lando-norris.webp'},
    ];

    for (var flavor in defaultFlavors) {
      await db.insert('flavors', flavor);
    }
  }

  // USER OPERATIONS

  /// Creates a new user
  Future<User> createUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  /// Gets a user by ID
  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Gets the default user (for single-user app)
  Future<User?> getDefaultUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // FLAVOR OPERATIONS

  /// Creates a new flavor
  Future<Flavor> createFlavor(Flavor flavor) async {
    final db = await database;
    final id = await db.insert('flavors', flavor.toMap());
    return flavor.copyWith(id: id);
  }

  /// Gets all active flavors
  Future<List<Flavor>> getActiveFlavors() async {
    final db = await database;
    final maps = await db.query(
      'flavors',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Flavor.fromMap(map)).toList();
  }

  /// Gets all flavors (including inactive)
  Future<List<Flavor>> getAllFlavors() async {
    final db = await database;
    final maps = await db.query('flavors', orderBy: 'name ASC');
    return maps.map((map) => Flavor.fromMap(map)).toList();
  }

  /// Gets a flavor by ID
  Future<Flavor?> getFlavor(int id) async {
    final db = await database;
    final maps = await db.query(
      'flavors',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Flavor.fromMap(maps.first);
    }
    return null;
  }

  /// Updates a flavor
  Future<int> updateFlavor(Flavor flavor) async {
    final db = await database;
    return db.update(
      'flavors',
      flavor.toMap(),
      where: 'id = ?',
      whereArgs: [flavor.id],
    );
  }

  /// Deletes a flavor
  Future<int> deleteFlavor(int id) async {
    final db = await database;
    return db.delete(
      'flavors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // LOG OPERATIONS

  /// Creates a new log entry
  Future<Log> createLog(Log log) async {
    final db = await database;
    final id = await db.insert('logs', log.toMap());
    return log.copyWith(id: id);
  }

  /// Gets all logs
  Future<List<Log>> getAllLogs() async {
    final db = await database;
    final maps = await db.query('logs', orderBy: 'timestamp DESC');
    return maps.map((map) => Log.fromMap(map)).toList();
  }

  /// Gets logs for a specific date
  Future<List<LogWithFlavor>> getLogsByDate(String date) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT l.*, f.name, f.ml, f.caffeine_mg, f.is_active, f.image_path
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      WHERE DATE(l.timestamp) = DATE(?)
      ORDER BY l.timestamp DESC
    ''', [date]);

    return maps.map((map) {
      return LogWithFlavor(
        log: Log.fromMap(map),
        flavor: Flavor.fromMap(map),
      );
    }).toList();
  }

  /// Gets all logs with flavor details
  Future<List<LogWithFlavor>> getLogsWithFlavors() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT l.*, f.name, f.ml, f.caffeine_mg, f.is_active, f.image_path
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      ORDER BY l.timestamp DESC
    ''');

    return maps.map((map) {
      return LogWithFlavor(
        log: Log.fromMap(map),
        flavor: Flavor.fromMap(map),
      );
    }).toList();
  }

  /// Gets today's caffeine total
  Future<int> getTodaysCaffeineTotal() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(f.caffeine_mg) as total
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      WHERE DATE(l.timestamp) = DATE('now', 'localtime')
    ''');

    final total = result.first['total'];
    return total != null ? (total as num).toInt() : 0;
  }

  /// Gets today's drink count
  Future<int> getTodaysDrinkCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM logs
      WHERE DATE(timestamp) = DATE('now', 'localtime')
    ''');

    return (result.first['count'] as int?) ?? 0;
  }

  /// Gets today's total spending
  Future<double> getTodaysTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(price_paid) as total
      FROM logs
      WHERE DATE(timestamp) = DATE('now', 'localtime')
    ''');

    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Deletes a log entry
  Future<int> deleteLog(int id) async {
    final db = await database;
    return db.delete(
      'logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Closes the database connection
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

