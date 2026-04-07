import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/car.dart';
import '../pages/car_detail_page.dart';
import '../provider/saved_cars_provider.dart';

class CarCard extends StatelessWidget {
  final Car car;
  const CarCard({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    // ✅ Use Selector instead of Provider.of so the card only rebuilds
    //    when THIS car's saved state changes — not on every notifyListeners()
    //    call from other cars or unrelated providers.
    final isSaved = context.select<SavedCarsProvider, bool>(
      (p) => p.isSaved(car.id),
    );

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => CarDetailPage(car: car))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + overlay ──────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: car.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: car.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),

                // Category badge
                if (car.category.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        car.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // ✅ Heart button
                // Uses context.read to avoid subscribing this Positioned widget
                // to the full SavedCarsProvider — it only needs isSaved (above).
                Positioned(
                  top: 8,
                  right: 8,
                  child: _HeartButton(car: car, isSaved: isSaved),
                ),
              ],
            ),

            // ── Info ────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          car.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${_fmtPrice(car.price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.brand} • ${car.year}',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _chip(Icons.local_gas_station_outlined, car.fuelType),
                      const SizedBox(width: 8),
                      _chip(Icons.settings_outlined, car.transmission),
                      const Spacer(),
                      Text(
                        car.sellerName,
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 180,
    width: double.infinity,
    color: Colors.grey.shade100,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.directions_car_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'No Image',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _chip(IconData icon, String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  static String _fmtPrice(String p) {
    final n = int.tryParse(p.replaceAll(',', '').replaceAll('₹', ''));
    if (n == null) return p;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} K';
    return p;
  }
}

// ── Heart button extracted to its own StatefulWidget ──────────
// ✅ This is isolated so only this tiny widget rebuilds on toggle —
//    not the entire CarCard or the ListView above it.
class _HeartButton extends StatefulWidget {
  final Car car;
  final bool isSaved;
  const _HeartButton({required this.car, required this.isSaved});

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    // ✅ Play bounce animation ONLY — no CircularProgressIndicator involved
    await _ctrl.forward();
    await _ctrl.reverse();

    if (!mounted) return;
    final savedProvider = context.read<SavedCarsProvider>();

    try {
      // toggle() does optimistic UI update then syncs to Supabase
      // It calls notifyListeners() which only rebuilds widgets using
      // context.select<SavedCarsProvider, bool>(...) for THIS car.id
      await savedProvider.toggle(widget.car);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedProvider.isSaved(widget.car.id)
                ? '${widget.car.name} saved!'
                : 'Removed from saved',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: savedProvider.isSaved(widget.car.id)
              ? AppTheme.accentGreen
              : Colors.grey.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save — check your connection'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-read isSaved live in case parent passes stale value
    final isSaved = context.select<SavedCarsProvider, bool>(
      (p) => p.isSaved(widget.car.id),
    );

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSaved ? Colors.red.shade50 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4),
            ],
          ),
          child: Icon(
            isSaved ? Icons.favorite : Icons.favorite_border,
            color: isSaved ? Colors.red : Colors.grey.shade500,
            size: 20,
          ),
        ),
      ),
    );
  }
}
