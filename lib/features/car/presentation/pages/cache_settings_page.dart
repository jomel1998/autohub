import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/cache/app_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../provider/car_provider.dart';

class CacheSettingsPage extends StatefulWidget {
  const CacheSettingsPage({super.key});
  @override
  State<CacheSettingsPage> createState() => _CacheSettingsPageState();
}

class _CacheSettingsPageState extends State<CacheSettingsPage> {
  CacheStats? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await AppCache.getStats();
    if (mounted)
      setState(() {
        _stats = stats;
        _loading = false;
      });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all cache?'),
        content: const Text(
          'This removes all cached car data from your device. '
          'The app will fetch fresh data from the server next time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await context.read<CarProvider>().clearCache();
    _showSnack('Cache cleared successfully');
    await _loadStats();
  }

  Future<void> _clearCarLists() async {
    await AppCache.invalidateCarLists();
    _showSnack('Car list cache cleared');
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh stats',
            onPressed: _loadStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Stats card ───────────────────────────
            _card(
              title: 'Cache Statistics',
              icon: Icons.analytics_outlined,
              color: AppTheme.primaryBlue,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _stats == null
                  ? const Text('Could not load stats')
                  : Column(
                      children: [
                        _statRow(
                          'Memory entries',
                          '${_stats!.memoryEntries} items',
                        ),
                        _divider(),
                        _statRow(
                          'Disk entries',
                          '${_stats!.diskEntries} items',
                        ),
                        _divider(),
                        _statRow('Disk size', _stats!.diskSize),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // ── How cache works ──────────────────────
            _card(
              title: 'How it works',
              icon: Icons.info_outline,
              color: Colors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    '⚡',
                    'Memory cache',
                    'Instant reads. Lost when app closes.',
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    '💾',
                    'Disk cache',
                    'Persists across restarts. Used on cold start.',
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    '⏱',
                    'TTL',
                    'Each entry expires automatically after its time-to-live.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── TTL info ─────────────────────────────
            _card(
              title: 'Cache durations',
              icon: Icons.timer_outlined,
              color: Colors.orange,
              child: Column(
                children: [
                  _ttlRow(
                    'All cars (home feed)',
                    '${AppCache.ttlAllCars.inMinutes} min',
                  ),
                  _divider(),
                  _ttlRow(
                    'Category filter',
                    '${AppCache.ttlCategory.inMinutes} min',
                  ),
                  _divider(),
                  _ttlRow(
                    'Search results',
                    '${AppCache.ttlSearch.inMinutes} min',
                  ),
                  _divider(),
                  _ttlRow(
                    'Car detail',
                    '${AppCache.ttlCarDetail.inMinutes} min',
                  ),
                  _divider(),
                  _ttlRow(
                    'Brand filter',
                    '${AppCache.ttlBrandFilter.inMinutes} min',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Actions ──────────────────────────────
            _card(
              title: 'Actions',
              icon: Icons.build_outlined,
              color: Colors.red,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.playlist_remove_outlined,
                      color: Colors.orange,
                    ),
                    title: const Text('Clear car list cache'),
                    subtitle: const Text(
                      'Refreshes home, category, search data',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _clearCarLists,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Clear all cache',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                      'Removes everything from memory and disk',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _clearAll,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── When to clear ─────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'When to clear cache',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• If home page shows outdated cars\n'
                    '• After adding/editing cars on another device\n'
                    '• If you see stale prices or images\n'
                    '• Cache clears automatically on logout',
                    style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppTheme.textDark,
          ),
        ),
      ],
    ),
  );

  Widget _ttlRow(String label, String duration) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            duration,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.orange.shade800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _infoRow(String emoji, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F0F0));

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}
