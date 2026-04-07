import 'dart:convert';
import 'dart:io';
import '../../../../core/cache/app_cache.dart';
import '../../domain/entities/car.dart';
import 'car_repository_impl.dart';
import '../datasources/car_supabase_data_source.dart';
import '../models/car_model.dart';

class CachedCarRepository {
  final CarRepositoryImpl _repo;

  CachedCarRepository() : _repo = CarRepositoryImpl(CarSupabaseDataSource());

  // ── All cars (realtime stream, no cache needed) ───
  // The Supabase realtime stream already handles live updates.
  // We cache the LAST snapshot for offline/fast initial render.
  Stream<List<Car>> getCars() {
    return _repo.getCars().map((cars) {
      // Silently cache the latest list every time stream emits
      _cacheCarList(AppCache.keyAllCars, cars, AppCache.ttlAllCars);
      return cars;
    });
  }

  // ── Cached snapshot for instant first render ──────
  // Called before opening the stream so the UI shows data immediately
  // while the stream connection is being established.
  Future<List<Car>?> getCachedAllCars() async {
    return _getFromCache(AppCache.keyAllCars);
  }

  // ── Cars by category ──────────────────────────────
  Future<List<Car>> getCarsByCategory(String category) async {
    final key = AppCache.keyCategory(category);

    // 1. Try cache
    final cached = await _getFromCache(key);
    if (cached != null) return cached;

    // 2. Fetch from Supabase
    final cars = await _repo.getCarsByCategory(category);

    // 3. Store in cache
    await _cacheCarList(key, cars, AppCache.ttlCategory);

    return cars;
  }

  // ── Cars by brand ─────────────────────────────────
  Future<List<Car>> getCarsByBrand(String brand) async {
    final key = AppCache.keyBrand(brand);

    final cached = await _getFromCache(key);
    if (cached != null) return cached;

    final cars = await _repo.getCarsByBrand(brand);
    await _cacheCarList(key, cars, AppCache.ttlBrandFilter);
    return cars;
  }

  // ── Search ────────────────────────────────────────
  // Short TTL — search results go stale quickly
  Future<List<Car>> searchCars(String query) async {
    if (query.trim().length < 2) return [];

    final key = AppCache.keySearch(query);

    final cached = await _getFromCache(key);
    if (cached != null) return cached;

    final cars = await _repo.searchCars(query);
    await _cacheCarList(key, cars, AppCache.ttlSearch);
    return cars;
  }

  // ── Car detail ────────────────────────────────────
  Future<Car?> getCarById(String carId) async {
    final key = AppCache.keyCarDetail(carId);

    // Check memory cache first for instant detail page load
    final cached = await _getFromCache(key);
    if (cached != null && cached.isNotEmpty) return cached.first;

    return null; // detail comes from list, not separate fetch
  }

  void cacheCarDetail(Car car) {
    _cacheCarList(AppCache.keyCarDetail(car.id), [car], AppCache.ttlCarDetail);
  }

  // ── Add car ───────────────────────────────────────
  Future<void> addCar(Car car, {File? imageFile}) async {
    await _repo.addCar(car, imageFile: imageFile);
    // Invalidate all list caches so home refreshes with new car
    await AppCache.invalidateCarLists();
  }

  // ── Update car ────────────────────────────────────
  Future<void> updateCar(Car car, {File? imageFile}) async {
    await _repo.updateCar(car, imageFile: imageFile);
    await AppCache.invalidateCarLists();
    await AppCache.invalidate(AppCache.keyCarDetail(car.id));
  }

  // ── Delete car ────────────────────────────────────
  Future<void> deleteCar(String carId) async {
    await _repo.deleteCar(carId);
    await AppCache.invalidateCarLists();
    await AppCache.invalidate(AppCache.keyCarDetail(carId));
  }

  // ── Image upload (no caching, always fresh) ───────
  Future<String?> uploadCarImage(String fileName, File imageFile) {
    return _repo.dataSource.uploadCarImage(fileName, imageFile);
  }

  // ─────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────

  // Serialize Car list → JSON → store in AppCache
  Future<void> _cacheCarList(String key, List<Car> cars, Duration ttl) async {
    try {
      final json = cars
          .map(
            (c) => CarModel.fromEntity(c).toMap()
              ..['id'] = c.id
              ..['created_at'] = c.createdAt?.toIso8601String(),
          )
          .toList();
      await AppCache.set(key, json, ttl: ttl);
    } catch (e) {
      // Cache write failures are non-fatal
    }
  }

  // Read JSON → deserialize → return Car list
  Future<List<Car>?> _getFromCache(String key) async {
    try {
      final raw = await AppCache.get(key);
      if (raw == null) return null;
      final list = (raw as List)
          .map(
            (item) => CarModel.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      return list;
    } catch (e) {
      // Corrupt cache entry — remove it
      await AppCache.invalidate(key);
      return null;
    }
  }
}

// Extension to expose dataSource from repo
extension RepoAccess on CarRepositoryImpl {
  CarSupabaseDataSource get dataSource =>
      // ignore: invalid_use_of_protected_member
      this.dataSource;
}
