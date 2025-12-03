import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class PaymentPage extends StatelessWidget {
  final double amount;

  const PaymentPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Choose a payment method",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600
                )
            ),

            const SizedBox(height: 20),

            _PaymentOption(
              icon: Icons.account_balance_wallet_rounded,
              label: "PayPal (Demo)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const _SuccessPage(method: "PayPal")),
                );
              },
            ),

            const SizedBox(height: 12),

            _PaymentOption(
              icon: Icons.credit_card_rounded,
              label: "Credit / Debit Card",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _CardPaymentPage(amount: amount),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _PaymentOption(
              icon: Icons.apple_rounded,
              label: "Apple Pay (Demo)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const _SuccessPage(method: "Apple Pay")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CardPaymentPage extends StatelessWidget {
  final double amount;

  const _CardPaymentPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Card Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(decoration: InputDecoration(labelText: "Card Number")),
            TextField(decoration: InputDecoration(labelText: "Expiry (MM/YY)")),
            TextField(decoration: InputDecoration(labelText: "CVV")),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                      const _SuccessPage(method: "Card Payment")),
                );
              },
              child: Text("Pay \$${amount.toStringAsFixed(2)}"),
            )
          ],
        ),
      ),
    );
  }
}

class _SuccessPage extends StatelessWidget {
  final String method;

  const _SuccessPage({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Payment Successful!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text("Paid via $method", style: GoogleFonts.poppins()),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
