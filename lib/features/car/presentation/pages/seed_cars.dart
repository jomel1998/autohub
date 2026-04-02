import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/data/dummy_cars.dart';
import '../../../../core/theme/app_theme.dart';

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});
  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  final _client = Supabase.instance.client;
  final List<String> _logs = [];
  bool _isRunning = false;
  bool _isDone = false;
  int _done = 0;

  void _log(String msg) => setState(() => _logs.add(msg));

  Future<void> _clearExisting() async {
    try {
      await _client
          .from(SupabaseConfig.carsTable)
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000');
      _log('Cleared existing cars.');
    } catch (e) {
      _log('Warning clearing: $e');
    }
  }

  Future<void> _seed() async {
    setState(() {
      _isRunning = true;
      _isDone = false;
      _logs.clear();
      _done = 0;
    });
    _log('Starting — ${DummyCars.all.length} cars...');
    await _clearExisting();

    for (final car in DummyCars.all) {
      try {
        await _client.from(SupabaseConfig.carsTable).insert({
          'name': car.name,
          'brand': car.brand,
          'price': car.price,
          'year': car.year,
          'category': car.category,
          'fuel_type': car.fuelType,
          'transmission': car.transmission,
          'description': car.description,
          'seller_name': car.sellerName,
          'seller_id': '',
          'image_url': car.imageUrl,
          'is_favorite': false,
        });
        _log('  OK  ${car.name}');
        setState(() => _done++);
      } catch (e) {
        _log('  ERR ${car.name}: $e');
      }
    }

    _log('Done! $_done/${DummyCars.all.length} cars seeded.');
    setState(() {
      _isRunning = false;
      _isDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = DummyCars.all.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Dummy Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                '• Clears existing cars & inserts 8 dummy cars\n'
                '• Images load from internet (no local files needed)\n'
                '• Go back to Home after seeding to view cars',
                style: TextStyle(fontSize: 13, color: AppTheme.textDark),
              ),
            ),
            const SizedBox(height: 16),
            if (_isRunning || _isDone) ...[
              LinearProgressIndicator(
                value: total > 0 ? _done / total : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accentGreen),
              ),
              const SizedBox(height: 6),
              Text(
                '$_done / $total',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logs.isEmpty
                        ? [
                            const Text(
                              'Logs appear here...',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ]
                        : _logs
                              .map(
                                (log) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      color: log.contains('ERR')
                                          ? Colors.red.shade300
                                          : log.contains('Done')
                                          ? Colors.green.shade300
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _seed,
                icon: _isRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isRunning
                      ? 'Seeding...'
                      : _isDone
                      ? 'Re-seed'
                      : 'Seed Dummy Cars',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_isDone) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Home'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
