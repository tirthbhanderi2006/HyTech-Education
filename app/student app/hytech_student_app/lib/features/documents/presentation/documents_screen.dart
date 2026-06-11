import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/checklist_model.dart';
import '../../../core/models/document_model.dart';
import '../../home/bloc/cases_bloc.dart';
import '../bloc/documents_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';

// ── Document model — mapped from checklist items ────
class _Document {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final _DocStatus status;
  final bool isRequired;

  const _Document({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.status,
    this.isRequired = true,
  });
}

enum _DocStatus { verified, processing, error, pending, optional }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String? _caseId;

  @override
  void initState() {
    super.initState();
    // Dispatch loading cases when screen initializes
    context.read<CasesBloc>().add(CasesLoadRequested());
  }

  String _getDocTitle(String docType) {
    return switch (docType) {
      'passport' => 'Passport',
      'bank_statement' => 'Bank Statements',
      'degree_certificate' => 'Degree Certificate',
      'lor' => 'Letter of Recommendation',
      'photo' => 'Passport-size Photo',
      _ => docType.replaceAll('_', ' ').toUpperCase(),
    };
  }

  IconData _getDocIcon(String docType) {
    return switch (docType) {
      'passport' => Icons.book,
      'bank_statement' => Icons.account_balance,
      'degree_certificate' => Icons.workspace_premium,
      'lor' => Icons.mail_outline,
      'photo' => Icons.face,
      _ => Icons.description,
    };
  }

  Color _getDocIconColor(String docType) {
    return switch (docType) {
      'passport' => AppColors.primary,
      'bank_statement' => AppColors.onSurfaceVariant,
      'degree_certificate' => AppColors.error,
      'lor' => AppColors.secondary,
      'photo' => AppColors.onSurfaceVariant,
      _ => AppColors.primary,
    };
  }

  List<_Document> _mapChecklistToDocs(List<ChecklistItemModel> items) {
    return items.map((item) {
      final title = _getDocTitle(item.documentType);
      final icon = _getDocIcon(item.documentType);
      final iconColor = _getDocIconColor(item.documentType);
      
      final status = switch (item.status) {
        'validated' => _DocStatus.verified,
        'rejected' => _DocStatus.error,
        _ => item.isMandatory ? _DocStatus.pending : _DocStatus.optional,
      };

      return _Document(
        id: item.documentType,
        title: title,
        subtitle: item.personalizedDescription,
        icon: icon,
        iconColor: iconColor,
        status: status,
        isRequired: item.isMandatory,
      );
    }).toList();
  }

  Future<void> _pickImage(ImageSource source, String docType) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        _uploadFile(File(pickedFile.path), docType);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickFile(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        _uploadFile(File(result.files.single.path!), docType);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _uploadFile(File file, String docType) {
    if (_caseId != null) {
      context.read<DocumentsBloc>().add(
        DocumentUploadRequested(
          caseId: _caseId!,
          documentType: docType,
          file: file,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active case ID to upload documents to.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String applicantName = 'APPLICANT';
    if (authState is AuthAuthenticated) {
      applicantName = authState.user.fullName.toUpperCase();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MultiBlocListener(
        listeners: [
          BlocListener<CasesBloc, CasesState>(
            listener: (context, state) {
              if (state is CasesLoaded && state.cases.isNotEmpty && _caseId == null) {
                setState(() {
                  _caseId = state.cases.first.id;
                });
                context.read<CasesBloc>().add(CaseChecklistLoadRequested(_caseId!));
                context.read<DocumentsBloc>().add(DocumentsLoadRequested(_caseId!));
              }
            },
          ),
          BlocListener<DocumentsBloc, DocumentsState>(
            listener: (context, state) {
              if (state is DocumentUploading) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Uploading and validating document via AI...'),
                      ],
                    ),
                    duration: Duration(seconds: 30),
                  ),
                );
              }
              if (state is DocumentUploaded) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Document "${state.document.originalFilename}" uploaded successfully! Status: ${state.document.status}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                if (_caseId != null) {
                  context.read<CasesBloc>().add(CaseChecklistLoadRequested(_caseId!));
                }
              }
              if (state is DocumentsError) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload failed: ${state.message}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<CasesBloc, CasesState>(
          builder: (context, state) {
            if (state is CasesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CasesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load documents: ${state.message}', style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<CasesBloc>().add(CasesLoadRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            List<ChecklistItemModel> checklistItems = [];
            if (state is CaseChecklistLoaded) {
              checklistItems = state.items;
            } else if (_caseId != null) {
              // Trigger reload checklist if we have a case ID but aren't in loaded state
              return const Center(child: CircularProgressIndicator());
            } else {
              return const Center(child: Text('No active visa applications.'));
            }

            final docsState = context.watch<DocumentsBloc>().state;
            List<DocumentModel> uploadedDocs = [];
            if (docsState is DocumentsLoaded) {
              uploadedDocs = docsState.documents;
            } else if (docsState is DocumentsInitial && _caseId != null) {
              context.read<DocumentsBloc>().add(DocumentsLoadRequested(_caseId!));
            }

            final docs = _mapChecklistToDocs(checklistItems);
            final uploadedCount = docs.where((d) => d.status == _DocStatus.verified || d.status == _DocStatus.processing).length;
            final totalCount = docs.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            applicantName.isNotEmpty ? applicantName.substring(0, 2).toUpperCase() : 'AP',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('APPLICANT: $applicantName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                          const Text('Documents', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Progress Card ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant, width: 2),
                      boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Upload Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('$uploadedCount of $totalCount Uploaded', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalCount > 0 ? uploadedCount / totalCount : 0.0,
                            backgroundColor: AppColors.surfaceVariant,
                            color: AppColors.primary,
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── AI Verification Banner ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed.withAlpha(76),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.tertiary, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Verification Active', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary, fontSize: 14)),
                              Text('All uploads are analyzed and validated instantly by the AI Agent.', style: TextStyle(fontSize: 12, color: AppColors.onSurface)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Required Documents', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                  const SizedBox(height: 12),

                  // ── Document Cards ───────────────────────────────────────────
                  ...docs.map((doc) {
                    DocumentModel? matchingDoc;
                    try {
                      matchingDoc = uploadedDocs.firstWhere((d) => d.documentType == doc.id);
                    } catch (_) {
                      matchingDoc = null;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DocCard(
                        doc: doc,
                        matchingDoc: matchingDoc,
                        onUpload: () => _showUploadSheet(context, doc),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Upload Bottom Sheet ──────────────────────────────────────────────
  void _showUploadSheet(BuildContext context, _Document doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Doc header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: doc.iconColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(doc.icon, color: doc.iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload ${doc.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          doc.subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'CHOOSE UPLOAD METHOD',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              _UploadOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                sublabel: 'Use your camera',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, doc.id);
                },
              ),
              const SizedBox(height: 10),
              _UploadOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                sublabel: 'JPG, PNG supported',
                color: AppColors.tertiary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, doc.id);
                },
              ),
              const SizedBox(height: 10),
              _UploadOption(
                icon: Icons.upload_file,
                label: 'Browse Files',
                sublabel: 'PDF, DOC, DOCX',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(doc.id);
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.onSurfaceVariant),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Files are encrypted and stored securely. Only your consultant can access them.',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Doc Card ─────────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final _Document doc;
  final DocumentModel? matchingDoc;
  final VoidCallback onUpload;
  const _DocCard({required this.doc, this.matchingDoc, required this.onUpload});

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusIcon, borderColor) = _statusInfo(doc.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [BoxShadow(color: borderColor, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: doc.iconColor.withAlpha(30), borderRadius: BorderRadius.circular(10)),
            child: Icon(doc.icon, color: doc.iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Title + subtitle — takes all remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface), overflow: TextOverflow.ellipsis)),
                    if (!doc.isRequired) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)), child: const Text('Optional', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)))
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  doc.subtitle,
                  style: TextStyle(fontSize: 12, color: doc.status == _DocStatus.error ? AppColors.error : AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (matchingDoc?.driveViewLink != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _launchURL(matchingDoc!.driveViewLink!),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'View on Drive',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Action widget — fixed, never expands
          _ActionWidget(status: doc.status, label: statusLabel, color: statusColor, icon: statusIcon, onUpload: onUpload),
        ],
      ),
    );
  }

  (String, Color, IconData, Color) _statusInfo(_DocStatus s) {
    return switch (s) {
      _DocStatus.verified => ('Verified', AppColors.primary, Icons.check_circle, AppColors.surfaceVariant),
      _DocStatus.processing => ('Processing', AppColors.tertiary, Icons.hourglass_top, AppColors.tertiary),
      _DocStatus.error => ('Re-upload', AppColors.error, Icons.error, AppColors.error),
      _DocStatus.pending => ('Upload', AppColors.primary, Icons.upload, AppColors.surfaceVariant),
      _DocStatus.optional => ('Add', AppColors.onSurfaceVariant, Icons.add, AppColors.surfaceVariant),
    };
  }
}

class _ActionWidget extends StatelessWidget {
  final _DocStatus status;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onUpload;
  const _ActionWidget({required this.status, required this.label, required this.color, required this.icon, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    if (status == _DocStatus.verified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    }
    if (status == _DocStatus.processing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.tertiary.withAlpha(20), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tertiary)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 0,
        ),
        onPressed: onUpload,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Upload Option Tile ────────────────────────────────────────────────
class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final VoidCallback onTap;
  const _UploadOption({required this.icon, required this.label, required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant, width: 2),
          boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onSurface)),
                  Text(sublabel, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
