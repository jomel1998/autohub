// lib/features/car/presentation/pages/home_page.dart
import 'package:autohub/features/auth/presnetation/pages/login_page.dart';
import 'package:autohub/features/auth/presnetation/provider/auth_provider.dart';
import 'package:autohub/features/car/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/car.dart';
import '../provider/car_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/car_card.dart';
import '../widgets/brand_chip.dart';
import '../widgets/category_tab.dart';
import 'add_car_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ✅ GlobalKey wires the menu icon button to the Scaffold drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final carProvider = Provider.of<CarProvider>(context);

    return Scaffold(
      key: _scaffoldKey, // ✅ attach key
      drawer: const AppDrawer(), // ✅ functional sidebar
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, auth),
            _buildSearchBar(carProvider),
            Expanded(
              child: carProvider.isSearching
                  ? _buildSearchResults(carProvider)
                  : _buildBrowseView(carProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!auth.isLoggedIn) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
            return;
          }
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddCarPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Sell Car'),
        backgroundColor: AppTheme.accentGreen,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          } else {
            setState(() => _currentIndex = i);
          }
        },
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth) {
    final name =
        auth.currentUser?.userMetadata?['name'] as String? ??
        auth.currentUser?.email?.split('@').first ??
        'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      color: AppTheme.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ✅ Menu icon now opens the drawer
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AutoHUB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (auth.isLoggedIn)
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
              child: CircleAvatar(
                backgroundColor: AppTheme.accentGreen,
                radius: 18,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
              child: const Text(
                'Sign In',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CarProvider carProvider) {
    return Container(
      color: AppTheme.primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (query) => carProvider.searchCars(query),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search cars, brands...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    carProvider.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white24,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseView(CarProvider carProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(Icons.shopping_cart_outlined, 'Buy'),
                _buildQuickAction(Icons.sell_outlined, 'Sell'),
                _buildQuickAction(Icons.compare_arrows, 'Compare'),
              ],
            ),
          ),

          // Category tabs
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Browse by Type',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                CategoryTab(
                  label: 'All',
                  isSelected: carProvider.selectedCategory == 'All',
                  onTap: () => carProvider.loadCarsByCategory('All'),
                ),
                ...AppConstants.carCategories.map(
                  (c) => CategoryTab(
                    label: c,
                    isSelected: carProvider.selectedCategory == c,
                    onTap: () => carProvider.loadCarsByCategory(c),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Most Searched Cars',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),

          // Car list — realtime stream for All, provider state for category
          if (carProvider.selectedCategory == 'All')
            StreamBuilder<List<Car>>(
              stream: carProvider.getCars(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return _buildEmptyState();
                return _buildCarList(snapshot.data!);
              },
            )
          else if (carProvider.isCategoryLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (carProvider.categoryResults.isEmpty)
            _buildEmptyState()
          else
            _buildCarList(carProvider.categoryResults),

          // Popular Brands
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Brands',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: AppConstants.carBrands
                  .map(
                    (brand) => BrandChip(
                      brand: brand,
                      onTap: () => carProvider.setBrand(brand),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCarList(List<Car> cars) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cars.length,
      itemBuilder: (context, i) => CarCard(car: cars[i]),
    );
  }

  Widget _buildSearchResults(CarProvider carProvider) {
    if (carProvider.status == CarStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (carProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No cars found',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: carProvider.searchResults.length,
      itemBuilder: (_, i) => CarCard(car: carProvider.searchResults[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No cars listed yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap menu → Seed Dummy Data to add test cars',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
