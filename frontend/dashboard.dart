import 'package:flutter/material.dart';
import 'api.dart';
import 'models.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<JournalEntry> allEntries = [];
  Map<String, int> emotionCounts = {};
  Map<String, int> themeCounts = {};
  List<String> recentEmotions = [];
  bool isLoading = true;
  String dominantEmotion = "--";
  String topTheme = "--";
  String volatility = "--";
  String trend = "--";

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final entries = await ApiService.getEntries();
    
    Map<String, int> eCounts = {};
    Map<String, int> tCounts = {};
    List<String> timeline = [];

    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (var entry in entries) {
      if (entry.analysis != null) {
        for (var e in entry.analysis!.emotions) {
          eCounts[e] = (eCounts[e] ?? 0) + 1;
        }
        for (var t in entry.analysis!.themes) {
          tCounts[t] = (tCounts[t] ?? 0) + 1;
        }
        if (entry.analysis!.emotions.isNotEmpty) {
          timeline.add(entry.analysis!.emotions.first);
        }
      }
    }

    String dom = eCounts.isEmpty ? "N/A" : eCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    String topT = tCounts.isEmpty ? "N/A" : tCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    int uniqueRecent = 0;
    if (timeline.length >= 5) {
      uniqueRecent = timeline.sublist(timeline.length - 5).toSet().length;
    }
    String vol = uniqueRecent > 3 ? "High" : (uniqueRecent > 1 ? "Med" : "Low");

    String tr = "Stable";
    if (timeline.isNotEmpty) {
      final last = timeline.last;
      if (["Sadness", "Anger", "Anxiety"].contains(last)) {
        tr = "Declining";
      } else if (["Joy", "Happy", "Excited", "Calm"].contains(last)) tr = "Improving";
    }

    if (mounted) {
      setState(() {
        allEntries = entries;
        emotionCounts = eCounts;
        themeCounts = tCounts;
        recentEmotions = timeline;
        dominantEmotion = dom;
        topTheme = topT;
        volatility = vol;
        trend = tr;
        isLoading = false;
      });
    }
  }

  void _showEntryListModal(String title, List<JournalEntry> relevantEntries) {
    relevantEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF27272A),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text("${relevantEntries.length} found", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text("Here's what happened:", style: TextStyle(color: Colors.white38)),
              SizedBox(height: 24),
              Expanded(
                child: relevantEntries.isEmpty 
                  ? Center(child: Text("No entries found.", style: TextStyle(color: Colors.white24)))
                  : ListView.separated(
                    controller: scrollController,
                    itemCount: relevantEntries.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final entry = relevantEntries[i];
                      final date = DateTime.parse(entry.createdAt);
                      final dateStr = DateFormat('MMM d').format(date);
                      
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                SizedBox(width: 12),
                                if (entry.analysis?.themes.isNotEmpty ?? false)
                                  Expanded(
                                    child: Text(
                                      entry.analysis!.themes.join(" • "),
                                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.tertiary, letterSpacing: 0.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              entry.content, 
                              maxLines: 4, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.4),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryListModal(String title, Map<String, int> counts, Function(String) onItemTap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF27272A),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 24),
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: counts.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.white10, height: 1),
                  itemBuilder: (ctx, i) {
                    final sortedKeys = counts.keys.toList()..sort((a,b) => counts[b]!.compareTo(counts[a]!));
                    final key = sortedKeys[i];
                    final count = counts[key];
                    
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      title: Text(key, style: TextStyle(color: Colors.white, fontSize: 16)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text("$count", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
                        ],
                      ),
                      onTap: () => onItemTap(key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEmotionTap(String emotion) {
    final relevant = allEntries.where((e) => e.analysis?.emotions.contains(emotion) ?? false).toList();
    _showEntryListModal(emotion, relevant);
  }

  void _onThemeTap(String theme) {
    final relevant = allEntries.where((e) => e.analysis?.themes.contains(theme) ?? false).toList();
    _showEntryListModal(theme, relevant);
  }

  Widget _buildSimpleBarChart(Map<String, int> data, Color color) {
    if (data.isEmpty) return SizedBox(height: 100, child: Center(child: Text("No data yet", style: TextStyle(color: Colors.white24))));
    int maxVal = data.values.isEmpty ? 1 : data.values.reduce(max);
    var sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    sortedEntries = sortedEntries.take(5).toList();

    return Column(
      children: sortedEntries.map((e) {
        double pct = e.value / maxVal;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text(e.key, style: TextStyle(fontSize: 12, color: Colors.white60), overflow: TextOverflow.ellipsis)),
              SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5))),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
                    )
                  ],
                ),
              ),
              SizedBox(width: 30, child: Text("${e.value}", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmotionLineChart() {
    if (recentEmotions.isEmpty) return SizedBox(height: 100, child: Center(child: Text("Start journaling to see your flow", style: TextStyle(color: Colors.white24))));
    return Container(
      height: 150,
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: CustomPaint(
        painter: EmotionLinePainter(recentEmotions, Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF27272A), 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
              if (value == "Improving" || value == "High") 
                Icon(Icons.arrow_upward_rounded, size: 16, color: Theme.of(context).colorScheme.tertiary)
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
              SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.white38)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Analysis")),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildKpiCard("Dominant", dominantEmotion, Icons.psychology_rounded, Theme.of(context).colorScheme.secondary),
                      _buildKpiCard("Top Theme", topTheme, Icons.topic_rounded, Theme.of(context).primaryColor),
                      _buildKpiCard("Volatility", volatility, Icons.waves_rounded, Colors.orangeAccent),
                      _buildKpiCard("Trend", trend, Icons.trending_up_rounded, Theme.of(context).colorScheme.tertiary),
                    ],
                  ),
                  
                  SizedBox(height: 32),
                  Text("Emotional Flow", style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF27272A), 
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.all(16),
                    child: _buildEmotionLineChart(),
                  ),

                  SizedBox(height: 32),
                  Text("Spectrum", style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () => _showCategoryListModal("Emotional Spectrum", emotionCounts, _onEmotionTap),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(0xFF27272A), 
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          _buildSimpleBarChart(emotionCounts, Theme.of(context).colorScheme.secondary),
                          SizedBox(height: 12),
                          Text("Tap for details", style: TextStyle(fontSize: 10, color: Colors.white24)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                  Text("Life Themes", style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () => _showCategoryListModal("Themes", themeCounts, _onThemeTap),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(0xFF27272A), 
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          _buildSimpleBarChart(themeCounts, Theme.of(context).colorScheme.tertiary),
                          SizedBox(height: 12),
                          Text("Tap for details", style: TextStyle(fontSize: 10, color: Colors.white24)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 100), // Space for nav bar
                ],
              ),
            ),
    );
  }
}

class EmotionLinePainter extends CustomPainter {
  final List<String> emotions;
  final Color lineColor;
  EmotionLinePainter(this.emotions, this.lineColor);

  double _getY(String emotion) {
    const pos = ["Joy", "Happy", "Excited", "Proud", "Calm", "Grateful", "Love"];
    const neg = ["Sadness", "Anger", "Fear", "Anxiety", "Frustrated", "Lonely"];
    if (pos.contains(emotion)) return 0.2; 
    if (neg.contains(emotion)) return 0.8; 
    return 0.5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.15), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    Paint dotPaint = Paint()..color = Color(0xFF27272A);
    Paint dotBorder = Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 2;

    Paint gridPaint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);

    if (emotions.length < 2) return;

    Path path = Path();
    Path fillPath = Path();
    double stepX = size.width / (emotions.length - 1);

    fillPath.moveTo(0, size.height);

    for (int i = 0; i < emotions.length; i++) {
      double x = i * stepX;
      double y = _getY(emotions[i]) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        double prevX = (i - 1) * stepX;
        double prevY = _getY(emotions[i-1]) * size.height;
        double ctrlX1 = prevX + (stepX / 2);
        double ctrlX2 = x - (stepX / 2);
        
        path.cubicTo(ctrlX1, prevY, ctrlX2, y, x, y);
        fillPath.cubicTo(ctrlX1, prevY, ctrlX2, y, x, y);
      }
    }
    
    fillPath.lineTo((emotions.length - 1) * stepX, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < emotions.length; i++) {
      double x = i * stepX;
      double y = _getY(emotions[i]) * size.height;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}