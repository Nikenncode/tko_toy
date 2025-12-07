import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage>
    with SingleTickerProviderStateMixin {
  // Brand colors
  static const tkoOrange = Color(0xFFFF6A00);
  static const tkoCream = Color(0xFFF7F2EC);
  static const tkoBrown = Color(0xFF6A3B1A);
  static const tkoTeal = Color(0xFF00B8A2);
  static const tkoGold = Color(0xFFFFD23F);

  late final TabController _tab;
  int _currentTab = 0;

  final inEmail = TextEditingController();
  final inPass = TextEditingController();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final upEmail = TextEditingController();
  final upPass1 = TextEditingController();
  final upPass2 = TextEditingController();

  bool loadingEmail = false;
  bool loadingGoogle = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) return;
      setState(() {
        _currentTab = _tab.index;
      });
    });
  }

  Future<void> _signInEmail() async {
    await Member2EmailAuth.signInEmail(
      auth: FirebaseAuth.instance,
      emailCtrl: inEmail,
      passCtrl: inPass,
      showToast: _toast,
      setLoading: (value) {
        if (!mounted) return;
        setState(() => loadingEmail = value);
      },
    );
  }

  Future<void> _forgotPassword() async {
    await Member2EmailAuth.forgotPassword(
      auth: FirebaseAuth.instance,
      emailCtrl: inEmail,
      showToast: _toast,
    );
  }

  Future<void> _signUpEmail() async {
    await Member2EmailAuth.signUpEmail(
      auth: FirebaseAuth.instance,
      firstNameCtrl: firstName,
      lastNameCtrl: lastName,
      emailCtrl: upEmail,
      pass1Ctrl: upPass1,
      pass2Ctrl: upPass2,
      showToast: _toast,
      setLoading: (value) {
        if (!mounted) return;
        setState(() => loadingEmail = value);
      },
    );
  }

  Future<void> _google() async {
    await Member1GoogleAuth.signInWithGoogle(
      showToast: _toast,
      setLoading: (value) {
        if (!mounted) return;
        setState(() => loadingGoogle = value);
      },
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    inEmail.dispose();
    inPass.dispose();
    firstName.dispose();
    lastName.dispose();
    upEmail.dispose();
    upPass1.dispose();
    upPass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _currentTab == 0;

    return Scaffold(
      backgroundColor: tkoCream,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/branding/tko_cross_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400), // MEDIUM WIDTH
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_currentTab),
                  tween: Tween(begin: 0.97, end: 1.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.97),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 1.2,
                        color: isSignIn
                            ? tkoOrange.withOpacity(.5)
                            : tkoTeal.withOpacity(.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSignIn ? tkoOrange : tkoTeal)
                              .withOpacity(0.18),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                        const BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        SizedBox(
                          height: 64,
                          child: Image.asset(
                            'assets/branding/tko_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Small pill + animated subtitle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.03),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSignIn
                                        ? Icons.login_rounded
                                        : Icons.stars_rounded,
                                    size: 14,
                                    color: isSignIn ? tkoBrown : tkoTeal,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isSignIn
                                        ? 'Welcome back'
                                        : 'Create your profile',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black.withOpacity(.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: Text(
                            isSignIn
                                ? 'Sign in to your TKO account'
                                : 'Sign up to join TKO Toy',
                            key: ValueKey(isSignIn),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Google button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: loadingGoogle ? null : _google,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.black.withOpacity(.14),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: loadingGoogle
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.g_mobiledata_rounded, size: 24),
                                SizedBox(width: 8),
                                Text('Continue with Google'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Divider
                        Row(
                          children: const [
                            Expanded(
                              child: Divider(
                                color: Colors.black,
                                thickness: 1.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'or email',
                              style: TextStyle(color: Colors.black87),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                color: Colors.black,
                                thickness: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        const SizedBox(height: 10),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(16),

                          ),

                          child: TabBar(
                            controller: _tab,

                            indicatorSize: TabBarIndicatorSize.tab,

                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: isSignIn
                                    ? [tkoOrange.withOpacity(.22), tkoGold.withOpacity(.85)]
                                    : [tkoTeal.withOpacity(.22), tkoTeal],
                              ),
                            ),

                            labelColor: Colors.black,            // selected text color
                            unselectedLabelColor: Colors.black54, // non-selected tab text

                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),

                            tabs: const [
                              Tab(text: "Sign in"),
                              Tab(text: "Sign up"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          height: 290,
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              // SIGN IN
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Field(
                                    label: 'Email',
                                    controller: inEmail,
                                    keyboard: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 8),
                                  _Field(
                                    label: 'Password',
                                    controller: inPass,
                                    obscure: true,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: tkoBrown,
                                      ),
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _BrandButton(
                                    text: 'Continue',
                                    onPressed:
                                    loadingEmail ? null : _signInEmail,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'New here? ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _tab.animateTo(1),
                                        child: const Text(
                                          'Create an account',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: tkoBrown,
                                            decoration:
                                            TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // SIGN UP
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _Field(
                                          label: 'First name',
                                          controller: firstName,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _Field(
                                          label: 'Last name',
                                          controller: lastName,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _Field(
                                    label: 'Email',
                                    controller: upEmail,
                                    keyboard: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 8),
                                  _Field(
                                    label: 'Password (min 6)',
                                    controller: upPass1,
                                    obscure: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _Field(
                                    label: 'Confirm password',
                                    controller: upPass2,
                                    obscure: true,
                                  ),
                                  const SizedBox(height: 6),
                                  _BrandButton(
                                    text: 'Create account',
                                    onPressed:
                                    loadingEmail ? null : _signUpEmail,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _tab.animateTo(0),
                                        child: const Text(
                                          'Sign in',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: tkoBrown,
                                            decoration:
                                            TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          'By continuing you agree to TKO’s Terms & Privacy.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
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

/// ---------------- AUTH HELPERS ----------------

class Member2EmailAuth {
  static Future<void> _ensureUserDoc(User user,
      {String? first, String? last}) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'displayName':
        user.displayName ?? '${first ?? ''} ${last ?? ''}'.trim(),
        'firstName': first ?? '',
        'lastName': last ?? '',
        'photoURL': user.photoURL ?? '',
        'yearPoints': 0,
        'lifetimePts': 0,
        'tier': 'Featherweight',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  static Future<void> signInEmail({
    required FirebaseAuth auth,
    required TextEditingController emailCtrl,
    required TextEditingController passCtrl,
    required void Function(String) showToast,
    required void Function(bool) setLoading,
  }) async {
    final e = emailCtrl.text.trim();
    final p = passCtrl.text.trim();
    if (e.isEmpty || p.isEmpty) {
      showToast('Enter email & password');
      return;
    }

    setLoading(true);
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: e,
        password: p,
      );
      await _ensureUserDoc(cred.user!);
    } on FirebaseAuthException catch (ex) {
      showToast(ex.message ?? 'Sign in failed');
    } finally {
      setLoading(false);
    }
  }

  static Future<void> forgotPassword({
    required FirebaseAuth auth,
    required TextEditingController emailCtrl,
    required void Function(String) showToast,
  }) async {
    final e = emailCtrl.text.trim();
    if (e.isEmpty) {
      showToast('Enter your email first');
      return;
    }
    try {
      await auth.sendPasswordResetEmail(email: e);
      showToast('Reset link sent to $e');
    } on FirebaseAuthException catch (ex) {
      showToast(ex.message ?? 'Could not send reset link');
    }
  }

  static Future<void> signUpEmail({
    required FirebaseAuth auth,
    required TextEditingController firstNameCtrl,
    required TextEditingController lastNameCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController pass1Ctrl,
    required TextEditingController pass2Ctrl,
    required void Function(String) showToast,
    required void Function(bool) setLoading,
  }) async {
    final first = firstNameCtrl.text.trim();
    final last = lastNameCtrl.text.trim();
    final e = emailCtrl.text.trim();
    final p1 = pass1Ctrl.text.trim();
    final p2 = pass2Ctrl.text.trim();

    if ([first, last, e, p1, p2].any((s) => s.isEmpty)) {
      showToast('Fill all fields');
      return;
    }
    if (p1.length < 6) {
      showToast('Password must be at least 6 characters');
      return;
    }
    if (p1 != p2) {
      showToast('Passwords do not match');
      return;
    }

    setLoading(true);
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: e,
        password: p1,
      );
      await _ensureUserDoc(cred.user!, first: first, last: last);
    } on FirebaseAuthException catch (ex) {
      showToast(ex.message ?? 'Sign up failed');
    } finally {
      setLoading(false);
    }
  }
}

class Member1GoogleAuth {
  static Future<void> signInWithGoogle({
    required void Function(String) showToast,
    required void Function(bool) setLoading,
  }) async {
    setLoading(true);
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        setLoading(false);
        return;
      }
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      final result =
      await FirebaseAuth.instance.signInWithCredential(cred);

      await Member2EmailAuth._ensureUserDoc(result.user!);
    } catch (_) {
      showToast(
          'Google sign-in failed. Check SHA-1/256 & google-services.json.');
    } finally {
      setLoading(false);
    }
  }
}

/// ---------------- SMALL WIDGETS ----------------

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;

  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.black.withOpacity(.035),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _BrandButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _BrandButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _LoginSignupPageState.tkoOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
