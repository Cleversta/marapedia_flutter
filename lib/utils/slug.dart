String slugify(String text) {
  return text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\w\s-]'), '')
    .replaceAll(RegExp(r'[\s_]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '')
    .trim();
}
