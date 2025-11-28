// lib/profile_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_page.dart';

const tkoOrange = Color(0xFFFF6A00);
const tkoCream = Color(0xFFF7F2EC);
const tkoBrown = Color(0xFF6A3B1A);
const tkoTeal = Color(0xFF00B8A2);
const tkoGold = Color(0xFFFFD23F);

class ProfileCardTab extends StatefulWidget {
  const ProfileCardTab({super.key});

  @override
  State<ProfileCardTab> createState() => _ProfileCardTabState();
}

class _ProfileCardTabState extends State<ProfileCardTab>
    with SingleTickerProviderStateMixin {
  bool _showFront = true;

  void _toggleSide() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  int _selectedFrontThemeIndex = 0;
  int _selectedBackThemeIndex = 0;

  final List<List<Color>> frontThemes = const [
    [Color(0xFF3B2A1A), Color(0xFF15100C)],
    [Color(0xFF006F7A), Color(0xFF021826)],
    [Color(0xFF542058), Color(0xFF160821)],
    [Color(0xFF7A3400), Color(0xFF1E0B00)],
    [Color(0xFF232733), Color(0xFF050608)],
  ];

  // Back card themes
  final List<List<Color>> backThemes = const [
    [Color(0xFFFFFFFF), Color(0xFFF2F2F2)],
    [Color(0xFF3A2C1F), Color(0xFF15110D)],
    [Color(0xFF00B8A2), Color(0xFF007F6C)],
    [Color(0xFFFF6A00), Color(0xFFB24A00)],
    [Color(0xFF8A2BE2), Color(0xFF4B0082)],
    [Color(0xFFFFC0CB), Color(0xFFFF69B4)],
    [Color(0xFF000000), Color(0xFF1A1A1A)],
  ];

  String? _displayName;
  String? _bio;
  String? _funFact;
  String? _birthday;
  String? _instagram;
  String? _discord;
  String? _xHandle;

  String? _avatarUrl;
  Uint8List? _avatarBytes;
  File? _avatarFile;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _funFactCtrl;
  late final TextEditingController _birthdayCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _discordCtrl;
  late final TextEditingController _xCtrl;

  final _picker = ImagePicker();
  bool _saving = false;

  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _funFactCtrl = TextEditingController();
    _birthdayCtrl = TextEditingController();
    _instagramCtrl = TextEditingController();
    _discordCtrl = TextEditingController();
    _xCtrl = TextEditingController();

    _loadFromAuth();
    _loadFromFirestore();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _funFactCtrl.dispose();
    _birthdayCtrl.dispose();
    _instagramCtrl.dispose();
    _discordCtrl.dispose();
    _xCtrl.dispose();
    super.dispose();
  }

  void _loadFromAuth() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    setState(() {
      _displayName = u.displayName ?? u.email?.split('@').first ?? 'Player';
      _avatarUrl = u.photoURL;
    });
  }

  Future<void> _loadFromFirestore() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final doc =
    await FirebaseFirestore.instance.doc('users/${u.uid}/profile/card').get();

    if (!doc.exists) return;

    final data = doc.data() ?? {};
    setState(() {
      _displayName = data['name'] ?? _displayName;
      _bio = data['bio'];
      _funFact = data['funFact'];
      _birthday = data['birthday'];
      _instagram = data['instagram'];
      _discord = data['discord'];
      _xHandle = data['xHandle'];

      // avatar base64
      final avatarBase64 = data['avatarBase64'];
      if (avatarBase64 is String && avatarBase64.isNotEmpty) {
        _avatarBytes = base64Decode(avatarBase64);
      }

      final frontIdx = data['frontThemeIndex'];
      final backIdx = data['backThemeIndex'];
      if (frontIdx is int && frontIdx >= 0 && frontIdx < frontThemes.length) {
        _selectedFrontThemeIndex = frontIdx;
      }
      if (backIdx is int && backIdx >= 0 && backIdx < backThemes.length) {
        _selectedBackThemeIndex = backIdx;
      }
    });
  }

  Future<void> _saveThemeIndexes() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await FirebaseFirestore.instance
        .doc('users/${u.uid}/profile/card')
        .set(
      {
        'frontThemeIndex': _selectedFrontThemeIndex,
        'backThemeIndex': _selectedBackThemeIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _saveAvatarToFirestore(Uint8List bytes) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final base64Str = base64Encode(bytes);

    await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
      {
        'avatarBase64': base64Str,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await FirebaseFirestore.instance
        .doc('users/${u.uid}/profile/card')
        .set(
      {
        'avatarBase64': base64Str,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _pickAvatar() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (xFile == null) return;

    final file = File(xFile.path);
    final bytes = await file.readAsBytes();

    setState(() {
      _avatarFile = file;
      _avatarBytes = bytes;
    });

    await _saveAvatarToFirestore(bytes);
  }

  void _cycleFrontTheme() {
    setState(() {
      _selectedFrontThemeIndex =
          (_selectedFrontThemeIndex + 1) % frontThemes.length;
    });
    _saveThemeIndexes();
  }

  void _cycleBackTheme() {
    setState(() {
      _selectedBackThemeIndex =
          (_selectedBackThemeIndex + 1) % backThemes.length;
    });
    _saveThemeIndexes();
  }

  void _openEditSheet() {
    final name = _displayName ?? '';
    _nameCtrl.text = name;
    _bioCtrl.text = _bio ?? '';
    _funFactCtrl.text = _funFact ?? '';
    _birthdayCtrl.text = _birthday ?? '';
    _instagramCtrl.text = _instagram ?? '';
    _discordCtrl.text = _discord ?? '';
    _xCtrl.text = _xHandle ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit player card',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: tkoCream,
                            image: _avatarFile != null
                                ? DecorationImage(
                              image: FileImage(_avatarFile!),
                              fit: BoxFit.cover,
                            )
                                : (_avatarBytes != null)
                                ? DecorationImage(
                              image: MemoryImage(_avatarBytes!),
                              fit: BoxFit.cover,
                            )
                                : (_avatarUrl != null &&
                                _avatarUrl!.trim().isNotEmpty)
                                ? DecorationImage(
                              image: NetworkImage(_avatarUrl!),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: (_avatarFile == null &&
                              _avatarBytes == null &&
                              (_avatarUrl == null ||
                                  _avatarUrl!.trim().isEmpty))
                              ? const Icon(Icons.camera_alt_outlined)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'About me',
                      hintText:
                      'What kind of trading buddy / deck tech are you?',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _funFactCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Fun fact',
                      hintText: 'Something fun, weird, or very TKO.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _birthdayCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Birthday',
                      hintText: 'DD / MM',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _instagramCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Instagram',
                      hintText: '@username',
                      prefixIcon: Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _discordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Discord',
                      hintText: 'User#0000 or invite link',
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _xCtrl,
                    decoration: const InputDecoration(
                      labelText: 'X / Twitter',
                      hintText: '@handle',
                      prefixIcon: Icon(Icons.alternate_email_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: tkoBrown,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    setState(() => _saving = true);

    final typedName = _nameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final funFact = _funFactCtrl.text.trim();
    final birthday = _birthdayCtrl.text.trim();
    final insta = _instagramCtrl.text.trim();
    final discord = _discordCtrl.text.trim();
    final x = _xCtrl.text.trim();

    final fallback =
        _displayName ?? u.displayName ?? u.email?.split('@').first ?? 'Player';
    final newDisplayName = typedName.isEmpty ? fallback : typedName;

    setState(() {
      _displayName = newDisplayName;
      _bio = bio.isEmpty ? null : bio;
      _funFact = funFact.isEmpty ? null : funFact;
      _birthday = birthday.isEmpty ? null : birthday;
      _instagram = insta.isEmpty ? null : insta;
      _discord = discord.isEmpty ? null : discord;
      _xHandle = x.isEmpty ? null : x;
    });

    try {
      await u.updateDisplayName(newDisplayName);

      String? avatarBase64;
      if (_avatarBytes != null) {
        avatarBase64 = base64Encode(_avatarBytes!);
      }

      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
        {
          'displayName': newDisplayName,
          if (avatarBase64 != null) 'avatarBase64': avatarBase64,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await FirebaseFirestore.instance
          .doc('users/${u.uid}/profile/card')
          .set(
        {
          'name': newDisplayName,
          'bio': _bio,
          'funFact': _funFact,
          'birthday': _birthday,
          'instagram': _instagram,
          'discord': _discord,
          'xHandle': _xHandle,
          if (avatarBase64 != null) 'avatarBase64': avatarBase64,
          'frontThemeIndex': _selectedFrontThemeIndex,
          'backThemeIndex': _selectedBackThemeIndex,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).maybePop();
    }
  }

  String? _handleToUrl(String? handle, String base) {
    if (handle == null || handle.trim().isEmpty) return null;
    final h = handle.trim();
    if (h.startsWith('http://') || h.startsWith('https://')) return h;
    final clean = h.startsWith('@') ? h.substring(1) : h;
    return '$base$clean';
  }

  String? _discordToUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://discord.com/users/${Uri.encodeComponent(v)}';
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Future<void> _captureAndShareCard() async {
    try {
      final boundary =
      _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card not rendered yet')),
          );
        }
        return;
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final pixelRatio = MediaQuery.of(context).devicePixelRatio * 2.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to encode image')),
          );
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tko_player_card.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'My TKO player card',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share card: $e')),
      );
    }
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final name =
        _displayName ?? FirebaseAuth.instance.currentUser?.email ?? 'Player';
    final initials = _initialsFromName(name);

    final instaUrl = _handleToUrl(_instagram, 'https://instagram.com/');
    final xUrl = _handleToUrl(_xHandle, 'https://x.com/');
    final discordUrl = _discordToUrl(_discord);

    // 🔹 SAME BACKGROUND AS MembershipQRPage
    return Stack(
      children: [
        // Gradient cream → white
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tkoCream,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
        // Soft halo in top-right
        Positioned(
          top: -80,
          right: -40,
          child: _softHalo(
            size: 180,
            color: tkoTeal.withValues(alpha: .45),
          ),
        ),

        // Page content
        Positioned.fill(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Top row
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tkoBrown.withValues(alpha: .85),
                          width: 1.3,
                        ),
                        color: Colors.white.withValues(alpha: .90),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tkoBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Player card',
                      style: TextStyle(
                        fontSize: 14,
                        color: tkoBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: tkoBrown,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsPage()),
                        );
                        _loadFromAuth();
                        await _loadFromFirestore();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        size: 20,
                        color: tkoBrown,
                      ),
                      onPressed: _captureAndShareCard,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth =
                      (constraints.maxWidth - 40).clamp(260.0, 420.0);
                      final cardHeight = cardWidth * 1.45;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _StripePainter(),
                            ),
                          ),
                          RepaintBoundary(
                            key: _cardKey,
                            child: SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: AnimatedSwitcher(
                                duration:
                                const Duration(milliseconds: 280),
                                transitionBuilder: (child, animation) {
                                  final fade = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  );
                                  final scale = Tween<double>(
                                    begin: 0.96,
                                    end: 1.0,
                                  ).animate(fade);

                                  return FadeTransition(
                                    opacity: fade,
                                    child: ScaleTransition(
                                      scale: scale,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _showFront
                                    ? _buildFrontCard(
                                    context, instaUrl, discordUrl, xUrl)
                                    : _buildBackCard(context, initials),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF101010), Color(0xFF050505)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: _openEditSheet,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit card',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      heroTag: 'flipCardFab',
                      onPressed: _toggleSide,
                      backgroundColor: tkoTeal,
                      child: const Icon(
                        Icons.autorenew_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrontCard(
      BuildContext context,
      String? instaUrl,
      String? discordUrl,
      String? xUrl,
      ) {
    final theme = Theme.of(context);
    final name = _displayName?.isNotEmpty == true ? _displayName! : 'Player';
    final initials = _initialsFromName(name);
    final colors = frontThemes[_selectedFrontThemeIndex];

    return GestureDetector(
      onTap: _cycleFrontTheme,
      child: AnimatedContainer(
        key: const ValueKey(true),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, 18),
              blurRadius: 40,
            ),
          ],
          border: Border.all(
            color: tkoGold,
            width: 1.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .9),
                      width: 1.4,
                    ),
                    color: Colors.black.withValues(alpha: .35),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.local_cafe_outlined,
                    size: 16, color: tkoGold),
                const SizedBox(width: 4),
                const Icon(Icons.videogame_asset_outlined,
                    size: 16, color: tkoGold),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_avatarFile != null)
                      Image.file(_avatarFile!, fit: BoxFit.cover)
                    else if (_avatarBytes != null)
                      Image.memory(_avatarBytes!, fit: BoxFit.cover)
                    else if ((_avatarUrl ?? '').isNotEmpty)
                        Image.network(_avatarUrl!, fit: BoxFit.cover)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                tkoTeal,
                                Color(0xFF3B82F6),
                                tkoOrange,
                              ],
                            ),
                          ),
                        ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: .25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoLine(
              icon: Icons.radio_button_checked,
              label: 'About me',
              value: _bio?.isNotEmpty == true
                  ? _bio!
                  : 'Tell people what kind of trading buddy you are.',
            ),
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.bolt_outlined,
              label: 'Fun fact',
              value: _funFact?.isNotEmpty == true
                  ? _funFact!
                  : 'Drop something fun, weird, or very TKO.',
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: .12), height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _PillIconText(
                  icon: Icons.cake_outlined,
                  label:
                  _birthday?.isNotEmpty == true ? _birthday! : 'Birthday',
                  onTap: () {
                    if (_birthday?.isNotEmpty == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Birthday: ${_birthday!}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      _openEditSheet();
                    }
                  },
                ),
                _PillIconText(
                  icon: Icons.camera_alt_outlined,
                  label: _instagram?.isNotEmpty == true
                      ? (_instagram!.startsWith('@')
                      ? _instagram!
                      : '@$_instagram')
                      : 'Instagram',
                  onTap:
                  instaUrl == null ? null : () => _launchExternal(instaUrl),
                ),
                _PillIconText(
                  icon: Icons.chat_bubble_outline,
                  label:
                  _discord?.isNotEmpty == true ? _discord! : 'Discord',
                  onTap: discordUrl == null
                      ? null
                      : () => _launchExternal(discordUrl),
                ),
                _PillIconText(
                  icon: Icons.alternate_email_outlined,
                  label: _xHandle?.isNotEmpty == true
                      ? _xHandle!
                      : 'X / Twitter',
                  onTap: xUrl == null ? null : () => _launchExternal(xUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(BuildContext context, String initials) {
    final colors = backThemes[_selectedBackThemeIndex];
    final bool isWhiteTheme = _selectedBackThemeIndex == 0;

    return GestureDetector(
      onTap: _cycleBackTheme,
      child: Container(
        key: const ValueKey(false),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, 18),
              blurRadius: 40,
            ),
          ],
          border: Border.all(
            color: tkoGold,
            width: 1.8,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(
                  painter: _BackWavePainter(),
                ),
              ),
            ),
            Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: isWhiteTheme ? Colors.black12 : Colors.white24,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: tkoGold.withValues(alpha: .9),
                    width: 1.2,
                  ),
                ),
                child: const Text(
                  'TKO TOY CO.',
                  style: TextStyle(
                    color: tkoGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Text(
                'TKO Loyalty Player Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isWhiteTheme
                      ? Colors.black.withValues(alpha: .55)
                      : Colors.white.withValues(alpha: .6),
                  fontSize: 11,
                  letterSpacing: .6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tkoGold),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PillIconText extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PillIconText({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: .06),
            border: Border.all(
              color: Colors.white.withValues(alpha: .18),
              width: 0.7,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: tkoGold),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .04)
      ..strokeWidth = 1;

    const step = 28.0;
    for (double i = -size.height; i < size.width + size.height; i += step) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x66FFFFFF),
          Color(0x00000000),
        ],
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.05,
        size.width * 0.7,
        size.height * 0.25,
      )
      ..quadraticBezierTo(
        size.width * 0.95,
        size.height * 0.45,
        size.width * 0.8,
        size.height,
      )
      ..lineTo(size.width * 0.2, size.height)
      ..quadraticBezierTo(
        size.width * 0.05,
        size.height * 0.6,
        size.width * 0.1,
        0.2 * size.height,
      )
      ..close();

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🔸 Same helper as MembershipQRPage
Widget _softHalo({required double size, required Color color}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .10),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .40),
          blurRadius: size * 0.6,
          spreadRadius: size * 0.18,
        ),
      ],
    ),
  );
}