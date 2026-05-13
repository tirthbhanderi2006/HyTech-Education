import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── Document model — swap `uploadedPath` with real File/URL later ────
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
  // Mutable list so status can change after "upload"
  final List<_Document> _docs = [
    const _Document(id: 'passport', title: 'Passport', subtitle: 'Front & back scan', icon: Icons.book, iconColor: AppColors.primary, status: _DocStatus.verified),
    const _Document(id: 'ielts', title: 'IELTS Scorecard', subtitle: 'Official PDF copy', icon: Icons.school, iconColor: AppColors.tertiary, status: _DocStatus.processing),
    const _Document(id: 'degree', title: 'Degree Certificate', subtitle: 'Image blurry — please re-upload', icon: Icons.workspace_premium, iconColor: AppColors.error, status: _DocStatus.error),
    const _Document(id: 'bank', title: 'Bank Statements', subtitle: 'Last 6 months', icon: Icons.account_balance, iconColor: AppColors.onSurfaceVariant, status: _DocStatus.pending),
    const _Document(id: 'lor', title: 'Letter of Recommendation', subtitle: 'Boosts your application', icon: Icons.mail_outline, iconColor: AppColors.secondary, status: _DocStatus.optional, isRequired: false),
    const _Document(id: 'photo', title: 'Passport-size Photo', subtitle: 'White background, recent', icon: Icons.face, iconColor: AppColors.onSurfaceVariant, status: _DocStatus.pending),
  ];

  // Simulate upload for a doc by id (in future, call actual file upload API here)
  void _simulateUpload(String docId) {
    setState(() {
      final idx = _docs.indexWhere((d) => d.id == docId);
      if (idx != -1) {
        _docs[idx] = _Document(
          id: _docs[idx].id,
          title: _docs[idx].title,
          subtitle: 'Uploaded — awaiting AI verification',
          icon: _docs[idx].icon,
          iconColor: AppColors.tertiary,
          status: _DocStatus.processing,
          isRequired: _docs[idx].isRequired,
        );
      }
    });
  }

  int get _uploadedCount => _docs.where((d) => d.status == _DocStatus.verified || d.status == _DocStatus.processing).length;
  int get _totalCount => _docs.length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(width: 52, height: 52, decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle), child: const Center(child: Text('RS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)))),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('APPLICANT: RAHUL S.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                  Text('Documents', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
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
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Upload Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$_uploadedCount of $_totalCount Uploaded', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _uploadedCount / _totalCount,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                  minHeight: 10,
                ),
              ),
            ]),
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
            child: Row(children: [
              Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Verification Active', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary, fontSize: 14)),
                Text('Verifying IELTS Scorecard — usually takes a few minutes.', style: TextStyle(fontSize: 12, color: AppColors.onSurface)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          const Text('Required Documents', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 12),

          // ── Document Cards ───────────────────────────────────────────
          ..._docs.map((doc) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DocCard(
              doc: doc,
              onUpload: () => _showUploadSheet(context, doc),
            ),
          )),
        ],
      ),
    );
  }

  // ── Upload Bottom Sheet ──────────────────────────────────────────────
  void _showUploadSheet(BuildContext context, _Document doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,   // lets sheet grow taller than 50% if needed
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        // Add keyboard padding so content isn't clipped when keyboard opens
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Doc header
              Row(children: [
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
              ]),
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
                onTap: () { Navigator.pop(context); _simulateUpload(doc.id); },
              ),
              const SizedBox(height: 10),
              _UploadOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                sublabel: 'JPG, PNG supported',
                color: AppColors.tertiary,
                onTap: () { Navigator.pop(context); _simulateUpload(doc.id); },
              ),
              const SizedBox(height: 10),
              _UploadOption(
                icon: Icons.upload_file,
                label: 'Browse Files',
                sublabel: 'PDF, DOC, DOCX',
                color: AppColors.primary,
                onTap: () { Navigator.pop(context); _simulateUpload(doc.id); },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: const Row(children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.onSurfaceVariant),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Files are encrypted and stored securely. Only your consultant can access them.',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ]),
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
  final VoidCallback onUpload;
  const _DocCard({required this.doc, required this.onUpload});

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
            width: 46, height: 46,
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
                Row(children: [
                  Flexible(child: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface), overflow: TextOverflow.ellipsis)),
                  if (!doc.isRequired) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)), child: const Text('Optional', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)))],
                ]),
                const SizedBox(height: 3),
                Text(
                  doc.subtitle,
                  style: TextStyle(fontSize: 12, color: doc.status == _DocStatus.error ? AppColors.error : AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
      _DocStatus.verified    => ('Verified',   AppColors.primary,          Icons.check_circle,  AppColors.surfaceVariant),
      _DocStatus.processing  => ('Processing', AppColors.tertiary,          Icons.hourglass_top, AppColors.tertiary),
      _DocStatus.error       => ('Re-upload',  AppColors.error,             Icons.error,         AppColors.error),
      _DocStatus.pending     => ('Upload',     AppColors.primary,           Icons.upload,        AppColors.surfaceVariant),
      _DocStatus.optional    => ('Add',        AppColors.onSurfaceVariant,  Icons.add,           AppColors.surfaceVariant),
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
    // ── Read-only badges (no tap) ──────────────────────────────────
    if (status == _DocStatus.verified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
        ]),
      );
    }
    if (status == _DocStatus.processing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.tertiary.withAlpha(20), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tertiary)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 11)),
        ]),
      );
    }

    // ── Tappable upload button — constrained width prevents overflow ──
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
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onSurface)),
            Text(sublabel, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ]),
      ),
    );
  }
}
