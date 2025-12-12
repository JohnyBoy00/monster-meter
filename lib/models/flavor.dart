/// Model class representing a Monster Energy flavor in the database
class Flavor {
  final int? id;
  final String name;
  final int ml;
  final int caffeineMg;
  final bool isActive;
  final String? imagePath;

  /// Constructor for Flavor model
  Flavor({
    this.id,
    required this.name,
    required this.ml,
    required this.caffeineMg,
    this.isActive = true,
    this.imagePath,
  });

  /// Converts Flavor object to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ml': ml,
      'caffeine_mg': caffeineMg,
      'is_active': isActive ? 1 : 0,
      'image_path': imagePath,
    };
  }

  /// Creates a Flavor object from a database Map
  factory Flavor.fromMap(Map<String, dynamic> map) {
    return Flavor(
      id: map['id'] as int?,
      name: map['name'] as String,
      ml: map['ml'] as int,
      caffeineMg: map['caffeine_mg'] as int,
      isActive: map['is_active'] == 1,
      imagePath: map['image_path'] as String?,
    );
  }

  /// Creates a copy of the Flavor with updated fields
  Flavor copyWith({
    int? id,
    String? name,
    int? ml,
    int? caffeineMg,
    bool? isActive,
    String? imagePath,
  }) {
    return Flavor(
      id: id ?? this.id,
      name: name ?? this.name,
      ml: ml ?? this.ml,
      caffeineMg: caffeineMg ?? this.caffeineMg,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

