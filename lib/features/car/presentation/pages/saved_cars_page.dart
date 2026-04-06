import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/car.dart';
import '../provider/saved_cars_provider.dart';
import 'car_detail_page.dart';
import 'compare_page.dart';

class SavedCarsPage extends StatefulWidget {
  const SavedCarsPage({super.key});
  @override
  State<SavedCarsPage> createState() => _SavedCarsPageState();
}

class _SavedCarsPageState extends State<SavedCarsPage> {
  final Set<String> _selectedForCompare = {};

  @override
  Widget build(BuildContext context) {
    final saved = Provider.of<SavedCarsProvider>(context);
    final cars = saved.savedCars;

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Cars (${cars.length})'),
        actions: [
          if (cars.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, saved),
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: cars.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                // Compare bar
                if (_selectedForCompare.isNotEmpty)
                  _buildCompareBar(cars, context),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cars.length,
                    itemBuilder: (_, i) => _SavedCarTile(
                      car: cars[i],
                      isSelectedForCompare: _selectedForCompare.contains(
                        cars[i].id,
                      ),
                      onCompareToggle: () => setState(() {
                        if (_selectedForCompare.contains(cars[i].id)) {
                          _selectedForCompare.remove(cars[i].id);
                        } else if (_selectedForCompare.length < 2) {
                          _selectedForCompare.add(cars[i].id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You can only compare 2 cars'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }),
                      onRemove: () => saved.remove(cars[i].id),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompareBar(List<Car> cars, BuildContext context) {
    final selected = cars
        .where((c) => _selectedForCompare.contains(c.id))
        .toList();

    return Container(
      color: AppTheme.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selected.length == 1
                  ? 'Select 1 more to compare'
                  : '${selected[0].name} vs ${selected[1].name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selected.length == 2)
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ComparePage(carA: selected[0], carB: selected[1]),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Compare Now'),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _selectedForCompare.clear()),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_outline, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text(
          'No saved cars yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap the heart icon on any car to save it',
          style: TextStyle(color: AppTheme.textGrey),
        ),
      ],
    ),
  );

  void _confirmClearAll(BuildContext context, SavedCarsProvider saved) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all saved cars?'),
        content: const Text('This will remove all your saved cars.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              saved.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _SavedCarTile extends StatelessWidget {
  final Car car;
  final bool isSelectedForCompare;
  final VoidCallback onCompareToggle;
  final VoidCallback onRemove;

  const _SavedCarTile({
    required this.car,
    required this.isSelectedForCompare,
    required this.onCompareToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => CarDetailPage(car: car))),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelectedForCompare
                ? AppTheme.primaryBlue
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: car.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: car.imageUrl,
                      width: 110,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _chip(car.year),
                        const SizedBox(width: 6),
                        _chip(car.fuelType),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Compare toggle
                IconButton(
                  icon: Icon(
                    isSelectedForCompare
                        ? Icons.compare_arrows
                        : Icons.compare_arrows_outlined,
                    color: isSelectedForCompare
                        ? AppTheme.primaryBlue
                        : Colors.grey,
                    size: 22,
                  ),
                  tooltip: 'Compare',
                  onPressed: onCompareToggle,
                ),
                // Remove saved
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 110,
    height: 90,
    color: Colors.grey.shade100,
    child: Icon(Icons.directions_car_outlined, color: Colors.grey.shade400),
  );

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.bgLight,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
    ),
  );

  String _fmtPrice(String p) {
    final n = int.tryParse(p.replaceAll(',', '').replaceAll('₹', ''));
    if (n == null) return p;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)} L';
    return p;
  }
}
