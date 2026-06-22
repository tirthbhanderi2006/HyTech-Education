import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/cases_api.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/case_model.dart';
import '../../../core/models/checklist_model.dart';
import '../../../core/models/document_model.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class AdminStudentEvent extends Equatable {
  const AdminStudentEvent();
  @override
  List<Object?> get props => [];
}

class AdminRegisterStudentRequested extends AdminStudentEvent {
  final String email, password, fullName, phone, nationality;
  const AdminRegisterStudentRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.nationality,
  });

  @override
  List<Object?> get props => [email, fullName];
}

class AdminCreateStudentCaseRequested extends AdminStudentEvent {
  final String destinationCountry, visaType, purpose;
  const AdminCreateStudentCaseRequested({
    required this.destinationCountry,
    required this.visaType,
    required this.purpose,
  });

  @override
  List<Object?> get props => [destinationCountry, visaType, purpose];
}

class AdminLoadLeadsRequested extends AdminStudentEvent {}

class AdminLoadLeadDetailsRequested extends AdminStudentEvent {
  final UserModel student;
  final String? caseId;
  const AdminLoadLeadDetailsRequested(this.student, {this.caseId});

  @override
  List<Object?> get props => [student, caseId];
}

class AdminRunAiAssessmentsRequested extends AdminStudentEvent {
  final String caseId;
  const AdminRunAiAssessmentsRequested(this.caseId);

  @override
  List<Object?> get props => [caseId];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class AdminStudentState extends Equatable {
  const AdminStudentState();
  @override
  List<Object?> get props => [];
}

class AdminStudentInitial extends AdminStudentState {}
class AdminStudentLoading extends AdminStudentState {}

class AdminLeadsLoaded extends AdminStudentState {
  final List<UserModel> leads;
  const AdminLeadsLoaded(this.leads);

  @override
  List<Object?> get props => [leads];
}

class AdminStudentRegistered extends AdminStudentState {
  final UserModel student;
  const AdminStudentRegistered(this.student);

  @override
  List<Object?> get props => [student];
}

class AdminStudentCaseCreated extends AdminStudentState {
  final CaseModel studentCase;
  final List<ChecklistItemModel> checklist;
  const AdminStudentCaseCreated(this.studentCase, this.checklist);

  @override
  List<Object?> get props => [studentCase, checklist];
}

class AdminLeadDetailsLoaded extends AdminStudentState {
  final UserModel student;
  final CaseModel? activeCase;
  final List<CaseModel> allCases;
  final List<ChecklistItemModel> checklist;
  final List<DocumentModel> uploadedDocs;
  final Map<String, dynamic>? eligibilityReport;
  final Map<String, dynamic>? riskReport;

  const AdminLeadDetailsLoaded({
    required this.student,
    this.activeCase,
    this.allCases = const [],
    this.checklist = const [],
    this.uploadedDocs = const [],
    this.eligibilityReport,
    this.riskReport,
  });

  @override
  List<Object?> get props => [student, activeCase, allCases, checklist, uploadedDocs, eligibilityReport, riskReport];
}

class AdminStudentError extends AdminStudentState {
  final String message;
  const AdminStudentError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class AdminStudentBloc extends Bloc<AdminStudentEvent, AdminStudentState> {
  final AuthApi _authApi = AuthApi();
  final CasesApi _casesApi = CasesApi();

  UserModel? _registeredStudent;
  CaseModel? _activeCase;
  List<ChecklistItemModel> _checklist = [];
  List<UserModel> leads = [];

  AdminStudentBloc() : super(AdminStudentInitial()) {
    on<AdminLoadLeadsRequested>(_onLoadLeads);
    on<AdminRegisterStudentRequested>(_onRegister);
    on<AdminCreateStudentCaseRequested>(_onCreateCase);
    on<AdminLoadLeadDetailsRequested>(_onLoadDetails);
    on<AdminRunAiAssessmentsRequested>(_onRunAi);
  }

  Future<void> _onLoadLeads(AdminLoadLeadsRequested e, Emitter<AdminStudentState> emit) async {
    emit(AdminStudentLoading());
    try {
      final leadsList = await _authApi.listUsers();
      leads = leadsList;
      emit(AdminLeadsLoaded(leadsList));
    } on ApiException catch (ex) {
      emit(AdminStudentError(ex.message));
    } catch (_) {
      emit(const AdminStudentError('Failed to load leads list from database.'));
    }
  }

  Future<void> _onRegister(AdminRegisterStudentRequested e, Emitter<AdminStudentState> emit) async {
    emit(AdminStudentLoading());
    try {
      final student = await _authApi.register(
        email: e.email,
        password: e.password,
        fullName: e.fullName,
        phone: e.phone.isNotEmpty ? e.phone : null,
        nationality: e.nationality.isNotEmpty ? e.nationality : null,
      );
      _registeredStudent = student;
      _activeCase = null;
      _checklist = [];
      emit(AdminStudentRegistered(student));
    } on ApiException catch (ex) {
      emit(AdminStudentError(ex.message));
    } catch (_) {
      emit(const AdminStudentError('Registration failed. Please verify credentials.'));
    }
  }

  Future<void> _onCreateCase(AdminCreateStudentCaseRequested e, Emitter<AdminStudentState> emit) async {
    emit(AdminStudentLoading());
    try {
      // Create case
      final caseModel = await _casesApi.createCase(
        destinationCountry: e.destinationCountry,
        visaType: e.visaType,
        purpose: e.purpose,
      );
      _activeCase = caseModel;

      // Load checklist
      final checklistItems = await _casesApi.getChecklist(caseModel.id);
      _checklist = checklistItems;

      emit(AdminStudentCaseCreated(caseModel, checklistItems));
    } on ApiException catch (ex) {
      emit(AdminStudentError(ex.message));
    } catch (_) {
      emit(const AdminStudentError('Failed to create visa case for student.'));
    }
  }

  Future<void> _onLoadDetails(AdminLoadLeadDetailsRequested e, Emitter<AdminStudentState> emit) async {
    emit(AdminStudentLoading());
    try {
      final user = e.student;
      final cases = await _casesApi.listCases(userId: user.id);
      
      CaseModel? active;
      List<ChecklistItemModel> checklist = [];
      List<DocumentModel> docs = [];
      Map<String, dynamic>? elReport;
      Map<String, dynamic>? rkReport;

      if (cases.isNotEmpty) {
        active = cases.firstWhere(
          (c) => c.id == e.caseId,
          orElse: () => cases.first,
        );
        checklist = await _casesApi.getChecklist(active.id);
        try {
          docs = await _casesApi.listCaseDocuments(active.id);
        } catch (_) {}
        
        try {
          elReport = await _casesApi.runEligibility(active.id);
          rkReport = await _casesApi.runRiskAnalysis(active.id);
        } catch (_) {}
      }

      emit(AdminLeadDetailsLoaded(
        student: user,
        activeCase: active,
        allCases: cases,
        checklist: checklist,
        uploadedDocs: docs,
        eligibilityReport: elReport,
        riskReport: rkReport,
      ));
    } on ApiException catch (ex) {
      emit(AdminStudentError(ex.message));
    } catch (_) {
      emit(const AdminStudentError('Failed to load student case metrics.'));
    }
  }

  Future<void> _onRunAi(AdminRunAiAssessmentsRequested e, Emitter<AdminStudentState> emit) async {
    if (_registeredStudent == null) return;
    emit(AdminStudentLoading());
    try {
      final el = await _casesApi.runEligibility(e.caseId);
      final rk = await _casesApi.runRiskAnalysis(e.caseId);
      emit(AdminLeadDetailsLoaded(
        student: _registeredStudent!,
        activeCase: _activeCase,
        checklist: _checklist,
        eligibilityReport: el,
        riskReport: rk,
      ));
    } catch (_) {
      emit(const AdminStudentError('AI assessment execution failed.'));
    }
  }
}
