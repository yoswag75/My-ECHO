import 'package:flutter/material.dart';
import 'api.dart';
import 'models.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  _PeopleScreenState createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<Person> people = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    if (mounted) setState(() => isLoading = true);
    final loaded = await ApiService.getPeople();
    if (mounted) {
      setState(() {
      people = loaded;
      isLoading = false;
    });
    }
  }

  void _showPersonDetails(Person person) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersonDetailSheet(personId: person.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connections 👥")),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : people.isEmpty
              ? Center(child: Text("Mentions appear here.", style: TextStyle(color: Colors.white38)))
              : ListView.separated(
                  padding: EdgeInsets.all(20),
                  separatorBuilder: (c, i) => SizedBox(height: 12),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final p = people[index];
                    return InkWell(
                      onTap: () => _showPersonDetails(p),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(p.name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            SizedBox(width: 16),
                            Text(p.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            Spacer(),
                            Icon(Icons.chevron_right_rounded, color: Colors.white24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class PersonDetailSheet extends StatefulWidget {
  final int personId;
  const PersonDetailSheet({super.key, required this.personId});

  @override
  _PersonDetailSheetState createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends State<PersonDetailSheet> {
  PersonAnalytics? analytics;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final res = await ApiService.getPersonAnalytics(widget.personId);
    if (mounted) {
      setState(() {
      analytics = res;
      loading = false;
    });
    }
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFF27272A), 
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.0)),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)]
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : analytics == null
              ? Center(child: Text("Could not load analytics"))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
                      SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text(analytics!.name, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 8),
                            Text("${analytics!.entryCount} mentions", style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      Row(
                        children: [
                          _buildMetric("Impact", analytics!.netEffect, 
                            analytics!.netEffect.contains("Positive") ? Theme.of(context).colorScheme.tertiary : Colors.orangeAccent),
                          SizedBox(width: 12),
                          _buildMetric("Tone", analytics!.tone, Theme.of(context).primaryColor),
                        ],
                      ),
                      SizedBox(height: 32),
                      Text("Trajectory", style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      Container(
                        height: 180,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: CustomPaint(
                          painter: RelationshipGraphPainter(analytics!.history, Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      SizedBox(height: 32),
                      Text("Recurring Emotions", style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: analytics!.commonEmotions.map((e) => Chip(
                          label: Text(e),
                          backgroundColor: Color(0xFF27272A),
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                          padding: EdgeInsets.all(8),
                        )).toList(),
                      ),
                      SizedBox(height: 32),
                      Text("Stability Score", style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(height: 12, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
                          FractionallySizedBox(
                            widthFactor: analytics!.consistency / 100,
                            child: Container(height: 12, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(6))),
                          )
                        ],
                      ),
                      SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: Text("${analytics!.consistency}%", style: TextStyle(color: Colors.white38, fontSize: 12))),
                    ],
                  ),
                ),
    );
  }
}

class RelationshipGraphPainter extends CustomPainter {
  final List<SentimentPoint> history;
  final Color color;
  RelationshipGraphPainter(this.history, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    Paint gridPaint = Paint()..color = Colors.white10..strokeWidth = 1.0;
    
    // Center line
    double midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    if (history.isEmpty) return;
    
    if (history.length == 1) {
      canvas.drawCircle(Offset(size.width/2, midY), 6, Paint()..color=color);
      return;
    }

    Path path = Path();
    double stepX = size.width / (history.length - 1);
    
    // Map -5 to 5 -> height to 0
    double mapY(int score) {
      int s = score.clamp(-5, 5);
      double norm = (s + 5) / 10.0;
      return size.height - (norm * size.height);
    }

    for (int i = 0; i < history.length; i++) {
      double x = i * stepX;
      double y = mapY(history[i].score);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double prevX = (i - 1) * stepX;
        double prevY = mapY(history[i-1].score);
        double ctrlX1 = prevX + (stepX / 2);
        double ctrlX2 = x - (stepX / 2);
        
        path.cubicTo(ctrlX1, prevY, ctrlX2, y, x, y);
      }
    }
    
    // Shadow
    Paint shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}