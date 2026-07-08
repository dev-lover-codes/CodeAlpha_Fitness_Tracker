class AppException implements Exception {
  final String message;
  final dynamic details;

  AppException(this.message, [this.details]);

  @override
  String toString() => message;
}
