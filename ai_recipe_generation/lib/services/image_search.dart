import 'dart:convert';
import 'package:ai_recipe_generation/constants.dart';
import 'package:http/http.dart' as http;

class ImageSearchService {
  static Future<List<String>> searchImages(String query) async {
    final url = Uri.parse(
        'https://www.googleapis.com/customsearch/v1?q=$query&cx=$searchEngineId&searchType=image&key=$googleApiKey&num=3');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'] as List;
      final res = items.map((item) => item['link'] as String).toList();
      return res;
    } else {
      throw Exception('Failed to load images');
    }
  }
}
