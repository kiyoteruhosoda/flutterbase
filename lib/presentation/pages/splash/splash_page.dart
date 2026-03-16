import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/app_router.dart';
import '../../../presentation/viewmodels/splash_viewmodel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// スプラッシュページ
///
/// アプリ起動時に表示されます。
/// 初期化完了後にメインページへ遷移します。
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Start initialization after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashViewModelProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    ref.listen(splashViewModelProvider, (prev, next) {
      if (next.status == SplashStatus.done) {
        context.go(AppRoutes.main);
      }
    });

    final splashState = ref.watch(splashViewModelProvider);

    return Scaffold(
      backgroundColor:
          isLight ? AppColors.bgBrandLight : AppColors.bgBrandDark,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.onPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.apps_rounded,
                    size: 56,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // App title
                Text(
                  'Flutterbase',
                  style: AppTextStyles.stdXlBold.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'デジタル庁デザインシステム',
                  style: AppTextStyles.dnsLgNormal.copyWith(
                    color: scheme.onPrimary.withAlpha(200),
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),

                // Loading indicator or error
                if (splashState.status == SplashStatus.loading) ...[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onPrimary,
                    ),
                  ),
                ] else if (splashState.status == SplashStatus.error) ...[
                  Icon(
                    Icons.error_outline,
                    size: 32,
                    color: scheme.onPrimary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    splashState.errorMessage ?? 'エラーが発生しました',
                    style: AppTextStyles.dnsSmNormal.copyWith(
                      color: scheme.onPrimary.withAlpha(200),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () =>
                        ref.read(splashViewModelProvider.notifier).initialize(),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onPrimary,
                    ),
                    child: Text(
                      '再試行',
                      style: AppTextStyles.olnMdBold.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
