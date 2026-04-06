// lib/features/car/presentation/pages/test_drive_page.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/car.dart';

class TestDrivePage extends StatefulWidget {
  final Car? car; // null = user picks from list
  const TestDrivePage({super.key, this.car});
  @override
  State<TestDrivePage> createState() => _TestDrivePageState();
}

class _TestDrivePageState extends State<TestDrivePage> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  String _selectedLocation = 'Showroom';
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _booked = false;

  static const _slots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
  ];

  static const _locations = ['Showroom', 'Your Location', 'Dealer Lot'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Please enter your name');
      return;
    }
    if (_phoneCtrl.text.trim().length < 10) {
      _snack('Enter a valid phone number');
      return;
    }
    if (_selectedDate == null) {
      _snack('Please select a date');
      return;
    }
    if (_selectedSlot == null) {
      _snack('Please select a time slot');
      return;
    }
    setState(() => _booked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_booked) return _buildSuccess();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Test Drive')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Car info banner ──────────────────────
            if (widget.car != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.car!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          Text(
                            '${widget.car!.brand} • ${widget.car!.year}',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_fmtPrice(widget.car!.price)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentGreen,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Personal details ─────────────────────
            _sectionTitle('Your Details'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // ── Date picker ──────────────────────────
            _sectionTitle('Select Date'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDate != null
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade300,
                    width: _selectedDate != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: _selectedDate != null
                          ? AppTheme.primaryBlue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Tap to choose a date',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? AppTheme.textDark
                            : Colors.grey,
                        fontWeight: _selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Time slots ───────────────────────────
            _sectionTitle('Select Time'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _slots.map((slot) {
                final sel = _selectedSlot == slot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primaryBlue
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        color: sel ? Colors.white : AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Location ─────────────────────────────
            _sectionTitle('Test Drive Location'),
            const SizedBox(height: 10),
            Column(
              children: _locations.map((loc) {
                final sel = _selectedLocation == loc;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLocation = loc),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryBlue.withOpacity(0.07)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primaryBlue
                            : Colors.grey.shade300,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          loc == 'Showroom'
                              ? Icons.store_outlined
                              : loc == 'Your Location'
                              ? Icons.my_location
                              : Icons.local_parking_outlined,
                          color: sel ? AppTheme.primaryBlue : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          loc,
                          style: TextStyle(
                            color: sel
                                ? AppTheme.primaryBlue
                                : AppTheme.textDark,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (sel)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // ── Summary ──────────────────────────────
            if (_selectedDate != null && _selectedSlot != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _summaryRow('Date', _formatDate(_selectedDate!)),
                    _summaryRow('Time', _selectedSlot!),
                    _summaryRow('Location', _selectedLocation),
                    if (widget.car != null)
                      _summaryRow('Car', widget.car!.name),
                  ],
                ),
              ),

            // ── Book button ──────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.event_available),
                label: const Text('Confirm Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() => Scaffold(
    appBar: AppBar(title: const Text('Test Drive Booked')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.accentGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Test Drive Confirmed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your test drive is booked for\n'
              '${_formatDate(_selectedDate!)} at $_selectedSlot\nat $_selectedLocation',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will receive a confirmation call from the seller.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppTheme.textDark,
    ),
  );

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.textDark,
          ),
        ),
      ],
    ),
  );

  String _formatDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtPrice(String p) {
    final n = int.tryParse(p.replaceAll(',', '').replaceAll('₹', ''));
    if (n == null) return p;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
    return p;
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red,
    ),
  );
}
