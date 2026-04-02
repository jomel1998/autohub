// lib/features/car/data/repositories/car_repository_impl.dart
import 'dart:io';
import '../../domain/entities/car.dart';
import '../../domain/repositories/car_repository.dart';
import '../datasources/car_supabase_data_source.dart';
import '../models/car_model.dart';

class CarRepositoryImpl implements CarRepository {
  final CarSupabaseDataSource dataSource;
  CarRepositoryImpl(this.dataSource);

  @override
  Stream<List<Car>> getCars() => dataSource.getCars();

  @override
  Future<List<Car>> getCarsByCategory(String category) =>
      dataSource.getCarsByCategory(category);

  @override
  Future<List<Car>> getCarsByBrand(String brand) =>
      dataSource.getCarsByBrand(brand);

  @override
  Future<List<Car>> searchCars(String query) => dataSource.searchCars(query);

  // ── Add car ────────────────────────────────────────
  // NOTE: imageFile is optional. If provided, upload happens here.
  //       If image was already uploaded in the UI (AddCarPage), pass null.
  @override
  Future<void> addCar(Car car, {File? imageFile}) async {
    String imageUrl = car.imageUrl;

    if (imageFile != null && imageUrl.isEmpty) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${car.name.replaceAll(' ', '_')}.jpg';
      imageUrl = await dataSource.uploadCarImage(fileName, imageFile);
    }

    final model = CarModel.fromEntity(car.copyWith(imageUrl: imageUrl));
    await dataSource.addCar(model);
  }

  @override
  Future<void> updateCar(Car car, {File? imageFile}) async {
    String imageUrl = car.imageUrl;

    if (imageFile != null) {
      final fileName = '${car.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      imageUrl = await dataSource.uploadCarImage(fileName, imageFile);
    }

    final model = CarModel.fromEntity(car.copyWith(imageUrl: imageUrl));
    await dataSource.updateCar(model);
  }

  @override
  Future<void> deleteCar(String carId) => dataSource.deleteCar(carId);
}
