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


  static const tkoOrange = Color(0xFFFF6A00);
  static const tkoCream = Color(0xFFF7F2EC);
  static const tkoBrown = Color(0xFF6A3B1A);
  static const tkoTeal = Color(0xFF00B8A2);
  static const tkoGold = Color(0xFFFFD23F);

  late final TabController _tab = TabController(length: 2, vsync: this);


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
    return Scaffold(
      // base color under everything
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
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.96),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 80,
                        child: Image.asset(
                          'assets/branding/tko_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: loadingGoogle ? null : _google,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.black.withOpacity(.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: loadingGoogle
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata_rounded, size: 26),
                              SizedBox(width: 8),
                              Text('Sign in with Google'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          SizedBox(width: 8),
                          Text(
                            'or email',
                            style: TextStyle(color: Colors.black54),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tab,
                          indicator: BoxDecoration(
                            color: tkoOrange.withOpacity(.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: tkoBrown,
                          unselectedLabelColor: Colors.black54,
                          tabs: const [
                            Tab(text: 'Sign in'),
                            Tab(text: 'Sign up'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 330,
                        child: TabBarView(
                          controller: _tab,
                          children: [

                            Column(
                              children: [
                                _Field(
                                  label: 'Email',
                                  controller: inEmail,
                                  keyboard: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 10),
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
                                const SizedBox(height: 6),
                                _BrandButton(
                                  text: 'Continue',
                                  onPressed:
                                  loadingEmail ? null : _signInEmail,
                                ),
                              ],
                            ),

                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Field(
                                        label: 'First name',
                                        controller: firstName,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _Field(
                                        label: 'Last name',
                                        controller: lastName,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _Field(
                                  label: 'Email',
                                  controller: upEmail,
                                  keyboard: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 10),
                                _Field(
                                  label: 'Password (min 6)',
                                  controller: upPass1,
                                  obscure: true,
                                ),
                                const SizedBox(height: 10),
                                _Field(
                                  label: 'Confirm password',
                                  controller: upPass2,
                                  obscure: true,
                                ),
                                const SizedBox(height: 8),
                                _BrandButton(
                                  text: 'Create account',
                                  onPressed:
                                  loadingEmail ? null : _signUpEmail,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

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
        ],
      ),
    );
  }
}



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

      // Reuse Member 2's Firestore user doc helper
      await Member2EmailAuth._ensureUserDoc(result.user!);
    } catch (_) {
      showToast(
          'Google sign-in failed. Check SHA-1/256 & google-services.json.');
    } finally {
      setLoading(false);
    }
  }
}


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
          vertical: 14,
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
      height: 48,
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
