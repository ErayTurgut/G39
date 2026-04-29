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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. GÖRSEL KİMLİK
                const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  "G39 PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const Text(
                  "Kendi Limitlerini Zorla",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 60),

                /* // 🚧 ANDROID / GOOGLE LOGIN - GEÇİCİ OLARAK KALDIRILDI
                _buildAuthButton(
                  context: context,
                  text: "Google ile Devam Et",
                  icon: Icons.login_rounded, 
                  color: Colors.white,
                  textColor: Colors.black,
                  onTap: () async {
                    try {
                      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                      if (googleUser != null) {
                        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                        final AuthCredential credential = GoogleAuthProvider.credential(
                          accessToken: googleAuth.accessToken,
                          idToken: googleAuth.idToken,
                        );
                        await FirebaseAuth.instance.signInWithCredential(credential);
                        await IsarService.saveUser(googleUser.displayName ?? "Sporcu", googleUser.email);
                      }
                    } catch (e) {
                      debugPrint("Google Login Error: $e");
                    }
                  },
                ),
                const SizedBox(height: 16),
                */

                // 2. APPLE LOGIN (Tek ve Resmi Giriş Yöntemi)
                SignInWithAppleButton(
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
                        await IsarService.saveUser(
                          userCredential.user!.displayName ?? "Apple Kullanıcısı",
                          userCredential.user!.email ?? ""
                        );
                      }
                    } catch (e) {
                      debugPrint("Apple Login Error: $e");
                    }
                  },
                  style: SignInWithAppleButtonStyle.white, 
                  height: 55,
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                ),
                
                const SizedBox(height: 40),
                
                // 3. GİZLİLİK VE ŞARTLAR
                TextButton(
                  onPressed: () async {
                    final Uri url = Uri.parse('https://sites.google.com/view/g39pro/ana-sayfa'); 
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      debugPrint('Link error: $url');
                    }
                  },
                  child: const Text(
                    "Gizlilik Politikası ve Kullanım Şartları",
                    textAlign: TextAlign.center,
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
      ),
    );
  }

  // Google Butonu Widget'ı (Kullanılmadığı için burada durabilir ya da silebilirsin)
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
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}