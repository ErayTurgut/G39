import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Kimlik ve mail için şart

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = true;
  
  Package? _lifetimePkg; 
  Package? _monthlyPkg;
  Package? _sixMonthPkg;
  Package? _annualPkg;

  bool _isBeatMasterUnlocked = false;
  bool _isProUnlocked = false;

  @override
  void initState() {
    super.initState();
    _fetchRevenueCatData();
  }

  // 🔥 YENİ: Panelde UID + Mail + İsim görünmesini sağlayan fonksiyon
  Future<void> _ensureUserIdentified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. UID ile giriş yap
        await Purchases.logIn(user.uid);
        
        // 2. Panelde mail ve isim görünmesi için öznitelikleri set et
        await Purchases.setEmail(user.email ?? "");
        await Purchases.setDisplayName(user.displayName ?? "İsimsiz Kullanıcı");
        
        debugPrint("G39 - Kimlik ve Detaylar Bildirildi: ${user.email}");
      }
    } catch (e) {
      debugPrint("G39 - Kimlik Hatası: $e");
    }
  }

  Future<void> _fetchRevenueCatData() async {
    try {
      // Verileri çekmeden önce kimliği tazele
      await _ensureUserIdentified();

      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateEntitlementStatus(customerInfo);

      Offerings offerings = await Purchases.getOfferings();
      
      debugPrint("======== G39 REVENUECAT DÜKKAN ANALİZİ ========");
      
      if (offerings.current != null) {
        debugPrint("Aktif Vitrin ID: ${offerings.current!.identifier}");
        
        _lifetimePkg = null;
        _monthlyPkg = null;
        _sixMonthPkg = null;
        _annualPkg = null;

        for (var p in offerings.current!.availablePackages) {
          debugPrint("--- Paket Bulundu ---");
          debugPrint("ID: ${p.identifier} | Tip: ${p.packageType} | Ürün: ${p.storeProduct.identifier}");

          if (p.packageType == PackageType.lifetime) _lifetimePkg = p;
          if (p.packageType == PackageType.monthly) _monthlyPkg = p;
          if (p.packageType == PackageType.sixMonth) _sixMonthPkg = p;
          if (p.packageType == PackageType.annual) _annualPkg = p;

          if (p.storeProduct.identifier == "g39_beep" || p.identifier.contains("beep")) {
            _lifetimePkg = p;
            debugPrint("✅ ZAFER: Beep paketi manuel olarak eşleştirildi!");
          }
        }
      } else {
        debugPrint("❌ HATA: Aktif bir Offering (Vitrin) bulunamadı!");
      }
      debugPrint("===============================================");
      
    } catch (e) {
      debugPrint("G39 RC Yükleme Hatası: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateEntitlementStatus(CustomerInfo customerInfo) {
    if (mounted) {
      setState(() {
        _isBeatMasterUnlocked = customerInfo.entitlements.all["Beat Master"]?.isActive ?? false;
        _isProUnlocked = customerInfo.entitlements.all["G39 Pro"]?.isActive ?? false;
      });
    }
  }

  Future<void> _purchasePackage(Package? package) async {
    if (package == null) return;
    
    setState(() => _isLoading = true);
    try {
      // 🔥 EKLENDİ: Ödeme anında kimlik ve detayları tekrar çak
      await _ensureUserIdentified();

      PurchaseResult purchaseResult = await Purchases.purchasePackage(package);
      _updateEntitlementStatus(purchaseResult.customerInfo);
      
      if (mounted) {
        _showSuccessSnackBar(context, "İşlem Başarılı! Premium özellikler açıldı.");
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Satın alma hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      // 🔥 EKLENDİ: Geri yüklemede kimlik ve detayları çak
      await _ensureUserIdentified();

      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateEntitlementStatus(customerInfo);
      if (mounted) _showSuccessSnackBar(context, "Satın alımlar geri yüklendi.");
    } catch (e) {
      debugPrint("Geri yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // Arka plan blur efekti (Tasarımına Dokunulmadı)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.1),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text("G39 PRO ACCESS", style: TextStyle(color: Colors.white12, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(width: 48),
                  ],
                ),

                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                    : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Icon(Icons.bolt_rounded, size: 54, color: Color(0xFF3B82F6)),
                        const SizedBox(height: 12),
                        const Text(
                          "SINIRLARI KALDIR",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Gelişimini pro verilerle mühürle.",
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 32),

                        if (_lifetimePkg != null) ...[
                          _sectionTitle("KİŞİSELLEŞTİR"),
                          _buildLifetimeCard(
                            title: "BEAT MASTER",
                            price: _lifetimePkg!.storeProduct.priceString, 
                            desc: "Özel sesler ve sınırsız kişiselleştirme.",
                            isUnlocked: _isBeatMasterUnlocked,
                            onTap: () => _purchasePackage(_lifetimePkg),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (_monthlyPkg != null || _sixMonthPkg != null || _annualPkg != null) ...[
                          _sectionTitle("PRO ANALİZ PAKETİ"),

                          if (_monthlyPkg != null) ...[
                            _buildSubRow(
                              title: "Aylık Paket",
                              price: _monthlyPkg!.storeProduct.priceString, 
                              unit: "Tüm grafikler ve analizler",
                              isBest: false,
                              isUnlocked: _isProUnlocked,
                              onTap: () => _purchasePackage(_monthlyPkg),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (_sixMonthPkg != null) ...[
                            _buildSubRow(
                              title: "6 Aylık Gelişim",
                              price: _sixMonthPkg!.storeProduct.priceString, 
                              unit: "En popüler orta vadeli çözüm",
                              isBest: true,
                              badge: "EN POPÜLER",
                              isUnlocked: _isProUnlocked,
                              onTap: () => _purchasePackage(_sixMonthPkg),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (_annualPkg != null) ...[
                            _buildSubRow(
                              title: "Yıllık Master",
                              price: _annualPkg!.storeProduct.priceString, 
                              unit: "Yıllık tek ödeme ile %50 kâr",
                              isBest: true,
                              badge: "%50 TASARRUF",
                              color: Colors.greenAccent,
                              isUnlocked: _isProUnlocked,
                              onTap: () => _purchasePackage(_annualPkg),
                            ),
                          ],
                        ],

                        const SizedBox(height: 40),

                        TextButton(
                          onPressed: _restorePurchases,
                          child: const Text(
                            "Satın Almaları Geri Yükle",
                            style: TextStyle(color: Colors.white24, decoration: TextDecoration.underline, fontSize: 11),
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
        ],
      ),
    );
  }

  // --- UI YARDIMCI METOTLARI (Kodun Kalan 200 Satırı Aynen Duruyor) ---

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildLifetimeCard({required String title, required String price, required String desc, required bool isUnlocked, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: isUnlocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF101826),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isUnlocked ? Colors.greenAccent.withOpacity(0.2) : Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.greenAccent.withOpacity(0.1) : const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isUnlocked ? "AÇIK" : price,
                style: TextStyle(color: isUnlocked ? Colors.greenAccent : Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubRow({
    required String title,
    required String price,
    required String unit,
    required bool isBest,
    required bool isUnlocked,
    String? badge,
    Color color = const Color(0xFF3B82F6),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isUnlocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isBest ? const Color(0xFF161B22) : const Color(0xFF101826),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isUnlocked ? Colors.greenAccent.withOpacity(0.4) : (isBest ? color.withOpacity(0.4) : Colors.white10), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (badge != null && !isUnlocked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                          child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(isUnlocked ? "Sınırsız Erişim Açık" : unit, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Text(isUnlocked ? "AÇIK" : price, style: TextStyle(color: isUnlocked ? Colors.greenAccent : Colors.white, fontSize: isUnlocked ? 14 : 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}