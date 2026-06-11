import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/documents_api.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/document_model.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class DocumentsEvent extends Equatable {
  const DocumentsEvent();
  @override List<Object?> get props => [];
}

class DocumentsLoadRequested extends DocumentsEvent {
  final String caseId;
  const DocumentsLoadRequested(this.caseId);
  @override List<Object?> get props => [caseId];
}

class DocumentUploadRequested extends DocumentsEvent {
  final String caseId, documentType;
  final File file;
  final String? intendedTravelDate;
  const DocumentUploadRequested({
    required this.caseId, required this.documentType,
    required this.file, this.intendedTravelDate,
  });
  @override List<Object?> get props => [caseId, documentType];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class DocumentsState extends Equatable {
  const DocumentsState();
  @override List<Object?> get props => [];
}

class DocumentsInitial extends DocumentsState {}
class DocumentsLoading extends DocumentsState {}
class DocumentsLoaded extends DocumentsState {
  final List<DocumentModel> documents;
  const DocumentsLoaded(this.documents);
  @override List<Object?> get props => [documents];
}
class DocumentUploading extends DocumentsState {}
class DocumentUploaded extends DocumentsState {
  final DocumentModel document;
  const DocumentUploaded(this.document);
  @override List<Object?> get props => [document];
}
class DocumentsError extends DocumentsState {
  final String message;
  const DocumentsError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final DocumentsApi _api = DocumentsApi();

  DocumentsBloc() : super(DocumentsInitial()) {
    on<DocumentsLoadRequested>(_onLoad);
    on<DocumentUploadRequested>(_onUpload);
  }

  Future<void> _onLoad(DocumentsLoadRequested e, Emitter<DocumentsState> emit) async {
    emit(DocumentsLoading());
    try {
      final docs = await _api.getCaseDocuments(e.caseId);
      emit(DocumentsLoaded(docs));
    } on ApiException catch (ex) {
      emit(DocumentsError(ex.message));
    }
  }

  Future<void> _onUpload(DocumentUploadRequested e, Emitter<DocumentsState> emit) async {
    emit(DocumentUploading());
    try {
      final doc = await _api.uploadDocument(
        caseId: e.caseId,
        documentType: e.documentType,
        file: e.file,
        intendedTravelDate: e.intendedTravelDate,
      );
      emit(DocumentUploaded(doc));
      // Reload documents list
      add(DocumentsLoadRequested(e.caseId));
    } on ApiException catch (ex) {
      emit(DocumentsError(ex.message));
    }
  }
}
