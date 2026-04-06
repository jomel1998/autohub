// lib/features/car/presentation/pages/compare_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/car.dart';

class ComparePage extends StatelessWidget {
  final Car carA;
  final Car carB;

  const ComparePage({super.key, required this.carA, required this.carB});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Compare Cars')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Car image headers ────────────────────
            Row(
              children: [
                Expanded(child: _carHeader(carA, context)),
                const SizedBox(width: 12),
                Expanded(child: _carHeader(carB, context)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Comparison table ─────────────────────
            _sectionTitle('Basic Info'),
            _row(
              'Price',
              _fmtPrice(carA.price),
              _fmtPrice(carB.price),
              highlight: _comparePrice(carA.price, carB.price),
            ),
            _row('Year', carA.year, carB.year),
            _row('Brand', carA.brand, carB.brand),
            _row('Category', carA.category, carB.category),

            const SizedBox(height: 16),
            _sectionTitle('Specifications'),
            _row('Fuel Type', carA.fuelType, carB.fuelType),
            _row('Transmission', carA.transmission, carB.transmission),

            const SizedBox(height: 16),
            _sectionTitle('Seller'),
            _row('Seller', carA.sellerName, carB.sellerName),

            const SizedBox(height: 24),

            // ── Verdict ──────────────────────────────
            _buildVerdict(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _carHeader(Car car, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: car.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: car.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  car.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_fmtPrice(car.price)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    ),
  );

  Widget _row(String label, String a, String b, {int highlight = 0}) {
    // highlight: 0=none, 1=A is better (green), 2=B is better (green)
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Label row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textGrey,
              ),
            ),
          ),
          // Value row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(child: _valueCell(a, highlight == 1)),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                Expanded(child: _valueCell(b, highlight == 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueCell(String value, bool isBetter) => Container(
    alignment: Alignment.center,
    child: Text(
      value.isEmpty ? '—' : value,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: isBetter ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
        color: isBetter ? AppTheme.accentGreen : AppTheme.textDark,
      ),
    ),
  );

  Widget _buildVerdict() {
    final priceA =
        int.tryParse(carA.price.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    final priceB =
        int.tryParse(carB.price.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    final cheaper = priceA <= priceB ? carA.name : carB.name;
    final newer = (carA.year.compareTo(carB.year) >= 0) ? carA.name : carB.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verdict',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _verdictLine('Better value', cheaper),
          _verdictLine('Newer model', newer),
          _verdictLine(
            'Electric option',
            carA.fuelType == 'Electric'
                ? carA.name
                : carB.fuelType == 'Electric'
                ? carB.name
                : 'Neither',
          ),
        ],
      ),
    );
  }

  Widget _verdictLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  Widget _imgPlaceholder() => Container(
    height: 120,
    color: Colors.grey.shade100,
    child: Icon(Icons.directions_car_outlined, color: Colors.grey.shade400),
  );

  String _fmtPrice(String p) {
    final n = int.tryParse(p.replaceAll(',', '').replaceAll('₹', ''));
    if (n == null) return p;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)} K';
    return p;
  }

  // 1 = A is cheaper (better), 2 = B is cheaper, 0 = same
  int _comparePrice(String a, String b) {
    final na = int.tryParse(a.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    final nb = int.tryParse(b.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    if (na < nb) return 1;
    if (nb < na) return 2;
    return 0;
  }
}
