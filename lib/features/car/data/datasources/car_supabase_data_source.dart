import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import '../../../../core/config/supabase_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/car_model.dart';

class CarSupabaseDataSource {
  final SupabaseClient _client;

  CarSupabaseDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  // ── Fetch all cars (realtime stream) ──────────────
  Stream<List<CarModel>> getCars() {
    final data = _client
        .from(SupabaseConfig.carsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => CarModel.fromMap(row)).toList());
    // print(data.);
    return data;
  }

  // ── Fetch by category ─────────────────────────────
  // Supabase stream doesn't support .eq filters,
  // so we fetch all and filter client-side for realtime,
  // or use a one-time query:
  Future<List<CarModel>> getCarsByCategory(String category) async {
    try {
      final data = await _client
          .from(SupabaseConfig.carsTable)
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      return (data as List).map((row) => CarModel.fromMap(row)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch by category: $e');
    }
  }

  // ── Fetch by brand ────────────────────────────────
  Future<List<CarModel>> getCarsByBrand(String brand) async {
    try {
      final data = await _client
          .from(SupabaseConfig.carsTable)
          .select()
          .eq('brand', brand)
          .order('created_at', ascending: false);
      return (data as List).map((row) => CarModel.fromMap(row)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch by brand: $e');
    }
  }

  // ── Search cars ───────────────────────────────────
  Future<List<CarModel>> searchCars(String query) async {
    try {
      // Supabase ilike for case-insensitive search
      final data = await _client
          .from(SupabaseConfig.carsTable)
          .select()
          .or(
            'name.ilike.%$query%,brand.ilike.%$query%,category.ilike.%$query%',
          )
          .order('created_at', ascending: false);
      return (data as List).map((row) => CarModel.fromMap(row)).toList();
    } catch (e) {
      throw ServerException(message: 'Search failed: $e');
    }
  }

  // ── Add car ───────────────────────────────────────
  Future<void> addCar(CarModel car) async {
    try {
      await _client.from(SupabaseConfig.carsTable).insert(car.toMap());
    } catch (e) {
      throw ServerException(message: 'Failed to add car: $e');
    }
  }

  // ── Update car ────────────────────────────────────
  Future<void> updateCar(CarModel car) async {
    try {
      await _client
          .from(SupabaseConfig.carsTable)
          .update(car.toMap())
          .eq('id', car.id);
    } catch (e) {
      throw ServerException(message: 'Failed to update car: $e');
    }
  }

  // ── Delete car ────────────────────────────────────
  Future<void> deleteCar(String carId) async {
    try {
      await _client.from(SupabaseConfig.carsTable).delete().eq('id', carId);
    } catch (e) {
      throw ServerException(message: 'Failed to delete car: $e');
    }
  }

  // ── Upload image to Supabase Storage ──────────────
  Future<String> uploadCarImage(String fileName, File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final filePath = 'cars/$fileName';

      await _client.storage
          .from(SupabaseConfig.carImagesBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(SupabaseConfig.carImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw StorageException(message: 'Image upload failed: $e');
    }
  }

  // ── Upload asset image (from assets/images/) ──────
  // Used by seed script — reads from Flutter asset bytes
  Future<String> uploadAssetImage(String fileName, Uint8List bytes) async {
    try {
      final filePath = 'cars/$fileName';

      await _client.storage
          .from(SupabaseConfig.carImagesBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return _client.storage
          .from(SupabaseConfig.carImagesBucket)
          .getPublicUrl(filePath);
    } catch (e) {
      throw StorageException(message: 'Asset image upload failed: $e');
    }
  }
}
