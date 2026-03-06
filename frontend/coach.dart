import 'package:flutter/material.dart';
import 'api.dart';
import 'models.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  _CoachScreenState createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  WeeklyGoal? goal;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoach();
  }

  Future<void> _loadCoach() async {
    final res = await ApiService.getWeeklyCoach();
    if (mounted) {
      setState(() {
      goal = res;
      isLoading = false;
    });
    }
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF27272A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 16),
              Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
            ],
          ),
          SizedBox(height: 16),
          Text(content, style: TextStyle(fontSize: 16, height: 1.6, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.white12),
            SizedBox(height: 24),
            Text(
              "Gathering Stardust...",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "Write a journal entry so I can learn about your week.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white38, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Weekly Coach")),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : goal == null
              ? Center(child: Text("Could not reach coach.", style: TextStyle(color: Colors.white38)))
              : !goal!.hasData 
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Theme.of(context).primaryColor.withOpacity(0.2), Theme.of(context).primaryColor.withOpacity(0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2))
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text("WEEKLY SUMMARY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF18181B), letterSpacing: 1.0)),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  goal!.title,
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 32),
                          _buildSection("Insight", goal!.insight, Icons.visibility_rounded, Theme.of(context).colorScheme.tertiary),
                          _buildSection("Advice", goal!.advice, Icons.lightbulb_rounded, Theme.of(context).colorScheme.secondary),
                          
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              "Week starting ${goal!.weekStart}",
                              style: TextStyle(color: Colors.white24, fontSize: 12),
                            ),
                          ),
                          SizedBox(height: 80),
                        ],
                      ),
                    ),
    );
  }
}