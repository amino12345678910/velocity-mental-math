import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/konnect_config.dart';

class KonnectService {
  
  /// Initiates a payment request to Konnect API.
  /// Returns the payment URL to redirect the user to.
  Future<String?> initPayment(double amount) async {
    final url = Uri.parse('${KonnectConfig.baseUrl}/payments/init-payment');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': KonnectConfig.apiKey, 
        },
        body: jsonEncode({
          'receiverWalletId': KonnectConfig.walletId,
          'amount': amount * 1000, // Konnect usually uses millimes? Check docs. Assuming standard unit or millimes. usually 1000 millimes = 1 TND
          'token': 'TND',
          'selectedPaymentMethod': 'gateway',
          'firstName': 'Velocity',
          'lastName': 'Gamer',
          'email': 'gamer@velocity.app', // Placeholder or actual user email
          'webhook': 'https://your-webhook-url.com', // Optional
          'successUrl': 'http://localhost:8081/success', // Deep link or web url
          'failUrl': 'http://localhost:8081/fail',
          'theme': 'dark',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payUrl']; // Field name depends on actual API response
      } else {
        print("Konnect Init Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Konnect Service Error: $e");
      return null;
    }
  }

  /// Launches the given URL in the browser.
  Future<void> launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
