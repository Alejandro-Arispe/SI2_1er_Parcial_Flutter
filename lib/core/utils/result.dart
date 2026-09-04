import 'package:fashion_store/core/error/failures.dart';

/// Tipo de resultado utilizado en toda la capa de dominio para representar
/// el éxito o el fallo de una operación (caso de uso / repositorio) sin
/// depender de excepciones para el control de flujo.
///
/// Se usa en lugar de un paquete externo (como dartz) para mantener la
/// cantidad de dependencias al mínimo, aprovechando las sealed classes
/// de Dart 3 y el pattern matching con switch.
sealed class Result<T> {
  const Result();
}

/// Representa una operación exitosa y contiene el dato obtenido.
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Representa una operación fallida y contiene el Failure de dominio
/// correspondiente (ver core/error/failures.dart).
final class ResultError<T> extends Result<T> {
  final Failure failure;
  const ResultError(this.failure);
}
