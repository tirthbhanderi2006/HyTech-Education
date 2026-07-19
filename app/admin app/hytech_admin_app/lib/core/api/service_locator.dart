// Drop this in your main.dart MultiBlocProvider to wire everything up.
//
// Example main.dart usage:
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(
//     MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (_) => AuthBloc()..add(AuthCheckRequested())),
//         BlocProvider(create: (_) => CasesBloc()),
//         BlocProvider(create: (_) => DocumentsBloc()),
//         BlocProvider(create: (_) => NotificationsBloc()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }
//
// Each BLoC is independent. Dispatch events like:
//   context.read<AuthBloc>().add(AuthLoginRequested(email, password));
//   context.read<CasesBloc>().add(CasesLoadRequested());
//   context.read<DocumentsBloc>().add(DocumentUploadRequested(caseId: ..., documentType: ..., file: ...));
//   context.read<NotificationsBloc>().add(NotificationsLoadRequested());
