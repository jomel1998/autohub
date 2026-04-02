import '../../domain/entities/car.dart';

class CarModel extends Car {
  const CarModel({
    required super.id,
    required super.name,
    required super.brand,
    required super.price,
    required super.imageUrl,
    super.category,
    super.fuelType,
    super.transmission,
    super.year,
    super.description,
    super.sellerId,
    super.sellerName,
    super.isFavorite,
    super.createdAt,
  });

  // ── From Supabase row (snake_case) ─────────────────
  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      price: map['price'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      category: map['category'] as String? ?? '',
      fuelType: map['fuel_type'] as String? ?? '',
      transmission: map['transmission'] as String? ?? '',
      year: map['year'] as String? ?? '',
      description: map['description'] as String? ?? '',
      sellerId: map['seller_id'] as String? ?? '',
      sellerName: map['seller_name'] as String? ?? '',
      isFavorite: map['is_favorite'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  // ── From domain entity ─────────────────────────────
  factory CarModel.fromEntity(Car car) {
    return CarModel(
      id: car.id,
      name: car.name,
      brand: car.brand,
      price: car.price,
      imageUrl: car.imageUrl,
      category: car.category,
      fuelType: car.fuelType,
      transmission: car.transmission,
      year: car.year,
      description: car.description,
      sellerId: car.sellerId,
      sellerName: car.sellerName,
      isFavorite: car.isFavorite,
      createdAt: car.createdAt,
    );
  }

  // ── To Supabase row (snake_case) ──────────────────
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'fuel_type': fuelType,
      'transmission': transmission,
      'year': year,
      'description': description,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'is_favorite': isFavorite,
    };
  }
}
