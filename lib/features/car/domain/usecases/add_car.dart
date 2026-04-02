import 'dart:io';
import '../entities/car.dart';
import '../repositories/car_repository.dart';

class AddCar {
  final CarRepository repository;
  AddCar(this.repository);

  Future<void> call(Car car, {File? imageFile}) {
    return repository.addCar(car, imageFile: imageFile);
  }
}
