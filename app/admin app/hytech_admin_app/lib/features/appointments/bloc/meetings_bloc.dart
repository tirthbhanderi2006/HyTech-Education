import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/meetings_api.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/models/user_model.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class MeetingsEvent extends Equatable {
  const MeetingsEvent();
  @override
  List<Object?> get props => [];
}

class MeetingsLoadRequested extends MeetingsEvent {}

class MeetingCancelRequested extends MeetingsEvent {
  final String meetingId;
  const MeetingCancelRequested(this.meetingId);

  @override
  List<Object?> get props => [meetingId];
}

class MeetingRescheduleRequested extends MeetingsEvent {
  final String meetingId;
  final DateTime startTime;
  final DateTime endTime;
  const MeetingRescheduleRequested({
    required this.meetingId,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [meetingId, startTime, endTime];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class MeetingsState extends Equatable {
  const MeetingsState();
  @override
  List<Object?> get props => [];
}

class MeetingsInitial extends MeetingsState {}
class MeetingsLoading extends MeetingsState {}
class MeetingsLoaded extends MeetingsState {
  final List<MeetingModel> meetings;
  final List<UserModel> counselors;

  const MeetingsLoaded(this.meetings, this.counselors);

  @override
  List<Object?> get props => [meetings, counselors];
}
class MeetingsError extends MeetingsState {
  final String message;
  const MeetingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class MeetingsBloc extends Bloc<MeetingsEvent, MeetingsState> {
  final MeetingsApi _api = MeetingsApi();

  MeetingsBloc() : super(MeetingsInitial()) {
    on<MeetingsLoadRequested>(_onLoad);
    on<MeetingCancelRequested>(_onCancel);
    on<MeetingRescheduleRequested>(_onReschedule);
  }

  Future<void> _onLoad(MeetingsLoadRequested event, Emitter<MeetingsState> emit) async {
    emit(MeetingsLoading());
    try {
      final meetings = await _api.getMeetings();
      final counselors = await _api.getCounselors();
      emit(MeetingsLoaded(meetings, counselors));
    } catch (e) {
      emit(const MeetingsError('Failed to load counseling sessions.'));
    }
  }

  Future<void> _onCancel(MeetingCancelRequested event, Emitter<MeetingsState> emit) async {
    final currentState = state;
    List<MeetingModel> oldMeetings = [];
    List<UserModel> oldCounselors = [];
    if (currentState is MeetingsLoaded) {
      oldMeetings = currentState.meetings;
      oldCounselors = currentState.counselors;
    }

    try {
      await _api.cancelMeeting(event.meetingId);
      // Reload meetings
      final meetings = await _api.getMeetings();
      emit(MeetingsLoaded(meetings, oldCounselors));
    } catch (_) {
      emit(const MeetingsError('Cancellation failed.'));
      emit(MeetingsLoaded(oldMeetings, oldCounselors));
    }
  }

  Future<void> _onReschedule(MeetingRescheduleRequested event, Emitter<MeetingsState> emit) async {
    final currentState = state;
    List<MeetingModel> oldMeetings = [];
    List<UserModel> oldCounselors = [];
    if (currentState is MeetingsLoaded) {
      oldMeetings = currentState.meetings;
      oldCounselors = currentState.counselors;
    }

    emit(MeetingsLoading());
    try {
      await _api.rescheduleMeeting(event.meetingId, event.startTime, event.endTime);
      // Reload meetings
      final meetings = await _api.getMeetings();
      emit(MeetingsLoaded(meetings, oldCounselors));
    } catch (_) {
      emit(const MeetingsError('Reschedule failed.'));
      emit(MeetingsLoaded(oldMeetings, oldCounselors));
    }
  }
}
