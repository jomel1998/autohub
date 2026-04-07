// lib/features/car/presentation/provider/car_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/cache/app_cache.dart';
import '../../data/repositories/cached_car_repository.dart';
import '../../domain/entities/car.dart';

enum CarStatus { initial, loading, success, error }

class CarProvider extends ChangeNotifier {
  // ✅ Uses CachedCarRepository instead of raw repo
  final CachedCarRepository _repo = CachedCarRepository();

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

  // ── Realtime stream (home feed) ───────────────────
  Stream<List<Car>> getCars() => _repo.getCars();

  // ── Instant cached snapshot ───────────────────────
  // Returns the last-cached list immediately — no network wait.
  // Used by home_page to render something instantly while stream connects.
  Future<List<Car>?> getCachedSnapshot() => _repo.getCachedAllCars();

  // ── Category filter ───────────────────────────────
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
      // Served from cache if fresh, Supabase if stale
      _categoryResults = await _repo.getCarsByCategory(category);
    } catch (e) {
      _categoryResults = [];
      _errorMessage = e.toString();
    } finally {
      _isCategoryLoading = false;
      notifyListeners();
    }
  }

  // ── Search ────────────────────────────────────────
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
      _searchResults = await _repo.searchCars(query);
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

  // ── Add car ───────────────────────────────────────
  // After add → cache is invalidated → stream emits fresh list
  Future<bool> addCar(Car car, {File? imageFile}) async {
    _setStatus(CarStatus.loading);
    try {
      await _repo.addCar(car, imageFile: imageFile);
      _setStatus(CarStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Update car ────────────────────────────────────
  Future<bool> updateCar(Car car, {File? imageFile}) async {
    _setStatus(CarStatus.loading);
    try {
      await _repo.updateCar(car, imageFile: imageFile);
      _setStatus(CarStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Delete car ────────────────────────────────────
  Future<bool> deleteCar(String carId) async {
    _setStatus(CarStatus.loading);
    try {
      await _repo.deleteCar(carId);
      _setStatus(CarStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Cache detail for instant detail page open ─────
  void cacheCarDetail(Car car) => _repo.cacheCarDetail(car);

  // ── Manual cache clear (logout / settings) ────────
  Future<void> clearCache() async {
    await AppCache.clear();
    _categoryResults = [];
    _searchResults = [];
    notifyListeners();
  }

  // ── Cache stats for debug page ────────────────────
  Future<CacheStats> getCacheStats() => AppCache.getStats();

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
