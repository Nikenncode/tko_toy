import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart' show AuthGate;


const tkoOrange = Color(0xFFFF6A00);
const tkoCream = Color(0xFFF7F2EC);
const tkoBrown = Color(0xFF6A3B1A);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _name;
  String? _email;
  Uint8List? _avatarBytes;
  bool _pushEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    String display = u.displayName ?? u.email?.split('@').first ?? 'Player';
    bool push = true;
    Uint8List? avatarBytes;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final data = doc.data();
      if (data != null) {
        display = (data['displayName'] as String?) ?? display;

        // 👇 match profile_page.dart: avatarBase64 stored in users/{uid}
        final avatarBase64 = data['avatarBase64'];
        if (avatarBase64 is String && avatarBase64.isNotEmpty) {
          avatarBytes = base64Decode(avatarBase64);
        }

        push = (data['pushEnabled'] as bool?) ?? true;
      }
    } catch (_) {
    }

    if (!mounted) return;
    setState(() {
      _name = display;
      _email = u.email;
      _avatarBytes = avatarBytes;
      _pushEnabled = push;
      _loading = false;
    });
  }

  String _initials(String from) {
    final parts = from.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _togglePush(bool value) async {
    setState(() => _pushEnabled = value);

    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
        {
          'pushEnabled': value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _pushEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update notification setting'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not log out: $e')),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
    );
  }

  void _openFaqs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FAQs coming soon'),
      ),
    );
  }

  Future<void> _openWhatsapp() async {
    // TODO: change to your real number
    final uri = Uri.parse('https://wa.me/1234567890');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  Future<void> _openChangePasswordSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final pass1 = TextEditingController();
        final pass2 = TextEditingController();
        bool saving = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              final p1 = pass1.text.trim();
              final p2 = pass2.text.trim();

              if (p1.isEmpty || p2.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fill both password fields'),
                  ),
                );
                return;
              }
              if (p1.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                    Text('Password must be at least 6 characters long'),
                  ),
                );
                return;
              }
              if (p1 != p2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                  ),
                );
                return;
              }

              setSheetState(() => saving = true);

              try {
                final u = FirebaseAuth.instance.currentUser;
                if (u == null) {
                  throw Exception('Not signed in');
                }

                await u.updatePassword(p1);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated'),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.message ??
                            'Could not change password. You may need to log in again.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not change password: $e'),
                    ),
                  );
                }
              } finally {
                if (ctx.mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pass1,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pass2,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      style: FilledButton.styleFrom(
                        backgroundColor: tkoBrown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'SAVE',
                        style: TextStyle(
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPersonalInfoPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
    );
    // Reload user (name, email, avatarBase64) when coming back
    await _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final name = _name ?? 'Player';
    final email = _email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // USER CARD
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: tkoCream,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : null,
                      child: _avatarBytes == null
                          ? Text(
                        _initials(name),
                        style: const TextStyle(
                          color: tkoBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.person_outline,
                      title: 'User Profile',
                      onTap: _openPersonalInfoPage,
                    ),
                    _SettingTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: _openChangePasswordSheet,
                    ),
                    _SettingTile(
                      icon: Icons.help_outline,
                      title: 'FAQs',
                      onTap: _openFaqs,
                    ),
                    _SettingSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notification',
                      value: _pushEnabled,
                      onChanged: _togglePush,
                    ),

                    const SizedBox(height: 18),

                    // SUPPORT / WHATSAPP BOX
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'If you have any other query you can reach out to us.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _openWhatsapp,
                            child: const Text(
                              'WhatsApp Us',
                              style: TextStyle(
                                color: tkoOrange,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LOGOUT BUTTON
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Log out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple row tile with right arrow
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: tkoBrown),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black38,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Row tile with a Switch
class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: tkoBrown),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: tkoOrange,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// PERSONAL INFO PAGE (same as before, only text details)
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    String first = '';
    String last = '';
    String phone = '';

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final data = doc.data();
      if (data != null) {
        first = (data['firstName'] as String?) ?? '';
        last = (data['lastName'] as String?) ?? '';
        phone = (data['phone'] as String?) ?? '';
      }
    } catch (_) {}

    if (first.isEmpty && last.isEmpty) {
      final dn = u.displayName ?? '';
      final parts = dn.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        first = parts.first;
        if (parts.length > 1) {
          last = parts.sublist(1).join(' ');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _first.text = first;
      _last.text = last;
      _email.text = u.email ?? '';
      _phone.text = phone;
    });
  }

  Future<void> _save() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final first = _first.text.trim();
    final last = _last.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final displayName =
      (first.isNotEmpty || last.isNotEmpty) ? '$first $last'.trim() : null;

      if (displayName != null && displayName.isNotEmpty) {
        await u.updateDisplayName(displayName);
      }
      if (email != u.email && email.isNotEmpty) {
        await u.updateEmail(email);
      }

      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
        {
          'firstName': first,
          'lastName': last,
          'displayName': displayName ?? u.displayName,
          'phone': phone,
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not update profile')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              // Just text fields, avatar is handled by profile card
              _RoundedTextField(
                controller: _first,
                label: 'First Name',
              ),
              const SizedBox(height: 12),
              _RoundedTextField(
                controller: _last,
                label: 'Last Name',
              ),
              const SizedBox(height: 12),
              _RoundedTextField(
                controller: _email,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _RoundedTextField(
                controller: _phone,
                label: 'Mobile',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: tkoBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'SAVE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _RoundedTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: tkoOrange,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
