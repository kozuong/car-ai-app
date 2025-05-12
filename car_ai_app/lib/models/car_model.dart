class CarModel {
  final String imagePath;
  final String carName;
  final String year;
  final String price;
  final String power;
  final String acceleration;
  final String topSpeed;
  final String engine;
  final String interior;
  final String features;
  final String description;
  final DateTime timestamp;

  CarModel({
    required this.imagePath,
    required this.carName,
    required this.year,
    required this.price,
    required this.power,
    required this.acceleration,
    required this.topSpeed,
    required this.engine,
    required this.interior,
    required this.features,
    required this.description,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'carName': carName,
        'year': year,
        'price': price,
        'power': power,
        'acceleration': acceleration,
        'topSpeed': topSpeed,
        'engine': engine,
        'interior': interior,
        'features': features,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
        imagePath: json['imagePath'] as String? ?? '',
        carName: json['carName'] as String? ?? '',
        year: json['year'] as String? ?? '',
        price: json['price'] as String? ?? '',
        power: json['power'] as String? ?? '',
        acceleration: json['acceleration'] as String? ?? '',
        topSpeed: json['topSpeed'] as String? ?? '',
        engine: json['engine'] as String? ?? '',
        interior: json['interior'] as String? ?? '',
        features: json['features'] as String? ?? '',
        description: json['description'] as String? ?? '',
        timestamp: json['timestamp'] != null 
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );

  @override
  String toString() => 'CarModel(carName: $carName)';

  CarModel copyWith({
    String? imagePath,
    String? carName,
    String? year,
    String? price,
    String? power,
    String? acceleration,
    String? topSpeed,
    String? engine,
    String? interior,
    String? features,
    String? description,
    DateTime? timestamp,
  }) {
    return CarModel(
      imagePath: imagePath ?? this.imagePath,
      carName: carName ?? this.carName,
      year: year ?? this.year,
      price: price ?? this.price,
      power: power ?? this.power,
      acceleration: acceleration ?? this.acceleration,
      topSpeed: topSpeed ?? this.topSpeed,
      engine: engine ?? this.engine,
      interior: interior ?? this.interior,
      features: features ?? this.features,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 