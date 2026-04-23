import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../services/isar_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // GOOGLE LOGIN
              _buildAuthButton(
                context: context,
                text: "Google ile Devam Et",
                icon: Icons.g_mobiledata_rounded,
                color: Colors.white,
                textColor: Colors.black,
                onTap: () async {
                  try {
                    debugPrint("🚀 [G39 LOGIN] Başlatılıyor...");
                    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                    
                    if (googleUser != null) {
                      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                      final AuthCredential credential = GoogleAuthProvider.credential(
                        accessToken: googleAuth.accessToken,
                        idToken: googleAuth.idToken,
                      );

                      await FirebaseAuth.instance.signInWithCredential(credential);
                      debugPrint("🔥 [GİRİŞ BAŞARILI]");
                      
                      await IsarService.saveUser(
                        googleUser.displayName ?? "Sporcu", 
                        googleUser.email
                      );
                    }
                  } catch (e) {
                    debugPrint("❌ G39 LOGIN HATASI: $e");
                  }
                },
              ),

              const SizedBox(height: 15),

              // APPLE LOGIN - RESMİ APPLE BUTONU
              SignInWithAppleButton(
                text: "Apple ile Giriş Yap", 
                height: 50,
                borderRadius: BorderRadius.circular(15),
                onPressed: () async {
                  try {
                    final appleCredential = await SignInWithApple.getAppleIDCredential(
                      scopes: [
                        AppleIDAuthorizationScopes.email,
                        AppleIDAuthorizationScopes.fullName,
                      ],
                    );

                    final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
                    final AuthCredential credential = oAuthProvider.credential(
                      idToken: appleCredential.identityToken,
                      accessToken: appleCredential.authorizationCode,
                    );

                    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                    
                    if (userCredential.user != null) {
                      debugPrint("🍎 [APPLE GİRİŞ BAŞARILI]");
                      await IsarService.saveUser(
                        userCredential.user!.displayName ?? "Apple Kullanıcısı",
                        userCredential.user!.email ?? ""
                      );
                    }
                  } catch (e) {
                    debugPrint("❌ APPLE LOGIN HATASI: $e");
                  }
                },
              ),
              
              const SizedBox(height: 25),
              
              // GİZLİLİK POLİTİKASI LİNKİ
              TextButton(
                onPressed: () async {
                  final Uri url = Uri.parse('https://sites.google.com/view/g39pro/ana-sayfa'); 
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    debugPrint('Hata: Link açılamadı $url');
                  }
                },
                child: const Text(
                  "Gizlilik Politikası ve Kullanım Şartları",
                  style: TextStyle(
                    color: Colors.grey, 
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Google Butonu için yardımcı widget
  Widget _buildAuthButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}