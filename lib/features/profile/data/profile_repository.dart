import 'package:dio/dio.dart';
import 'package:login_again/core/api/api_client.dart';
import 'package:login_again/features/landlord/data/models/partner_profile.dart';

class ProfileRepository {
  final ApiClient apiClient;

  ProfileRepository({required this.apiClient});

  Future<PartnerProfile?> fetchPartnerProfile({required int partnerId}) async {
    try {
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'res.partner',
          'method': 'search_read',
          'args': [
            [
              ['id', '=', partnerId],
            ],
          ],
          'kwargs': {
            'fields': [
              'id',
              'name',
              'email',
              'email_normalized',
              'phone',
              'mobile',
              'street',
              'city',
              'country_id',
              'image_128',
            ],
            'limit': 1,
          },
        },
        'id': 1,
      };

      final resp = await apiClient.post('/web/dataset/call_kw', data: payload);
      final list = (resp.data['result'] as List?) ?? [];
      if (list.isEmpty) return null;

      final m = Map<String, dynamic>.from(list.first as Map);
      return PartnerProfile.fromOdoo(m);
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }
}
