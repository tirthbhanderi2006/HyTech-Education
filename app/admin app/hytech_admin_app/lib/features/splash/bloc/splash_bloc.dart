import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class SplashEvent extends Equatable {
  const SplashEvent();
  @override
  List<Object> get props => [];
}

class SplashStarted extends SplashEvent {}

// States
abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object> get props => [];
}

class SplashInitial extends SplashState {}
class SplashLoading extends SplashState {}
class SplashCompleted extends SplashState {}

// Bloc
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<SplashStarted>((event, emit) async {
      emit(SplashLoading());
      await Future.delayed(const Duration(seconds: 2));
      emit(SplashCompleted());
    });
  }
}
