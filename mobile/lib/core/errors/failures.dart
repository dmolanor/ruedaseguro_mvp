abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de caché local']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Error de autenticación']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Error de validación']);
}

class ImageQualityFailure extends Failure {
  final double? sharpness;
  final bool? isScreenPhoto;

  const ImageQualityFailure({
    String message = 'La imagen no cumple los requisitos de calidad',
    this.sharpness,
    this.isScreenPhoto,
  }) : super(message);
}
