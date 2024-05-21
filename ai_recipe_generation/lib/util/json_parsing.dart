String cleanJson(String maybeInvalidJson) {
  if (maybeInvalidJson.contains('```')) {
    final withoutLeading = maybeInvalidJson.split('```json').last;
    final withoutTrailing = withoutLeading.split('```').first;
    final result = withoutTrailing.replaceAll('].', ']');
    return result;
  }
  return maybeInvalidJson;
}
