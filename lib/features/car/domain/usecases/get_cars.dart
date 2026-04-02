import '../entities/car.dart';
import '../repositories/car_repository.dart';

class GetCars {
  final CarRepository repository;
  GetCars(this.repository);

  Stream<List<Car>> call() => repository.getCars();
}

// features/car/domain/usecases/delete_car.dart
class DeleteCar {
  final CarRepository repository;
  DeleteCar(this.repository);

  Future<void> call(String carId) => repository.deleteCar(carId);
}

// features/car/domain/usecases/search_cars.dart
class SearchCars {
  final CarRepository repository;
  SearchCars(this.repository);

  Future<List<Car>> call(String query) => repository.searchCars(query);
}
