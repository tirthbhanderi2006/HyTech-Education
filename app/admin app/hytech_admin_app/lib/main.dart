import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/home/bloc/admin_student_bloc.dart';
import 'features/appointments/bloc/meetings_bloc.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_dashboard.dart';

void main() {
  runApp(const VisaFlowAdminApp());
}

class VisaFlowAdminApp extends StatelessWidget {
  const VisaFlowAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Nunito — same rounded, bold typeface Duolingo uses
    final nunitoBase = GoogleFonts.nunitoTextTheme();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()..add(AuthCheckRequested())),
        BlocProvider<AdminStudentBloc>(create: (_) => AdminStudentBloc()),
        BlocProvider<MeetingsBloc>(create: (_) => MeetingsBloc()),
      ],
      child: MaterialApp(
        title: 'VisaFlow Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          // Apply Nunito globally to every Text widget
          textTheme: nunitoBase.copyWith(
            displayLarge:  GoogleFonts.nunito(fontWeight: FontWeight.w900),
            displayMedium: GoogleFonts.nunito(fontWeight: FontWeight.w900),
            displaySmall:  GoogleFonts.nunito(fontWeight: FontWeight.w900),
            headlineLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            headlineMedium:GoogleFonts.nunito(fontWeight: FontWeight.w800),
            headlineSmall: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            titleLarge:    GoogleFonts.nunito(fontWeight: FontWeight.w700),
            titleMedium:   GoogleFonts.nunito(fontWeight: FontWeight.w700),
            titleSmall:    GoogleFonts.nunito(fontWeight: FontWeight.w600),
            bodyLarge:     GoogleFonts.nunito(fontWeight: FontWeight.w600),
            bodyMedium:    GoogleFonts.nunito(fontWeight: FontWeight.w500),
            bodySmall:     GoogleFonts.nunito(fontWeight: FontWeight.w500),
            labelLarge:    GoogleFonts.nunito(fontWeight: FontWeight.w800),
            labelMedium:   GoogleFonts.nunito(fontWeight: FontWeight.w700),
            labelSmall:    GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.surface,
            elevation: 0,
            titleTextStyle: GoogleFonts.nunito(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
            iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.onSurfaceVariant,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        home: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is AuthAuthenticated) return const HomeDashboard();
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
