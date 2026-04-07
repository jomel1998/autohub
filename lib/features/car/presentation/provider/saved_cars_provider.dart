// lib/features/car/presentation/provider/saved_cars_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/car.dart';

class SavedCarsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final List<Car> _savedCars = [];

  List<Car> get savedCars => List.unmodifiable(_savedCars);
  int get count => _savedCars.length;
  String? get _uid => _supabase.auth.currentUser?.id;

  // ── Load from Supabase ────────────────────────────
  Future<void> loadSavedCars() async {
    if (_uid == null) return;
    try {
      final rows = await _supabase
          .from('saved_cars')
          .select()
          .eq('user_id', _uid!)
          .order('created_at', ascending: false);
      _savedCars.clear();
      for (final r in rows as List) {
        _savedCars.add(
          Car(
            id: r['car_id'] ?? '',
            name: r['name'] ?? '',
            brand: r['brand'] ?? '',
            price: r['price'] ?? '',
            imageUrl: r['image_url'] ?? '',
            category: r['category'] ?? '',
            fuelType: r['fuel_type'] ?? '',
            transmission: r['transmission'] ?? '',
            year: r['year'] ?? '',
            description: r['description'] ?? '',
            sellerId: r['seller_id'] ?? '',
            sellerName: r['seller_name'] ?? '',
          ),
        );
      }
    } catch (e) {
      debugPrint('loadSavedCars: $e');
    } finally {
      notifyListeners();
    }
  }

  bool isSaved(String carId) => _savedCars.any((c) => c.id == carId);

  // ── Toggle (optimistic) ───────────────────────────
  // ✅ Optimistic update: UI changes instantly, Supabase syncs in background.
  //    notifyListeners() is called ONCE before the async call so the heart
  //    flips immediately without waiting for the network.
  Future<void> toggle(Car car) async {
    if (_uid == null) return;
    final wasSaved = isSaved(car.id);

    // ── 1. Update local state instantly ──────────────
    if (wasSaved) {
      _savedCars.removeWhere((c) => c.id == car.id);
    } else {
      _savedCars.insert(0, car);
    }
    notifyListeners(); // ← triggers heart icon flip, badge count update

    // ── 2. Sync to Supabase in background ────────────
    try {
      if (wasSaved) {
        await _supabase
            .from('saved_cars')
            .delete()
            .eq('user_id', _uid!)
            .eq('car_id', car.id);
      } else {
        await _supabase.from('saved_cars').upsert({
          'user_id': _uid,
          'car_id': car.id,
          'name': car.name,
          'brand': car.brand,
          'price': car.price,
          'image_url': car.imageUrl,
          'category': car.category,
          'fuel_type': car.fuelType,
          'transmission': car.transmission,
          'year': car.year,
          'description': car.description,
          'seller_id': car.sellerId,
          'seller_name': car.sellerName,
        }, onConflict: 'user_id,car_id');
      }
    } catch (e) {
      // ── 3. Rollback on failure ────────────────────
      if (wasSaved) {
        _savedCars.insert(0, car);
      } else {
        _savedCars.removeWhere((c) => c.id == car.id);
      }
      notifyListeners();
      debugPrint('toggle error: $e');
      rethrow; // let _HeartButton show the error snackbar
    }
  }

  Future<void> remove(String carId) async {
    if (_uid == null) return;
    final car = _savedCars.firstWhere(
      (c) => c.id == carId,
      orElse: () =>
          const Car(id: '', name: '', brand: '', price: '', imageUrl: ''),
    );
    if (car.id.isEmpty) return;

    _savedCars.removeWhere((c) => c.id == carId);
    notifyListeners();

    try {
      await _supabase
          .from('saved_cars')
          .delete()
          .eq('user_id', _uid!)
          .eq('car_id', carId);
    } catch (e) {
      _savedCars.insert(0, car);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clear() async {
    if (_uid == null) return;
    final backup = List<Car>.from(_savedCars);
    _savedCars.clear();
    notifyListeners();
    try {
      await _supabase.from('saved_cars').delete().eq('user_id', _uid!);
    } catch (e) {
      _savedCars.addAll(backup);
      notifyListeners();
      rethrow;
    }
  }

  void clearLocal() {
    _savedCars.clear();
    notifyListeners();
  }

  Future<void> reload() => loadSavedCars();
}
