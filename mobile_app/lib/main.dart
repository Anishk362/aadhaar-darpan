import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

void main() {
  runApp(const AadhaarDarpanApp());
}

class AadhaarDarpanApp extends StatelessWidget {
  const AadhaarDarpanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aadhaar Darpan | RGIPT Intel',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700), // Cyber Gold
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? metadata;
  Map<String, dynamic>? auditData;
  Map<String, dynamic>? heatmapData;
  String? selectedState;
  String? selectedDistrict;
  bool isLoading = false;

  final String baseUrl = "http://127.0.0.1:5001/api";

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
    _fetchHeatmap();
  }

  // --- API LOGIC (UNCHANGED) ---
  Future<void> _fetchMetadata() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/metadata')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() { metadata = json.decode(response.body)['metadata']; });
      }
    } catch (e) { _showSnackbar("Engine Offline: Connect to RGIPT Central."); }
  }

  Future<void> _fetchHeatmap() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/heatmap'));
      if (response.statusCode == 200) {
        setState(() { heatmapData = json.decode(response.body)['data']; });
      }
    } catch (e) { debugPrint("Heatmap Error: $e"); }
  }

  Future<void> _fetchAuditReport() async {
    if (selectedState == null) return;
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('$baseUrl/audit?state=$selectedState&district=${selectedDistrict ?? ""}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() => auditData = json.decode(response.body));
      }
    } catch (e) { _showSnackbar("Neural Link Error: Data Desync."); }
    finally { setState(() => isLoading = false); }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFFF8C00),
      behavior: Brightness.dark == Brightness.dark ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            Text("AADHAAR DARPAN", style: GoogleFonts.spaceGrotesk(letterSpacing: 5, fontWeight: FontWeight.w900, color: Colors.white)),
            Text("RGIPT NATIONAL INTELLIGENCE UNIT", style: GoogleFonts.orbitron(fontSize: 8, color: const Color(0xFFFFD700), letterSpacing: 1.5)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black26))),
        actions: [IconButton(icon: const Icon(Icons.blur_on_rounded, color: Color(0xFFFFD700)), onPressed: _fetchHeatmap)],
      ),
      body: Stack(
        children: [
          // THE "MIDNIGHT PETROLEUM" GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000808), // Deepest Petrol
                  Color(0xFF001F1F), // RGIPT Teal
                  Color(0xFF0A0A0A), // Pure Dark
                ],
              ),
            ),
          ),
          // DYNAMIC DATA-WIRE OVERLAY
          Opacity(
            opacity: 0.05,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 12),
              itemBuilder: (context, index) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 0.2))),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildGlassCard(_buildSelectionFields(), accent: const Color(0xFFFFD700)),
                  const SizedBox(height: 24),
                  if (isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Color(0xFFFFD700))))
                  else if (auditData != null)
                    _buildReportView()
                  else
                    _buildHomeScreen(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(Widget child, {Color accent = Colors.white12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: accent.withOpacity(0.2), width: 1.2),
            boxShadow: [BoxShadow(color: accent.withOpacity(0.03), blurRadius: 20)],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSelectionFields() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          dropdownColor: const Color(0xFF001A1A),
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: _inputStyle("DATA HUB: SELECT ENTITY", Icons.hub_outlined),
          value: selectedState,
          items: metadata?.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) {
            setState(() { selectedState = val; selectedDistrict = null; auditData = null; _fetchAuditReport(); });
          },
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          dropdownColor: const Color(0xFF001A1A),
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: _inputStyle("REGIONAL DRILLDOWN", Icons.query_stats_rounded),
          value: selectedDistrict,
          items: selectedState == null ? [] : (metadata![selectedState] as List).map((d) => DropdownMenuItem(value: d.toString(), child: Text(d.toString()))).toList(),
          onChanged: (val) { setState(() { selectedDistrict = val; _fetchAuditReport(); }); },
        ),
      ],
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: GoogleFonts.orbitron(color: Colors.white30, fontSize: 8, letterSpacing: 1.5),
      prefixIcon: Icon(icon, color: const Color(0xFFFFD700), size: 20),
      filled: true, fillColor: Colors.black38,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildHomeScreen() {
    if (heatmapData == null) return const Center(child: Text("Initializing Neural Heatmap...", style: TextStyle(color: Colors.white24, letterSpacing: 3)));
    return Column(
      children: [
        Text("NATIONAL THREAT PULSE", style: GoogleFonts.orbitron(letterSpacing: 6, fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        SizedBox(
          height: 380,
          child: SimpleMap(
            instructions: SMapIndia.instructions,
            defaultColor: Colors.white.withOpacity(0.05),
            colors: _generateCyberMapColors(),
            callback: (id, name, taparea) {
              setState(() { selectedState = name.toUpperCase(); selectedDistrict = null; _fetchAuditReport(); });
            },
          ),
        ),
        const SizedBox(height: 25),
        _buildLegend(),
      ],
    );
  }

  Map<String, Color> _generateCyberMapColors() {
    Map<String, Color> colors = {};
    heatmapData?.forEach((state, details) {
      String status = details['status'];
      // CYBER PUNK STATUS COLORS
      colors[state] = status == "SAFE" 
          ? const Color(0xFF00FFC2).withOpacity(0.6) 
          : (status == "WARNING" ? Colors.white.withOpacity(0.6) : const Color(0xFFFF0055));
    });
    return colors;
  }

  Widget _buildLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _legendNode("CRITICAL", const Color(0xFFFF0055)), const SizedBox(width: 25),
      _legendNode("WARNING", Colors.white60), const SizedBox(width: 25),
      _legendNode("SECURE", const Color(0xFF00FFC2)),
    ]);
  }

  Widget _legendNode(String label, Color color) {
    return Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 10)])),
      const SizedBox(width: 8), Text(label, style: GoogleFonts.orbitron(fontSize: 8, color: Colors.white30)),
    ]);
  }

  Widget _buildReportView() {
    final cards = auditData!['cards'];
    final forecast = List<dynamic>.from(cards['efficiency']['biometric_traffic_trend']);
    final double modelAccuracy = (cards['efficiency']['accuracy'] ?? 94.2).toDouble();

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 1000),
          childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 80.0, child: FadeInAnimation(child: widget)),
          children: [
            _buildSectionHeader("PILLAR I: GENERATION SATURATION", Icons.radar),
            const SizedBox(height: 12),
            _buildGlassCard(SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: [
                PieChartSectionData(value: (cards['inclusivity']['value'] * 100).toDouble(), color: const Color(0xFFFFD700), title: "YOUTH", radius: 75, titleStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                PieChartSectionData(value: (100 - (cards['inclusivity']['value'] * 100)).toDouble(), color: Colors.white.withOpacity(0.05), title: "", radius: 60),
              ], centerSpaceRadius: 40)),
            ), accent: const Color(0xFFFFD700)),
            const SizedBox(height: 24),
            _buildSectionHeader("PILLAR II: ACCESS & RISK ANALYSIS", Icons.verified_user_rounded),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildStatusTile("VELOCITY", "${cards['security']['value']}%", cards['security']['status'])),
              const SizedBox(width: 15),
              Expanded(child: _buildStatusTile("INCLUSIVITY", cards['inclusivity']['status'], cards['inclusivity']['status'])),
            ]),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("PILLAR III: 90-DAY FORECAST", Icons.analytics_rounded),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFFD700), width: 0.5), borderRadius: BorderRadius.circular(8)),
                  child: Text("CONFIDENCE: $modelAccuracy%", style: GoogleFonts.robotoMono(fontSize: 9, color: const Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGlassCard(Column(
              children: [
                SizedBox(
                  height: 160,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (forecast.last as num).toDouble() * 1.5,
                    barGroups: List.generate(3, (i) => BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: (forecast[i] as num).toDouble(), 
                        color: const Color(0xFFFFD700), 
                        width: 40, 
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: (forecast.last as num).toDouble() * 1.5, color: Colors.white.withOpacity(0.02))
                      )
                    ])),
                    titlesData: const FlTitlesData(show: false), gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
                  )),
                ),
                const SizedBox(height: 10),
                Text("NEURAL TREND DETECTED: ${cards['efficiency']['trend']}", style: GoogleFonts.orbitron(fontSize: 8, color: Colors.white24, letterSpacing: 2)),
              ],
            ), accent: const Color(0xFFFFD700)),
            const SizedBox(height: 35),
            _buildRGIPTFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildRGIPTFooter() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => auditData = null), 
          icon: const Icon(Icons.keyboard_backspace_rounded, color: Color(0xFFFFD700), size: 16), 
          label: Text("BACK TO NATIONAL OVERVIEW", style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold))
        ),
        const SizedBox(height: 20),
        Text("OFFICIAL PROJECT | RGIPT UNIT", style: GoogleFonts.orbitron(fontSize: 7, color: Colors.white10, letterSpacing: 3)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 18, color: const Color(0xFFFFD700)),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w800, letterSpacing: 2)),
    ]);
  }

  Widget _buildStatusTile(String title, String val, String status) {
    Color col = status == "SAFE" ? const Color(0xFF00FFC2) : (status == "WARNING" ? Colors.white70 : const Color(0xFFFF0055));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: col.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: col.withOpacity(0.01), blurRadius: 15)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.orbitron(fontSize: 7, color: Colors.white24)),
          const SizedBox(height: 8),
          Text(val, style: GoogleFonts.robotoMono(fontSize: 22, fontWeight: FontWeight.bold, color: col, shadows: [Shadow(color: col.withOpacity(0.4), blurRadius: 10)])),
        ],
      ),
    );
  }
}