import 'dart:convert';

import 'package:autohub/features/car/domain/entities/car.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedCarsProvider extends ChangeNotifier {
  final List<Car> _savedCars = [];
  static const _key = 'saved_cars_v1';

  List<Car> get savedCars => List.unmodifiable(_savedCars);
  int get count => _savedCars.length;

  SavedCarsProvider() {
    _load();
  }

  bool isSaved(String carId) => _savedCars.any((c) => c.id == carId);

  // Toggle — called from CarCard heart button
  void toggle(Car car) {
    final idx = _savedCars.indexWhere((c) => c.id == car.id);
    if (idx >= 0) {
      _savedCars.removeAt(idx);
    } else {
      _savedCars.add(car);
    }
    notifyListeners();
    _persist();
  }

  void remove(String carId) {
    _savedCars.removeWhere((c) => c.id == carId);
    notifyListeners();
    _persist();
  }

  void clear() {
    _savedCars.clear();
    notifyListeners();
    _persist();
  }

  // ── Persist to SharedPreferences ──────────────────
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedCars
          .map(
            (c) => jsonEncode({
              'id': c.id,
              'name': c.name,
              'brand': c.brand,
              'price': c.price,
              'imageUrl': c.imageUrl,
              'category': c.category,
              'fuelType': c.fuelType,
              'transmission': c.transmission,
              'year': c.year,
              'description': c.description,
              'sellerId': c.sellerId,
              'sellerName': c.sellerName,
            }),
          )
          .toList();
      await prefs.setStringList(_key, list);
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      _savedCars.clear();
      for (final s in list) {
        final m = jsonDecode(s) as Map<String, dynamic>;
        _savedCars.add(
          Car(
            id: m['id'] ?? '',
            name: m['name'] ?? '',
            brand: m['brand'] ?? '',
            price: m['price'] ?? '',
            imageUrl: m['imageUrl'] ?? '',
            category: m['category'] ?? '',
            fuelType: m['fuelType'] ?? '',
            transmission: m['transmission'] ?? '',
            year: m['year'] ?? '',
            description: m['description'] ?? '',
            sellerId: m['sellerId'] ?? '',
            sellerName: m['sellerName'] ?? '',
          ),
        );
      }
      notifyListeners();
    } catch (_) {}
  }
}
