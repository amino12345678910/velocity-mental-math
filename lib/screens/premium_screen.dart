import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/konnect_service.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import '../config/konnect_config.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_button.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;

  Future<void> _buyPremium() async {
    setState(() => _isLoading = true);
    
    final konnect = KonnectService();
    final payUrl = await konnect.initPayment(KonnectConfig.premiumPrice); 

    if (payUrl != null) {
      await konnect.launchPaymentUrl(payUrl);
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to payment...")));
      }
    } else {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Init Failed. Check Console.")));
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _sandboxGrant() async {
     await SocialService().grantPremium();
     if(mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("UNLIMITED ACCESS"), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.star, size: 80, color: Colors.amber)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 1.seconds)
                          .rotate(begin: -0.1, end: 0.1),
                      const SizedBox(height: 24),
                      Text(
                        "PREMIUM\nSTATUS",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "• Unlimited Online Duels\n• No Wait Times\n• Exclusive Badge\n• Support Development",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                       _isLoading 
                        ? const CircularProgressIndicator(color: AppTheme.primary)
                        : NeonButton(
                            text: "UNLOCK NOW (${KonnectConfig.premiumPrice} TND)",
                            onPressed: _buyPremium,
                            color: Colors.amber,
                          ).animate().shimmer(delay: 1.seconds, duration: 2.seconds),
                    ],
                  ),
                ).animate().slideY(begin: 0.5, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: _sandboxGrant, 
                  child: const Text("Restore Purchases / [DEV] Grant", style: TextStyle(color: Colors.white30, fontSize: 12)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
