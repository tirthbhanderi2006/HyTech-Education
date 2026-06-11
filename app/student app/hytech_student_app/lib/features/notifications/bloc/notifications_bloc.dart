import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/notifications_api.dart';
import '../../../core/models/notification_model.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override List<Object?> get props => [];
}
class NotificationsLoadRequested extends NotificationsEvent {}
class NotificationMarkReadRequested extends NotificationsEvent {
  final String notificationId;
  const NotificationMarkReadRequested(this.notificationId);
  @override List<Object?> get props => [notificationId];
}

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override List<Object?> get props => [];
}
class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}
class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  const NotificationsLoaded(this.notifications);
  @override List<Object?> get props => [notifications];
}
class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override List<Object?> get props => [message];
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsApi _api = NotificationsApi();

  NotificationsBloc() : super(NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkReadRequested>(_onMarkRead);
  }

  Future<void> _onLoad(NotificationsLoadRequested e, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    try {
      final items = await _api.getNotifications();
      emit(NotificationsLoaded(items));
    } catch (_) {
      emit(const NotificationsError('Failed to load notifications.'));
    }
  }

  Future<void> _onMarkRead(NotificationMarkReadRequested e, Emitter<NotificationsState> emit) async {
    await _api.markAsRead(e.notificationId);
    add(NotificationsLoadRequested());
  }
}
