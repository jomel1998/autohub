// lib/features/car/presentation/pages/add_car_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/car.dart';
import '../provider/car_provider.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});
  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedBrand = AppConstants.carBrands.first;
  String _selectedCategory = AppConstants.carCategories.first;
  String _selectedFuel = AppConstants.fuelTypes.first;
  String _selectedTransmission = AppConstants.transmissions.first;

  File? _imageFile;
  bool _isLoading = false;
  String _uploadStep = ''; // shows current upload stage to user
  double _uploadPct = 0; // 0.0 → 1.0 progress

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // REQUEST PERMISSION THEN OPEN GALLERY
  // ─────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    // Android 13+: READ_MEDIA_IMAGES | older: READ_EXTERNAL_STORAGE
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.photos.request();
      // fallback for Android 12 and below
      if (status.isDenied) status = await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog('Photo Library');
      return;
    }
    if (!status.isGranted) {
      _showSnack('Gallery permission denied. Please allow in Settings.');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 960,
      );
      if (picked != null && mounted) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      _showSnack('Could not open gallery: $e');
    }
  }

  // ─────────────────────────────────────────────────
  // REQUEST PERMISSION THEN OPEN CAMERA
  // ─────────────────────────────────────────────────
  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();

    if (status.isPermanentlyDenied) {
      _showPermissionDialog('Camera');
      return;
    }
    if (!status.isGranted) {
      _showSnack('Camera permission denied. Please allow in Settings.');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 960,
      );
      if (picked != null && mounted) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      _showSnack('Could not open camera: $e');
    }
  }

  // ─────────────────────────────────────────────────
  // SUBMIT: UPLOAD IMAGE → INSERT TO DB → SHOW SUCCESS
  // ─────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadPct = 0;
      _uploadStep = 'Preparing...';
    });

    final user = Supabase.instance.client.auth.currentUser;
    final userName =
        user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        'Anonymous';
    final carId = const Uuid().v4();

    // ── Step 1: Upload image ──────────────────────
    String imageUrl = '';
    if (_imageFile != null) {
      setState(() {
        _uploadStep = 'Uploading photo...';
        _uploadPct = 0.2;
      });
      try {
        final ext = _imageFile!.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final fileName =
            '${carId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final filePath = 'cars/$fileName';
        final bytes = await _imageFile!.readAsBytes();

        setState(() => _uploadPct = 0.4);

        await Supabase.instance.client.storage
            .from('car-images')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: false),
            );

        setState(() => _uploadPct = 0.65);

        imageUrl = Supabase.instance.client.storage
            .from('car-images')
            .getPublicUrl(filePath);

        setState(() {
          _uploadStep = 'Photo uploaded!';
          _uploadPct = 0.75;
        });
      } catch (e) {
        // Image upload failed — still save the car without an image
        _showSnack('Photo upload failed: $e\nCar will be saved without photo.');
        imageUrl = '';
      }
    } else {
      setState(() => _uploadPct = 0.75);
    }

    // ── Step 2: Save car to Supabase ─────────────
    setState(() {
      _uploadStep = 'Saving car details...';
      _uploadPct = 0.85;
    });

    final car = Car(
      id: carId,
      name: _nameController.text.trim(),
      brand: _selectedBrand,
      price: _priceController.text.trim(),
      imageUrl: imageUrl,
      category: _selectedCategory,
      fuelType: _selectedFuel,
      transmission: _selectedTransmission,
      year: _yearController.text.trim(),
      description: _descController.text.trim(),
      sellerId: user?.id ?? '',
      sellerName: userName,
      createdAt: DateTime.now(),
    );

    final provider = Provider.of<CarProvider>(context, listen: false);
    // Pass null imageFile since we already uploaded it above
    final success = await provider.addCar(car);

    setState(() {
      _uploadPct = 1.0;
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      // ── Success dialog ──────────────────────────
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Car Listed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${car.name} is now live on CarMarket.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    Navigator.of(context).pop(); // go back to home
                  },
                  child: const Text('View Home'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _showSnack('Failed to save car: ${provider.errorMessage}', isError: true);
    }
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell Your Car')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Photo section ─────────────────────
                  _buildPhotoSection(),
                  const SizedBox(height: 24),

                  // ── Car details ───────────────────────
                  _sectionHeader('Car Details'),
                  const SizedBox(height: 12),

                  _field(
                    controller: _nameController,
                    label: 'Car Name',
                    hint: 'e.g. Maruti Swift VXi 2022',
                    icon: Icons.directions_car_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter car name'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _dropdown(
                    label: 'Brand',
                    icon: Icons.branding_watermark_outlined,
                    value: _selectedBrand,
                    items: AppConstants.carBrands,
                    onChanged: (v) => setState(() => _selectedBrand = v!),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _priceController,
                          label: 'Price (₹)',
                          hint: '650000',
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter price'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _yearController,
                          label: 'Year',
                          hint: '2022',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final y = int.tryParse(v ?? '');
                            if (y == null ||
                                y < 1990 ||
                                y > DateTime.now().year + 1) {
                              return 'Valid year';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Specifications ────────────────────
                  _sectionHeader('Specifications'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _dropdown(
                          label: 'Category',
                          icon: Icons.category_outlined,
                          value: _selectedCategory,
                          items: AppConstants.carCategories,
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown(
                          label: 'Fuel Type',
                          icon: Icons.local_gas_station_outlined,
                          value: _selectedFuel,
                          items: AppConstants.fuelTypes,
                          onChanged: (v) => setState(() => _selectedFuel = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _dropdown(
                    label: 'Transmission',
                    icon: Icons.settings_outlined,
                    value: _selectedTransmission,
                    items: AppConstants.transmissions,
                    onChanged: (v) =>
                        setState(() => _selectedTransmission = v!),
                  ),

                  const SizedBox(height: 24),

                  // ── Description ───────────────────────
                  _sectionHeader('Description'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Condition, features, modifications, reason for selling...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Upload overlay ────────────────────────
          if (_isLoading) _buildUploadOverlay(),
        ],
      ),

      // ── Fixed bottom submit button ─────────────
      bottomNavigationBar: _isLoading ? null : _buildSubmitBar(),
    );
  }

  // ─────────────────────────────────────────────────
  // PHOTO SECTION
  // ─────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Car Photo'),
        const SizedBox(height: 8),
        const Text(
          'A good photo gets 3× more views',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Preview box
        GestureDetector(
          onTap: _showImageSheet,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _imageFile != null
                    ? AppTheme.accentGreen
                    : Colors.grey.shade300,
                width: _imageFile != null ? 2 : 1,
              ),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 32,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to add car photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG or PNG, up to 10MB',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: GestureDetector(
                        onTap: _showImageSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Two explicit buttons — always visible
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ],
        ),

        // File name + remove
        if (_imageFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentGreen,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _imageFile!.path.split('/').last,
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _imageFile = null),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // UPLOAD PROGRESS OVERLAY
  // ─────────────────────────────────────────────────
  Widget _buildUploadOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryBlue),
                const SizedBox(height: 20),
                Text(
                  _uploadStep,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadPct,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(
                      AppTheme.accentGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_uploadPct * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please don\'t close the app',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // FIXED BOTTOM SUBMIT BAR
  // ─────────────────────────────────────────────────
  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _handleSubmit,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(
            _imageFile != null ? 'Upload Photo & List Car' : 'List Car',
          ),
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
    );
  }

  // ─────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppTheme.textDark,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
    );
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Pick any photo from your phone'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.camera_alt_outlined, color: Colors.green),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Use camera to capture now'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              if (_imageFile != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imageFile = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermissionDialog(String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$type Permission Required'),
        content: Text(
          '$type access was permanently denied. '
          'Please open Settings and allow $type permission for CarMarket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
