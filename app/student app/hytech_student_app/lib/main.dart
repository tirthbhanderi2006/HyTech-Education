import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/student_home.dart';

void main() {
  runApp(const VisaFlowStudentApp());
}

class VisaFlowStudentApp extends StatelessWidget {
  const VisaFlowStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final nunitoBase = GoogleFonts.nunitoTextTheme();

    return BlocProvider(
      create: (_) => AuthBloc(),
      child: MaterialApp(
        title: 'VisaFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
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
            if (state is AuthAuthenticated) return const StudentHome();
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
