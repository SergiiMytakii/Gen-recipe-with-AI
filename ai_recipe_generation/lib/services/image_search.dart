import 'dart:convert';
import 'package:ai_recipe_generation/constants.dart';
import 'package:ai_recipe_generation/util/valid_url_checker.dart';
import 'package:http/http.dart' as http;

class ImageSearchService {
  static Future<String?> searchImage(String query) async {
    final url = Uri.parse(
        'https://www.googleapis.com/customsearch/v1?q=$query&cx=$searchEngineId&searchType=image&key=$googleApiKey&num=3');
    final response = await http.get(url);
    String? imageLink;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'] as List;
      final res = items.map((item) => item['link'] as String).toList();
      for (final image in res) {
        if (await UrlChecker.isImageLinkValid(image)) {
          imageLink = image;
          break;
        }
      }
      return imageLink;
    } else {
      throw Exception('Failed to load images');
    }
  }
}
