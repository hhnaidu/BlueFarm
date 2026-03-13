import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../theme/legacy_theme.dart';
import '../widgets/animated_bg.dart';
import '../widgets/bounce_button.dart';
import 'main_shell.dart';

class FarmerInfoScreen extends StatefulWidget {
  final String phone;
  const FarmerInfoScreen({super.key, required this.phone});

  @override
  State<FarmerInfoScreen> createState() => _FarmerInfoScreenState();
}

class _FarmerInfoScreenState extends State<FarmerInfoScreen>
    with TickerProviderStateMixin {
  final farmerCtrl = TextEditingController();
  final farmCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final pondCtrl = TextEditingController();
  String? primaryFish;
  bool _detecting = false;

  late AnimationController _entryCtrl;

  final _fish = ["Rohu", "Catla", "Tilapia", "Pangasius", "Shrimp"];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    farmerCtrl.dispose();
    farmCtrl.dispose();
    pinCtrl.dispose();
    addressCtrl.dispose();
    pondCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fad(int i) {
    final s = (i * 0.08).clamp(0.0, 0.7);
    final e = (s + 0.35).clamp(0.0, 1.0);
    return Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(s, e, curve: Curves.easeOutCubic),
      ),
    );
  }

  Animation<Offset> _sld(int i) {
    final s = (i * 0.08).clamp(0.0, 0.7);
    final e = (s + 0.35).clamp(0.0, 1.0);
    return Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(s, e, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _detectPin() async {
    final pin = pinCtrl.text.trim();
    if (pin.length != 6) return;
    try {
      final res = await http
          .get(Uri.parse("https://api.postalpincode.in/pincode/$pin"));
      final data = jsonDecode(res.body);
      if (data[0]["Status"] == "Success") {
        final post = data[0]["PostOffice"][0];
        setState(() {
          addressCtrl.text = "${post["District"]}, ${post["State"]}, India";
        });
      }
    } catch (_) {}
  }

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    try {
      await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition();
      final url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}";
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      if (mounted) {
        setState(() => addressCtrl.text = data["display_name"]);
      }
    } catch (_) {}
    if (mounted) setState(() => _detecting = false);
  }

  Widget _field(int i, String hint, TextEditingController c,
      {Function(String)? onChange,
      TextInputType? keyboardType,
      int maxLines = 1,
      Widget? prefix}) {
    return FadeTransition(
      opacity: _fad(i),
      child: SlideTransition(
        position: _sld(i),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: c,
            onChanged: onChange,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefix,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("Your Farm")),
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fad(0),
                      child: const Text(
                        "Tell us about your farm",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeTransition(
                      opacity: _fad(0),
                      child: const Text(
                        "We'll help you monitor it better",
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _field(1, "Farmer Name", farmerCtrl,
                        prefix: const Icon(Icons.person_outline_rounded,
                            color: AppTheme.textSecondary)),
                    _field(2, "Farm Name", farmCtrl,
                        prefix: const Icon(Icons.agriculture_rounded,
                            color: AppTheme.textSecondary)),
                    _field(3, widget.phone, TextEditingController(),
                        prefix: const Icon(Icons.phone_rounded,
                            color: AppTheme.textSecondary)),
                    _field(4, "PIN Code", pinCtrl,
                        keyboardType: TextInputType.number,
                        onChange: (v) {
                          if (v.length == 6) _detectPin();
                        },
                        prefix: const Icon(Icons.pin_drop_rounded,
                            color: AppTheme.textSecondary)),

                    // Detect location
                    FadeTransition(
                      opacity: _fad(5),
                      child: SlideTransition(
                        position: _sld(5),
                        child: BounceButton(
                          onPressed: _detectLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: AppTheme.purpleGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonPurple
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _detecting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.my_location_rounded,
                                        color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  "Detect Farm Location",
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

                    const SizedBox(height: 16),

                    _field(6, "Detected address (editable)", addressCtrl,
                        maxLines: 2,
                        prefix: const Icon(Icons.location_on_rounded,
                            color: AppTheme.textSecondary)),
                    _field(7, "Pond Size (acres)", pondCtrl,
                        keyboardType: TextInputType.number,
                        prefix: const Icon(Icons.water_rounded,
                            color: AppTheme.textSecondary)),

                    // Fish dropdown
                    FadeTransition(
                      opacity: _fad(8),
                      child: SlideTransition(
                        position: _sld(8),
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          hint: const Text("Primary Fish Species",
                              style: TextStyle(color: AppTheme.textSecondary)),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.set_meal_rounded,
                                color: AppTheme.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          items: _fish
                              .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => primaryFish = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Next button
                    FadeTransition(
                      opacity: _fad(9),
                      child: SlideTransition(
                        position: _sld(9),
                        child: BounceButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 700),
                                pageBuilder: (_, __, ___) => const MainShell(),
                                transitionsBuilder: (_, anim, __, child) {
                                  return FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(
                                      scale: Tween(begin: 0.95, end: 1.0)
                                          .animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonBlue
                                      .withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "Enter BlueFarm →",
                                style: TextStyle(
                                  color: AppTheme.deepOcean,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}