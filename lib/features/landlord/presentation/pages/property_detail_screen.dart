import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/data/repositories/landlord_repository.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:login_again/core/utils/formatters.dart';
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _property;
  List<Map<String, dynamic>> _units = [];
  LatLng? _propertyLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  Future<void> _loadProperty() async {
    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is! Authenticated) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      final repo = LandlordRepository(
        apiClient: context.read<AuthCubit>().apiClient,
      );
      final properties = await repo.fetchProperties(
        ownerPartnerId: auth.user.partnerId,
      );

      if (!mounted) return;

      final property = properties.firstWhere(
        (p) => p['id'] == widget.propertyId,
        orElse: () => <String, dynamic>{},
      );

      // Fetch units for this property to get bedroom count
      final units = await repo.fetchUnitsByProperty(
        propertyId: widget.propertyId,
      );

      // Get coordinates from property data (stored in backend)
      LatLng? location;
      final geoLat = property['geo_lat'] as double?;
      final geoLong = property['geo_long'] as double?;

      // Debug: Print coordinates
      print('Property ID: ${widget.propertyId}');
      print('geo_lat: $geoLat');
      print('geo_long: $geoLong');
      print('Full property data: $property');

      if (geoLat != null &&
          geoLong != null &&
          geoLat != 0.0 &&
          geoLong != 0.0) {
        location = LatLng(geoLat, geoLong);
        print('Location set: $location');
      } else {
        print('Location NOT set - coordinates are null or 0');
      }

      if (!mounted) return;

      setState(() {
        _property = property;
        _units = units;
        _propertyLocation = location;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _property == null || _property!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = (_property!['name'] ?? 'Property').toString();
    final Uint8List? imageBytes = _property!['image_bytes'] as Uint8List?;
    final street = (_property!['street'] ?? '').toString();
    final city = (_property!['city'] ?? '').toString();
    final rentAmount =
        (_property!['default_rent_amount'] as num?)?.toDouble() ?? 0.0;

    final address = [street, city].where((e) => e.isNotEmpty).join(', ');

    final unitsCount = (_property!['units_count'] as int?) ?? 0;

    // Calculate average bedroom count from units
    int totalBedrooms = 0;
    if (_units.isNotEmpty) {
      for (final unit in _units) {
        totalBedrooms += (unit['room_count'] as int?) ?? 0;
      }
    }
    final avgBedrooms = _units.isNotEmpty
        ? (totalBedrooms / _units.length).round()
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  imageBytes != null
                      ? Image.memory(imageBytes, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.home,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.image, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '1',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.home_outlined,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'House',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        formatCurrency(rentAmount, currencySymbol: 'UGX'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        ' / month',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Facilities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        // Ensures "Bedroom" takes up half the width
                        child: _FacilityItem(
                          icon: Icons.bed_outlined,
                          label: 'Bedroom',
                          value: avgBedrooms > 0 ? '$avgBedrooms' : 'N/A',
                        ),
                      ),
                      Expanded(
                        child: _FacilityItem(
                          icon: Icons.apartment_outlined,
                          label: 'Units',
                          value: unitsCount > 0 ? '$unitsCount' : 'N/A',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  if (address.isEmpty)
                    const Text(
                      'No address provided',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FacilityItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
