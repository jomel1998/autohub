import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presnetation/pages/login_page.dart';
import '../../../auth/presnetation/provider/auth_provider.dart';
import '../../domain/entities/car.dart';
import '../provider/car_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Car> _myListings = [];
  bool _loadingListings = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyListings() async {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (uid.isEmpty) {
      setState(() => _loadingListings = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('cars')
          .select()
          .eq('seller_id', uid)
          .order('created_at', ascending: false);
      setState(() {
        _myListings = (data as List).map((row) => _carFromRow(row)).toList();
        _loadingListings = false;
      });
    } catch (_) {
      setState(() => _loadingListings = false);
    }
  }

  Car _carFromRow(Map<String, dynamic> row) => Car(
    id: row['id']?.toString() ?? '',
    name: row['name'] ?? '',
    brand: row['brand'] ?? '',
    price: row['price'] ?? '',
    imageUrl: row['image_url'] ?? '',
    category: row['category'] ?? '',
    fuelType: row['fuel_type'] ?? '',
    transmission: row['transmission'] ?? '',
    year: row['year'] ?? '',
    description: row['description'] ?? '',
    sellerId: row['seller_id'] ?? '',
    sellerName: row['seller_name'] ?? '',
    createdAt: row['created_at'] != null
        ? DateTime.parse(row['created_at'])
        : null,
  );

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isLoggedIn) {
      return _buildNotLoggedIn(context);
    }

    final name =
        auth.currentUser?.userMetadata?['name'] as String? ??
        auth.currentUser?.email?.split('@').first ??
        'User';
    final email = auth.currentUser?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final memberSince = auth.currentUser?.createdAt != null
        ? _formatDate(DateTime.parse(auth.currentUser!.createdAt))
        : 'Recently joined';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Blue header ──────────────────────────
                Container(
                  color: AppTheme.primaryBlue,
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'My Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () => _showEditProfile(context, name),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () => _showSettings(context, auth),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar + name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        email,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Member since $memberSince',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Stats row ───────────────────────────
                      Container(
                        margin: const EdgeInsets.only(bottom: 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statItem(
                              _myListings.length.toString(),
                              'Listings',
                            ),
                            _vDivider(),
                            _statItem('0', 'Sold'),
                            _vDivider(),
                            _statItem('4.8', 'Rating'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tab bar ──────────────────────────────
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryBlue,
                    unselectedLabelColor: AppTheme.textGrey,
                    indicatorColor: AppTheme.primaryBlue,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'My Listings'),
                      Tab(text: 'About'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: My listings ───────────────────
            _buildListingsTab(),
            // ── Tab 2: About ─────────────────────────
            _buildAboutTab(name, email, memberSince),
          ],
        ),
      ),
    );
  }

  // ── Listings tab ──────────────────────────────────────
  Widget _buildListingsTab() {
    if (_loadingListings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myListings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 72,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'No listings yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the Sell Car button to list your first car',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMyListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myListings.length,
        itemBuilder: (_, i) => _MyListingCard(
          car: _myListings[i],
          onDelete: () async {
            final provider = Provider.of<CarProvider>(context, listen: false);
            final ok = await provider.deleteCar(_myListings[i].id);
            if (ok) _loadMyListings();
          },
        ),
      ),
    );
  }

  // ── About tab ─────────────────────────────────────────
  Widget _buildAboutTab(String name, String email, String since) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard([
          _infoRow(Icons.person_outline, 'Name', name),
          _divider(),
          _infoRow(Icons.email_outlined, 'Email', email),
          _divider(),
          _infoRow(Icons.calendar_today_outlined, 'Member Since', since),
          _divider(),
          _infoRow(Icons.verified_outlined, 'Account', 'Verified'),
        ]),
        const SizedBox(height: 16),
        _infoCard([
          _infoRow(Icons.star_outline, 'Rating', '4.8 / 5.0'),
          _divider(),
          _infoRow(
            Icons.sell_outlined,
            'Total Listings',
            '${_myListings.length}',
          ),
          _divider(),
          _infoRow(Icons.check_circle_outline, 'Sold', '0'),
        ]),
        const SizedBox(height: 16),
        // OLX-style trust badges
        const Text(
          'Trust & Safety',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _badge(Icons.email_outlined, 'Email\nVerified', Colors.green),
            const SizedBox(width: 10),
            _badge(Icons.phone_outlined, 'Phone\nPending', Colors.orange),
            const SizedBox(width: 10),
            _badge(Icons.badge_outlined, 'ID\nPending', Colors.orange),
          ],
        ),
      ],
    );
  }

  // ── Not logged in ─────────────────────────────────────
  Widget _buildNotLoggedIn(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'Sign in to view your profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _statItem(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );

  Widget _vDivider() => Container(width: 1, height: 32, color: Colors.white24);

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textDark,
          ),
        ),
      ],
    ),
  );

  Widget _divider() => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: Colors.grey.shade100,
  );

  Widget _badge(IconData icon, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _showEditProfile(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(data: {'name': ctrl.text.trim()}),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (r) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── My listing card ───────────────────────────────────────
class _MyListingCard extends StatelessWidget {
  final Car car;
  final VoidCallback onDelete;

  const _MyListingCard({required this.car, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: car.imageUrl.isNotEmpty
                ? Image.network(
                    car.imageUrl,
                    width: 110,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
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
                      fontSize: 15,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
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
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
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
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return p;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('Remove "${car.name}" from your listings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
