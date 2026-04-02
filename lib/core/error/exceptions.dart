class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'A server error occurred.'});
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException({required this.message});
  @override
  String toString() => message;
}

class StorageException implements Exception {
  final String message;
  StorageException({this.message = 'A storage error occurred.'});
  @override
  String toString() => message;
}
