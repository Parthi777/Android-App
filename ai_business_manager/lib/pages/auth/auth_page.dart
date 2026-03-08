import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with TickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _pulseController;
  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late Animation<double> _pulseAnim;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _orb1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _orb2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final authService = ref.read(authServiceProvider);
    final enabled = await authService.isBiometricLoginEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (user != null && mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleBiometricAuth() async {
    final authService = ref.read(authServiceProvider);
    final authenticated = await authService.authenticateWithBiometrics();

    if (authenticated && mounted) {
      // Check if we have a current user (Firebase session)
      if (authService.currentUser != null) {
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Session expired. Please sign in with Google once.',
            ),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-bleed gradient background ──────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F4FF),
                  Color(0xFFE8EEFF),
                  Color(0xFFF5F0FF),
                ],
              ),
            ),
          ),

          // ── Animated floating orb 1 (top-right) ─────────────────
          AnimatedBuilder(
            animation: _orb1Controller,
            builder: (_, __) {
              final t = _orb1Controller.value;
              final x = size.width * 0.6 + 40 * math.sin(t * 2 * math.pi);
              final y = size.height * 0.08 + 30 * math.cos(t * 2 * math.pi);
              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7B52AB).withOpacity(0.18),
                        const Color(0xFF7B52AB).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Animated floating orb 2 (bottom-left) ───────────────
          AnimatedBuilder(
            animation: _orb2Controller,
            builder: (_, __) {
              final t = _orb2Controller.value;
              final x = -60 + 35 * math.sin(t * 2 * math.pi + math.pi / 3);
              final y =
                  size.height * 0.65 +
                  25 * math.cos(t * 2 * math.pi + math.pi / 3);
              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1E88E5).withOpacity(0.14),
                        const Color(0xFF1E88E5).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Secondary orb (center accent) ────────────────────────
          Positioned(
            left: size.width * 0.1,
            top: size.height * 0.25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00BCD4).withOpacity(0.1),
                    const Color(0xFF00BCD4).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // ── Logo / Icon ───────────────────────────
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B52AB), Color(0xFF1E88E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B52AB).withOpacity(0.4),
                                blurRadius: 28,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── App name ─────────────────────────────
                      const Text(
                        'Dhaara',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          color: Color(0xFF1A1340),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF7B52AB), Color(0xFF1E88E5)],
                        ).createShader(bounds),
                        child: const Text(
                          'AI Business Manager',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Multi-branch intelligence. One dashboard.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 44),

                      // ── Glassmorphic card ─────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white.withOpacity(0.70),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B52AB).withOpacity(0.08),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 20,
                              spreadRadius: -5,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card header
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1340),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue to your workspace',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 32),

                            const SizedBox(height: 24),
                            // ── Row of Attractive Icon-Only Buttons ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ── Google Login Icon Button ────────
                                _loading
                                    ? Container(
                                        width: 64,
                                        height: 64,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF7B52AB),
                                              Color(0xFF1E88E5),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: _handleGoogleSignIn,
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Image.network(
                                            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                const SizedBox(width: 24),
                                // ── Biometric Icon Button ───────────
                                GestureDetector(
                                  onTap: _biometricEnabled
                                      ? _handleBiometricAuth
                                      : () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Enable biometrics by logging in with Google once.',
                                              ),
                                              backgroundColor: const Color(
                                                0xFF7B52AB,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        },
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: _biometricEnabled
                                            ? [
                                                const Color(0xFF7B52AB),
                                                const Color(0xFF1E88E5),
                                              ]
                                            : [
                                                Colors.grey[300]!,
                                                Colors.grey[400]!,
                                              ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (_biometricEnabled
                                                      ? const Color(0xFF7B52AB)
                                                      : Colors.black)
                                                  .withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Feature pills ───────────────────────────
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _FeaturePill(
                            icon: Icons.insights,
                            label: 'Analytics',
                          ),
                          _FeaturePill(
                            icon: Icons.inventory_2_outlined,
                            label: 'Stock',
                          ),
                          _FeaturePill(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Finance',
                          ),
                          _FeaturePill(
                            icon: Icons.store_outlined,
                            label: 'Multi-Branch',
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // ── Footer ─────────────────────────────────
                      Text(
                        'By signing in, you agree to our Terms & Privacy Policy',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature pill chip ────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color(0xFF7B52AB).withOpacity(0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7B52AB)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D2C6E),
            ),
          ),
        ],
      ),
    );
  }
}
