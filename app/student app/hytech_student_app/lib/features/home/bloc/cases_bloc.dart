import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/cases_api.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/case_model.dart';
import '../../../core/models/checklist_model.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class CasesEvent extends Equatable {
  const CasesEvent();
  @override List<Object?> get props => [];
}

class CasesLoadRequested      extends CasesEvent {}
class CaseCreateRequested extends CasesEvent {
  final String destinationCountry, visaType, purpose;
  final String? intendedTravelDate;
  const CaseCreateRequested({
    required this.destinationCountry, required this.visaType,
    required this.purpose, this.intendedTravelDate,
  });
  @override List<Object?> get props => [destinationCountry, visaType];
}
class CaseEligibilityRequested extends CasesEvent {
  final String caseId;
  const CaseEligibilityRequested(this.caseId);
  @override List<Object?> get props => [caseId];
}
class CaseRiskRequested extends CasesEvent {
  final String caseId;
  const CaseRiskRequested(this.caseId);
  @override List<Object?> get props => [caseId];
}
class CaseChecklistLoadRequested extends CasesEvent {
  final String caseId;
  const CaseChecklistLoadRequested(this.caseId);
  @override List<Object?> get props => [caseId];
}

class CaseDeleteRequested extends CasesEvent {
  final String caseId;
  const CaseDeleteRequested(this.caseId);
  @override List<Object?> get props => [caseId];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class CasesState extends Equatable {
  const CasesState();
  @override List<Object?> get props => [];
}

class CasesInitial     extends CasesState {}
class CasesLoading     extends CasesState {}
class CasesLoaded extends CasesState {
  final List<CaseModel> cases;
  const CasesLoaded(this.cases);
  @override List<Object?> get props => [cases];
}
class CaseCreated extends CasesState {
  final CaseModel newCase;
  const CaseCreated(this.newCase);
  @override List<Object?> get props => [newCase];
}
class CaseAiResultLoaded extends CasesState {
  final Map<String, dynamic> result;
  final String type; // 'eligibility' or 'risk'
  const CaseAiResultLoaded(this.result, this.type);
  @override List<Object?> get props => [result, type];
}
class CaseChecklistLoaded extends CasesState {
  final List<ChecklistItemModel> items;
  const CaseChecklistLoaded(this.items);
  @override List<Object?> get props => [items];
}
class CasesError extends CasesState {
  final String message;
  const CasesError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class CasesBloc extends Bloc<CasesEvent, CasesState> {
  final CasesApi _api = CasesApi();

  CasesBloc() : super(CasesInitial()) {
    on<CasesLoadRequested>(_onLoad);
    on<CaseCreateRequested>(_onCreate);
    on<CaseEligibilityRequested>(_onEligibility);
    on<CaseRiskRequested>(_onRisk);
    on<CaseChecklistLoadRequested>(_onChecklist);
    on<CaseDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(CasesLoadRequested e, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final cases = await _api.listCases();
      emit(CasesLoaded(cases));
    } on ApiException catch (ex) {
      emit(CasesError(ex.message));
    }
  }

  Future<void> _onCreate(CaseCreateRequested e, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final newCase = await _api.createCase(
        destinationCountry: e.destinationCountry,
        visaType: e.visaType,
        purpose: e.purpose,
        intendedTravelDate: e.intendedTravelDate,
      );
      emit(CaseCreated(newCase));
    } on ApiException catch (ex) {
      emit(CasesError(ex.message));
    }
  }

  Future<void> _onEligibility(CaseEligibilityRequested e, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final result = await _api.runEligibility(e.caseId);
      emit(CaseAiResultLoaded(result, 'eligibility'));
    } on ApiException catch (ex) {
      emit(CasesError(ex.message));
    }
  }

  Future<void> _onRisk(CaseRiskRequested e, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final result = await _api.runRiskAnalysis(e.caseId);
      emit(CaseAiResultLoaded(result, 'risk'));
    } on ApiException catch (ex) {
      emit(CasesError(ex.message));
    }
  }

  Future<void> _onChecklist(CaseChecklistLoadRequested e, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final items = await _api.getChecklist(e.caseId);
      emit(CaseChecklistLoaded(items));
    } on ApiException catch (ex) {
      emit(CasesError(ex.message));
    }
  }

  Future<void> _onDelete(CaseDeleteRequested e, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      await _api.deleteCase(e.caseId);
      final cases = await _api.listCases();
      emit(CasesLoaded(cases));
    } on ApiException catch (ex) {
      emit(CasesError(ex.message));
    }
  }
}
