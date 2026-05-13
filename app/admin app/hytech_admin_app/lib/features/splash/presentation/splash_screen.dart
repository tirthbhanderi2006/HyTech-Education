import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../bloc/splash_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc()..add(SplashStarted()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashCompleted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryContainer,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primary,
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.flight_takeoff,
                      size: 40,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VisaFlow',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.surfaceContainerLowest,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your visa journey, simplified.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
