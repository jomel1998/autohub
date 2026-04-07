import 'package:autohub/features/auth/presnetation/pages/login_page.dart';
import 'package:autohub/features/auth/presnetation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/car.dart';
import '../provider/car_provider.dart';
import '../provider/saved_cars_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/car_card.dart';
import '../widgets/brand_chip.dart';
import '../widgets/category_tab.dart';
import 'add_car_page.dart';
import 'chat_page.dart';
import 'compare_page.dart';
import 'profile_page.dart';
import 'saved_cars_page.dart';
import 'test_drive_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  int _currentIndex = 0;

  // ✅ Cached car list — persists across rebuilds caused by heart taps
  // This prevents the StreamBuilder from showing a spinner on notifyListeners()
  List<Car>? _cachedAllCars;

  // ✅ Key used to force the StreamBuilder to re-subscribe on refresh
  Key _streamKey = UniqueKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Pull-to-refresh ────────────────────────────────
  // Only this triggers the RefreshIndicator spinner
  Future<void> _onRefresh(CarProvider carProvider) async {
    if (carProvider.selectedCategory == 'All') {
      // Clear the cache and reset the stream key so StreamBuilder re-subscribes
      setState(() {
        _cachedAllCars = null;
        _streamKey = UniqueKey();
      });
      // Give the stream time to emit fresh data
      await Future.delayed(const Duration(milliseconds: 800));
    } else {
      await carProvider.loadCarsByCategory(carProvider.selectedCategory);
    }
  }

  void _onNavTap(int i) {
    if (i == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestDrivePage()),
      );
    } else if (i == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedCarsPage()),
      );
    } else if (i == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else {
      setState(() => _currentIndex = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final carProvider = Provider.of<CarProvider>(context);
    final savedProv = Provider.of<SavedCarsProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, auth),
            _buildSearchBar(carProvider),
            Expanded(
              child: carProvider.isSearching
                  ? _buildSearchResults(carProvider)
                  : _buildBrowseView(carProvider, savedProv),
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
        onTap: _onNavTap,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Test Drive',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: savedProv.count > 0,
              label: Text('${savedProv.count}'),
              child: const Icon(Icons.favorite_outline),
            ),
            label: 'Saved',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────
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

  // ── Search bar ─────────────────────────────────────
  Widget _buildSearchBar(CarProvider carProvider) {
    return Container(
      color: AppTheme.primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        autofocus: false,
        controller: _searchController,
        onChanged: (q) => carProvider.searchCars(q),
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

  // ── Browse view ────────────────────────────────────
  Widget _buildBrowseView(
    CarProvider carProvider,
    SavedCarsProvider savedProv,
  ) {
    return RefreshIndicator(
      //  Only pull-to-refresh triggers the spinner, not heart taps
      onRefresh: () => _onRefresh(carProvider),
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickAction(Icons.diamond_outlined, 'Luxury', () {
                    carProvider.loadCarsByCategory('Luxury');
                  }),
                  _quickAction(Icons.favorite_outline, 'Saved', () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavedCarsPage()),
                    );
                  }),
                  _quickAction(Icons.compare_arrows, 'Compare', () {
                    final saved = savedProv.savedCars;
                    if (saved.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Save at least 2 cars first to compare',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ComparePage(carA: saved[0], carB: saved[1]),
                      ),
                    );
                  }),
                  _quickAction(Icons.chat_bubble_outline, 'Chat', () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatListPage()),
                    );
                  }),
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

            // ✅ Fixed StreamBuilder — uses _cachedAllCars to prevent
            //    spinner from showing when heart taps trigger notifyListeners()
            if (carProvider.selectedCategory == 'All')
              _buildAllCarsStream(carProvider)
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

            // Popular brands
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
      ),
    );
  }

  // ── Stream builder with cache ──────────────────────
  // ✅ _streamKey forces a fresh StreamBuilder subscription on pull-to-refresh.
  //    Once data is received, it's stored in _cachedAllCars.
  //    On subsequent rebuilds (e.g. heart tap → notifyListeners),
  //    if snapshot has no NEW data yet, we show the cached list instead
  //    of a spinner. The spinner only shows on very first load (null cache).
  Widget _buildAllCarsStream(CarProvider carProvider) {
    return StreamBuilder<List<Car>>(
      key: _streamKey, // ✅ New key on refresh forces re-subscription
      stream: carProvider.getCars(),
      builder: (context, snapshot) {
        // New data arrived — update cache
        if (snapshot.hasData) {
          _cachedAllCars = snapshot.data;
        }

        // Show list from cache if available (covers heart-tap rebuilds)
        if (_cachedAllCars != null) {
          if (_cachedAllCars!.isEmpty) return _buildEmptyState();
          return _buildCarList(_cachedAllCars!);
        }

        // True first load — no data yet at all
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load cars',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pull down to retry',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildCarList(List<Car> cars) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: cars.length,
    itemBuilder: (_, i) => CarCard(car: cars[i]),
  );

  // ── Search results ─────────────────────────────────
  Widget _buildSearchResults(CarProvider carProvider) {
    // ✅ No spinner for search either — just show results or empty
    if (carProvider.status == CarStatus.loading &&
        carProvider.searchResults.isEmpty) {
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

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.all(48),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
          'Tap Sell Car to add the first listing',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textGrey),
        ),
      ],
    ),
  );

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}
