import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
              // BOŞLUK - LOGO VE YAZILAR TAMAMEN KALDIRILDI
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

              // APPLE LOGIN
              _buildAuthButton(
                context: context,
                text: "Apple ID ile Giriş Yap",
                icon: Icons.apple,
                color: Colors.black,
                textColor: Colors.white,
                onTap: () => debugPrint("🍎 Apple yakında..."),
              ),
            ],
          ),
        ),
      ),
    );
  }

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