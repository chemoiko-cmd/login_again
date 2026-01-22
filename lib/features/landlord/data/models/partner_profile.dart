import 'dart:convert';
import 'dart:typed_data';

class PartnerProfile {
  final int id;
  final String name;
  final String email;
  final String emailNormalized;
  final String phone;
  final String mobile;
  final String street;
  final String city;
  final String country;
  final Uint8List? imageBytes;

  const PartnerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.emailNormalized,
    required this.phone,
    required this.mobile,
    required this.street,
    required this.city,
    required this.country,
    this.imageBytes,
  });

  static String _s(dynamic v) => v is String ? v : '';

  factory PartnerProfile.fromOdoo(Map<String, dynamic> m) {
    final countryId = m['country_id'];
    final country = (countryId is List && countryId.length > 1)
        ? (countryId[1] ?? '').toString()
        : '';

    final email = _s(m['email']).trim();
    final emailNormalized = _s(m['email_normalized']).trim();
    final resolvedEmail = email.isNotEmpty ? email : emailNormalized;

    Uint8List? bytes;
    final img = m['image_128'];
    if (img is String && img.trim().isNotEmpty) {
      try {
        bytes = base64Decode(img);
      } catch (_) {}
    }

    return PartnerProfile(
      id: (m['id'] as int?) ?? 0,
      name: _s(m['name']),
      email: resolvedEmail,
      emailNormalized: emailNormalized,
      phone: _s(m['phone']),
      mobile: _s(m['mobile']),
      street: _s(m['street']),
      city: _s(m['city']),
      country: country,
      imageBytes: bytes,
    );
  }
}
