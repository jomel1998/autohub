import 'dart:io';
import '../entities/car.dart';

abstract class CarRepository {
  Stream<List<Car>> getCars();
  Future<List<Car>> getCarsByCategory(String category);
  Future<List<Car>> getCarsByBrand(String brand);
  Future<List<Car>> searchCars(String query);
  Future<void> addCar(Car car, {File? imageFile});
  Future<void> updateCar(Car car, {File? imageFile});
  Future<void> deleteCar(String carId);
}
