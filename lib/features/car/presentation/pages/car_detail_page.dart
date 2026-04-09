import '../pages/chat_page.dart';
import '../pages/test_drive_page.dart';
// lib/features/car/presentation/pages/car_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ replaces firebase_auth
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/car.dart';
import '../provider/car_provider.dart';

class CarDetailPage extends StatefulWidget {
  final Car car;
  const CarDetailPage({super.key, required this.car});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _isFav = widget.car.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    // ✅ Supabase: currentUser.id  (was FirebaseAuth.instance.currentUser?.uid)
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isOwner = currentUserId.isNotEmpty && currentUserId == car.sellerId;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image App Bar ─────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            actions: [
              // Favorite button
              GestureDetector(
                onTap: () => setState(() => _isFav = !_isFav),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _isFav ? Icons.favorite : Icons.favorite_border,
                      color: _isFav ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              ),
              // Share button
              GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.share_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: car.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: car.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),

          // ── Content ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              car.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${car.brand} • ${car.year}',
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_formatPrice(car.price)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              car.category,
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Specifications
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSpecsGrid(car),

                  const SizedBox(height: 20),

                  // Description
                  if (car.description.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      car.description,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Seller card
                  const Text(
                    'Seller',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          child: Text(
                            car.sellerName.isNotEmpty
                                ? car.sellerName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car.sellerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const Text(
                                'Private Seller',
                                style: TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (car.createdAt != null)
                          Text(
                            _formatDate(car.createdAt!),
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Owner-only delete button
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Delete Listing',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom CTA (only shown to non-owners)
      bottomSheet: !isOwner
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  // Chat button
                  OutlinedButton(
                    onPressed: () {
                      final myId =
                          Supabase.instance.client.auth.currentUser?.id;
                      final myName =
                          Supabase
                                  .instance
                                  .client
                                  .auth
                                  .currentUser
                                  ?.userMetadata?['name']
                              as String? ??
                          Supabase.instance.client.auth.currentUser?.email
                              ?.split('@')
                              .first ??
                          'Buyer';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(
                            otherName: car.sellerName,
                            car: car,
                            sellerId: car.sellerId,
                            sellerName: car.sellerName,
                            buyerId: myId ?? '',
                            buyerName: myName,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  const SizedBox(width: 8),
                  // Test Drive button
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TestDrivePage(car: car),
                      ),
                    ),
                    icon: const Icon(Icons.event_available, size: 18),
                    label: const Text('Test Drive'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Contact seller
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Call Seller'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // ── Specs grid ──────────────────────────────────────
  Widget _buildSpecsGrid(Car car) {
    final specs = [
      _SpecItem(Icons.local_gas_station_outlined, 'Fuel', car.fuelType),
      _SpecItem(Icons.settings_outlined, 'Transmission', car.transmission),
      _SpecItem(Icons.category_outlined, 'Type', car.category),
      _SpecItem(Icons.calendar_today_outlined, 'Year', car.year),
    ].where((s) => s.value.isNotEmpty).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: specs.length,
      itemBuilder: (_, i) {
        final spec = specs[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(spec.icon, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spec.label,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      spec.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.directions_car_outlined,
          size: 80,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  String _formatPrice(String price) {
    final num = int.tryParse(price.replaceAll(',', '').replaceAll('₹', ''));
    if (num == null) return price;
    if (num >= 100000) return '${(num / 100000).toStringAsFixed(2)} Lacs';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)} K';
    return price;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to remove this car listing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<CarProvider>(context, listen: false);
              final success = await provider.deleteCar(widget.car.id);
              if (mounted) {
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing removed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SpecItem {
  final IconData icon;
  final String label;
  final String value;
  const _SpecItem(this.icon, this.label, this.value);
}
