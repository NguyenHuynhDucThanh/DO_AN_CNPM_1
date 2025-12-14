import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Đã xảy ra lỗi máy chủ']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lỗi truy xuất dữ liệu nội bộ']);
}

// Lỗi đặc thù cho Auth
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}