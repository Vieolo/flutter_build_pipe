enum WebVersioningType {
  semver,
  hash;

  static WebVersioningType getByName(String? n) {
    return WebVersioningType.values.firstWhere(
      (z) => z.name == n,
      orElse: () => WebVersioningType.hash,
    );
  }

  bool get isHash => this == WebVersioningType.hash;
}

class WebConfig {
  // Web specific
  bool? addVersionQueryParam;
  WebVersioningType? webVersioningType;

  WebConfig({this.addVersionQueryParam, this.webVersioningType});
}
