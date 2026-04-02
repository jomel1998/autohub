class Car {
  final String id;
  final String name;
  final String brand;
  final String price;
  final String imageUrl;
  final String category;
  final String fuelType;
  final String transmission;
  final String year;
  final String description;
  final String sellerId;
  final String sellerName;
  final bool isFavorite;
  final DateTime? createdAt;

  const Car({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    this.category = '',
    this.fuelType = '',
    this.transmission = '',
    this.year = '',
    this.description = '',
    this.sellerId = '',
    this.sellerName = '',
    this.isFavorite = false,
    this.createdAt,
  });

  Car copyWith({
    String? id,
    String? name,
    String? brand,
    String? price,
    String? imageUrl,
    String? category,
    String? fuelType,
    String? transmission,
    String? year,
    String? description,
    String? sellerId,
    String? sellerName,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Car(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      year: year ?? this.year,
      description: description ?? this.description,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
