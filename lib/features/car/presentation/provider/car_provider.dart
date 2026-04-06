// lib/features/car/presentation/provider/car_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/datasources/car_supabase_data_source.dart';
import '../../data/repositories/car_repository_impl.dart';
import '../../domain/entities/car.dart';

enum CarStatus { initial, loading, success, error }

class CarProvider extends ChangeNotifier {
  late final CarRepositoryImpl _repository;

  CarStatus _status = CarStatus.initial;
  String _errorMessage = '';
  List<Car> _searchResults = [];
  List<Car> _categoryResults = [];
  bool _isSearching = false;
  bool _isCategoryLoading = false;
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';

  CarStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<Car> get searchResults => _searchResults;
  List<Car> get categoryResults => _categoryResults;
  bool get isSearching => _isSearching;
  bool get isCategoryLoading => _isCategoryLoading;
  String get selectedCategory => _selectedCategory;
  String get selectedBrand => _selectedBrand;

  CarProvider() {
    _repository = CarRepositoryImpl(CarSupabaseDataSource());
  }

  Stream<List<Car>> getCars() => _repository.getCars();
  Future<void> refreshCars() async {
    // Re-fetch your data OR recreate stream
    notifyListeners();
  }

  Future<void> loadCarsByCategory(String category) async {
    if (category == 'All') {
      _categoryResults = [];
      _selectedCategory = 'All';
      notifyListeners();
      return;
    }
    _selectedCategory = category;
    _isCategoryLoading = true;
    notifyListeners();
    try {
      _categoryResults = await _repository.getCarsByCategory(category);
    } catch (e) {
      _categoryResults = [];
      _errorMessage = e.toString();
    } finally {
      _isCategoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchCars(String query) async {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    _setStatus(CarStatus.loading);
    try {
      _searchResults = await _repository.searchCars(query);
      _setStatus(CarStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  Future<bool> addCar(Car car, {File? imageFile}) async {
    _setStatus(CarStatus.loading);
    try {
      await _repository.addCar(car, imageFile: imageFile);
      _setStatus(CarStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateCar(Car car, {File? imageFile}) async {
    _setStatus(CarStatus.loading);
    try {
      await _repository.updateCar(car, imageFile: imageFile);
      _setStatus(CarStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteCar(String carId) async {
    _setStatus(CarStatus.loading);
    try {
      await _repository.deleteCar(carId);
      _setStatus(CarStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  void setBrand(String b) {
    _selectedBrand = b;
    notifyListeners();
  }

  void _setStatus(CarStatus s) {
    _status = s;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _status = CarStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _status = CarStatus.initial;
    notifyListeners();
  }
}
