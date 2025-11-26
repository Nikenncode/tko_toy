// lib/membership_qr_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

const tkoOrange = Color(0xFFFF6A00);
const tkoCream  = Color(0xFFF7F2EC);
const tkoBrown  = Color(0xFF6A3B1A);
const tkoTeal   = Color(0xFF00B8A2);
const tkoGold   = Color(0xFFFFD23F);

class MembershipQRPage extends StatelessWidget {
  const MembershipQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name =
        user?.displayName ?? (user?.email?.split('@').first ?? 'Member');
    final uid = user?.uid ?? 'guest';
    final memberId =
    uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase();
    final code = 'TKO:$uid';

    return Stack(
      children: [
        // Background similar to HomePage: cream → white + soft halo
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
        Positioned(
          top: -80,
          right: -40,
          child: _softHalo(
            size: 180,
            color: tkoTeal.withValues(alpha: .45),
          ),
        ),

        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),

                    // Section pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: .05),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: tkoBrown,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Membership',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tkoBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Title + helper copy
                    Text(
                      "$name's Membership",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: tkoBrown,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Show this pass at checkout to earn or redeem your TKO points.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // LUXE QR CARD
                    _MembershipCard(
                      code: code,
                      memberId: memberId,
                      name: name,
                    ),

                    const SizedBox(height: 24),

                    // Small reassurance / info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: tkoTeal,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Your QR is unique and securely linked to your account.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bright, eye-catchy QR card with teal / orange gradient frame
class _MembershipCard extends StatelessWidget {
  final String code;
  final String memberId;
  final String name;

  const _MembershipCard({
    required this.code,
    required this.memberId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 360;

    return Container(
      padding: const EdgeInsets.all(2.6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tkoTeal,
            tkoGold,
            tkoOrange,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFFDF7F0), // soft warm cream
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: brand + status chip
            Row(
              children: [
                const Text(
                  'TKO LOYALTY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: tkoBrown,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.stars_rounded,
                        size: 14,
                        color: tkoTeal,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: tkoBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Name & ID
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 17 : 19,
                fontWeight: FontWeight.w800,
                color: tkoBrown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Member ID: $memberId',
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 18),

            // QR block with glow + subtle gradient halo
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x2200B8A2),
                      Color(0x22FF6A00),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x25000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: code,
                    size: isCompact ? 160 : 185,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider line
            Opacity(
              opacity: 0.5,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0x33000000),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bottom info chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _InfoChip(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan at checkout',
                ),
                _InfoChip(
                  icon: Icons.stars_rounded,
                  label: 'Earn & redeem',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: tkoTeal,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: tkoBrown,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

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
