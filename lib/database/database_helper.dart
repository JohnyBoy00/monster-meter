import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
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
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE flavors ADD COLUMN image_path TEXT');
    }
    // On any upgrade, sync default flavors: insert missing, update existing (ml, caffeine, image)
    await _ensureDefaultFlavors(db);
  }

  /// Returns the list of default flavors (used on create and when adding new defaults on upgrade).
  static List<Map<String, Object?>> _getDefaultFlavors() {
    return [
      {'name': 'Original', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/orginal-monster.webp'},
      {'name': 'Pipeline Punch', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/pipeline-punch.webp'},
      {'name': 'Pacific Punch', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/pacific-punch.webp'},
      {'name': 'Rio Punch', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/rio-punch.webp'},
      {'name': 'Mango Loco', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/mucho-loco.webp'},
      {'name': 'Zero Sugar Ultra', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/Zero-sugar-ultra.webp'},
      {'name': 'Zero Sugar Ultra Rosa', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/Zero-sugar-ultra-rosa.webp'},
      {'name': 'Aussie Lemonade', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/Aussie-lemonade.webp'},
      {'name': 'Peachy Keen', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/peachy-keen.webp'},
      {'name': 'The Doctor', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/The-doctor.webp'},
      {'name': 'Lando Norris', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/Lando-norris.webp'},
      {'name': 'Strawberry Dreams', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/strawberry-dreams.webp'},
      {'name': 'Zero-Sugar Ultra Fiesta', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/ultra-fiesta-mango.webp'},
      {'name': 'Viking Berry', 'ml': 500, 'caffeine_mg': 160, 'is_active': 1, 'image_path': 'assets/images/flavors/viking-berry.webp'},
    ];
  }

  /// Ensures default flavors exist and syncs their data (by name). Inserts if missing; updates
  /// ml, caffeine_mg, image_path if the row exists so corrections in code apply on upgrade.
  Future<void> _ensureDefaultFlavors(Database db) async {
    for (var flavor in _getDefaultFlavors()) {
      final name = flavor['name'] as String;
      final existing = await db.query(
        'flavors',
        where: 'name = ?',
        whereArgs: [name],
      );
      if (existing.isEmpty) {
        await db.insert('flavors', flavor);
      } else {
        await db.update(
          'flavors',
          {
            'ml': flavor['ml'],
            'caffeine_mg': flavor['caffeine_mg'],
            'image_path': flavor['image_path'],
          },
          where: 'name = ?',
          whereArgs: [name],
        );
      }
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

    // Insert default flavors
    for (var flavor in _getDefaultFlavors()) {
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

  /// Gets weekly statistics for a specific week
  /// [startDate] should be the start of the week (Monday) in 'yyyy-MM-dd' format
  Future<Map<String, dynamic>> getWeeklyStats({String? startDate}) async {
    final db = await database;
    final weekStart = startDate ?? 
        DateFormat('yyyy-MM-dd').format(
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1))
        );
    
    final result = await db.rawQuery('''
      SELECT 
        DATE(l.timestamp) as date,
        COUNT(*) as drinks,
        SUM(f.caffeine_mg) as caffeine,
        SUM(l.price_paid) as spending
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      WHERE DATE(l.timestamp) >= DATE(?)
        AND DATE(l.timestamp) < DATE(?, '+7 days')
      GROUP BY DATE(l.timestamp)
      ORDER BY DATE(l.timestamp) ASC
    ''', [weekStart, weekStart]);

    int totalDrinks = 0;
    int totalCaffeine = 0;
    double totalSpending = 0.0;
    final dailyData = <String, Map<String, dynamic>>{};

    for (var row in result) {
      final date = row['date'] as String;
      final drinks = (row['drinks'] as num?)?.toInt() ?? 0;
      final caffeine = (row['caffeine'] as num?)?.toInt() ?? 0;
      final spending = (row['spending'] as num?)?.toDouble() ?? 0.0;

      totalDrinks += drinks;
      totalCaffeine += caffeine;
      totalSpending += spending;

      dailyData[date] = {
        'drinks': drinks,
        'caffeine': caffeine,
        'spending': spending,
      };
    }

    return {
      'totalDrinks': totalDrinks,
      'totalCaffeine': totalCaffeine,
      'totalSpending': totalSpending,
      'dailyData': dailyData,
    };
  }

  /// Gets monthly statistics for a specific month
  /// [year] and [month] should be the year and month (1-12) to query
  /// Returns weekly aggregated data for the month
  Future<Map<String, dynamic>> getMonthlyStats({int? year, int? month}) async {
    final db = await database;
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;
    final monthStart = '$targetYear-${targetMonth.toString().padLeft(2, '0')}-01';
    
    // Get daily data first
    final dailyResult = await db.rawQuery('''
      SELECT 
        DATE(l.timestamp) as date,
        COUNT(*) as drinks,
        SUM(f.caffeine_mg) as caffeine,
        SUM(l.price_paid) as spending
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      WHERE strftime('%Y-%m', l.timestamp) = strftime('%Y-%m', ?)
      GROUP BY DATE(l.timestamp)
      ORDER BY DATE(l.timestamp) ASC
    ''', [monthStart]);

    // Aggregate by week
    final weeklyData = <String, Map<String, dynamic>>{};
    int totalDrinks = 0;
    int totalCaffeine = 0;
    double totalSpending = 0.0;

    for (var row in dailyResult) {
      final dateStr = row['date'] as String;
      final date = DateTime.parse(dateStr);
      // Get the start of the week (Monday) for this date
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);
      
      final drinks = (row['drinks'] as num?)?.toInt() ?? 0;
      final caffeine = (row['caffeine'] as num?)?.toInt() ?? 0;
      final spending = (row['spending'] as num?)?.toDouble() ?? 0.0;

      if (weeklyData.containsKey(weekKey)) {
        weeklyData[weekKey]!['drinks'] = 
            (weeklyData[weekKey]!['drinks'] as int) + drinks;
        weeklyData[weekKey]!['caffeine'] = 
            (weeklyData[weekKey]!['caffeine'] as int) + caffeine;
        weeklyData[weekKey]!['spending'] = 
            (weeklyData[weekKey]!['spending'] as double) + spending;
      } else {
        weeklyData[weekKey] = {
          'drinks': drinks,
          'caffeine': caffeine,
          'spending': spending,
        };
      }

      totalDrinks += drinks;
      totalCaffeine += caffeine;
      totalSpending += spending;
    }

    return {
      'totalDrinks': totalDrinks,
      'totalCaffeine': totalCaffeine,
      'totalSpending': totalSpending,
      'dailyData': weeklyData, // Actually weekly data for monthly view
      'year': targetYear,
      'month': targetMonth,
    };
  }

  /// Gets most drank flavor statistics, optionally filtered by date range
  /// [startDate] and [endDate] in 'yyyy-MM-dd' format; if both null, returns all-time
  Future<List<Map<String, dynamic>>> getMostDrankFlavors({
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    final useRange = startDate != null && endDate != null;
    final result = await db.rawQuery(
      useRange
          ? '''
      SELECT 
        f.id,
        f.name,
        f.image_path,
        COUNT(l.id) as drink_count,
        SUM(f.caffeine_mg) as total_caffeine,
        SUM(l.price_paid) as total_spending
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      WHERE DATE(l.timestamp) >= ? AND DATE(l.timestamp) <= ?
      GROUP BY f.id, f.name, f.image_path
      ORDER BY drink_count DESC
      LIMIT ?
    '''
          : '''
      SELECT 
        f.id,
        f.name,
        f.image_path,
        COUNT(l.id) as drink_count,
        SUM(f.caffeine_mg) as total_caffeine,
        SUM(l.price_paid) as total_spending
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      GROUP BY f.id, f.name, f.image_path
      ORDER BY drink_count DESC
      LIMIT ?
    ''',
      useRange ? [startDate, endDate, limit] : [limit],
    );

    return result.map((row) => {
      'id': row['id'] as int,
      'name': row['name'] as String,
      'imagePath': row['image_path'] as String?,
      'drinkCount': (row['drink_count'] as num?)?.toInt() ?? 0,
      'totalCaffeine': (row['total_caffeine'] as num?)?.toInt() ?? 0,
      'totalSpending': (row['total_spending'] as num?)?.toDouble() ?? 0.0,
    }).toList();
  }

  /// Returns every flavor with at least one log, ordered by drink count (highest first).
  /// When [startDate] and [endDate] are both set (yyyy-MM-dd), counts are limited to that range.
  /// When either is null, treats as all-time (same as both null).
  Future<List<Map<String, dynamic>>> getFlavorDrinkCountsOrdered({
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    final useRange = startDate != null && endDate != null;
    final result = await db.rawQuery(
      useRange
          ? '''
      SELECT 
        f.id,
        f.name,
        f.image_path,
        COUNT(l.id) as drink_count,
        SUM(f.caffeine_mg) as total_caffeine,
        SUM(l.price_paid) as total_spending
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      WHERE DATE(l.timestamp) >= ? AND DATE(l.timestamp) <= ?
      GROUP BY f.id, f.name, f.image_path
      ORDER BY drink_count DESC
    '''
          : '''
      SELECT 
        f.id,
        f.name,
        f.image_path,
        COUNT(l.id) as drink_count,
        SUM(f.caffeine_mg) as total_caffeine,
        SUM(l.price_paid) as total_spending
      FROM logs l
      INNER JOIN flavors f ON l.flavor_id = f.id
      GROUP BY f.id, f.name, f.image_path
      ORDER BY drink_count DESC
    ''',
      useRange ? [startDate, endDate] : [],
    );

    return result.map((row) => {
      'id': row['id'] as int,
      'name': row['name'] as String,
      'imagePath': row['image_path'] as String?,
      'drinkCount': (row['drink_count'] as num?)?.toInt() ?? 0,
      'totalCaffeine': (row['total_caffeine'] as num?)?.toInt() ?? 0,
      'totalSpending': (row['total_spending'] as num?)?.toDouble() ?? 0.0,
    }).toList();
  }

  /// All active flavors with how many times each was logged in the period (0 if none).
  /// [startDate] and [endDate] inclusive yyyy-MM-dd; both null means all-time.
  Future<List<Map<String, dynamic>>> getAllActiveFlavorsWithDrinkCounts({
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    final useRange = startDate != null && endDate != null;
    final result = await db.rawQuery(
      useRange
          ? '''
      SELECT 
        f.id,
        f.name,
        f.image_path,
        COUNT(l.id) as drink_count,
        COALESCE(SUM(f.caffeine_mg), 0) as total_caffeine,
        COALESCE(SUM(l.price_paid), 0) as total_spending
      FROM flavors f
      LEFT JOIN logs l ON l.flavor_id = f.id
        AND DATE(l.timestamp) >= DATE(?)
        AND DATE(l.timestamp) <= DATE(?)
      WHERE f.is_active = 1
      GROUP BY f.id, f.name, f.image_path
      ORDER BY drink_count DESC, f.name COLLATE NOCASE ASC
    '''
          : '''
      SELECT 
        f.id,
        f.name,
        f.image_path,
        COUNT(l.id) as drink_count,
        COALESCE(SUM(f.caffeine_mg), 0) as total_caffeine,
        COALESCE(SUM(l.price_paid), 0) as total_spending
      FROM flavors f
      LEFT JOIN logs l ON l.flavor_id = f.id
      WHERE f.is_active = 1
      GROUP BY f.id, f.name, f.image_path
      ORDER BY drink_count DESC, f.name COLLATE NOCASE ASC
    ''',
      useRange ? [startDate, endDate] : [],
    );

    return result.map((row) => {
      'id': row['id'] as int,
      'name': row['name'] as String,
      'imagePath': row['image_path'] as String?,
      'drinkCount': (row['drink_count'] as num?)?.toInt() ?? 0,
      'totalCaffeine': (row['total_caffeine'] as num?)?.toInt() ?? 0,
      'totalSpending': (row['total_spending'] as num?)?.toDouble() ?? 0.0,
    }).toList();
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

