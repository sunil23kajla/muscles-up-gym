import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/inquiry_model.dart';

class WebsiteRepository {
  final ApiClient _client = ApiClient();

  // 1. Get Website dynamic layout settings
  Future<Map<String, dynamic>> getWebsiteConfig() async {
    final response = await _client.get(ApiEndpoints.websiteSettings);
    return response as Map<String, dynamic>;
  }

  // 2. Update Website dynamic layout setting (stats counters, banner message, etc.)
  Future<bool> updateWebsiteSetting(String key, dynamic value) async {
    await _client.put(ApiEndpoints.websiteSettings, {
      'key': key,
      'value': value,
    });
    return true;
  }

  // 3. Get all prospective client website inquiries
  Future<List<InquiryModel>> getInquiries() async {
    final response = await _client.get(ApiEndpoints.inquiries);
    if (response is List) {
      return response.map((item) => InquiryModel.fromJson(item)).toList();
    }
    return [];
  }

  // 4. Update inquiry review status ('contacted', 'joined', etc.)
  Future<bool> updateInquiryStatus(String id, String status) async {
    await _client.put('${ApiEndpoints.inquiries}/$id', {
      'status': status,
    });
    return true;
  }

  // 5. Delete spam or unwanted inquiries
  Future<bool> deleteInquiry(String id) async {
    await _client.delete('${ApiEndpoints.inquiries}/$id');
    return true;
  }

  // 6. Upload a gallery media file (image/video)
  Future<String> uploadGalleryMedia(String filePath) async {
    final response = await _client.uploadMedia('/upload_gallery.php', filePath);
    // Assuming the PHP script returns { "url": "..." }
    return response['url'] as String;
  }
}
