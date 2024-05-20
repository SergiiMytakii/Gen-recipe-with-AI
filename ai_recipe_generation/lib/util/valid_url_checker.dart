import 'dart:io';
import 'package:http/http.dart' as http;

class UrlChecker {
  static Future<bool> isImageLinkValid(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      if (response.statusCode == HttpStatus.ok) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.startsWith('image/')) {
          return true; // Valid image link
        }
      }
    } catch (e) {
      // Handle error
    }
    return false; // Invalid image link
  }
}
