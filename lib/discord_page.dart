import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_page.dart';

class DiscordScreen extends StatelessWidget {
  const DiscordScreen({super.key});

  final String discordUrl = "https://discord.com/invite/M8HZwrdjp7";

  Future<void> _launchDiscord() async {
    final Uri url = Uri.parse("https://discord.com/invite/M8HZwrdjp7");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open Discord link");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: TkoBottomNav(
        index: -1,
        onChanged: (newIndex) {
          if (newIndex == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: true,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            "Join Our Community",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Connect | Chat | Compete!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5865F2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Join the official TKO Toy Co. Discord community and stay updated with live events, exclusive drops, and connect with other collectors!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),

            Image.asset(
              'assets/branding/discord_logo.png',
              height: 150,
            ),
            const SizedBox(height: 30),

            Text(
              "Discord",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchDiscord,
                icon: Image.asset(
                  'assets/branding/discord_icon.png',
                  height: 28,
                ),
                label: Text(
                  "Join our Discord Server",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5865F2),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Be part of the TKO community — where collectors become champions!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
