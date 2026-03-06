import 'package:flutter/material.dart';
import 'api.dart';
import 'models.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> entries = [];
  bool isLoading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => isLoading = true);
    final loaded = await ApiService.getEntries();
    setState(() {
      entries = loaded;
      isLoading = false;
    });
  }

  Future<void> _submitEntry() async {
    if (_controller.text.isEmpty) return;
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
    );
    
    final newEntry = await ApiService.createEntry(_controller.text);
    
    Navigator.pop(context); // Close loader
    _controller.clear();
    FocusScope.of(context).unfocus(); 
    
    if (newEntry != null) {
      await _loadEntries();
      if (newEntry.analysis != null) {
        _showReflectionDialog(newEntry.analysis!.reflection);
      }
    }
  }

  Future<void> _deleteEntry(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove Memory?", style: TextStyle(color: Theme.of(context).primaryColor)),
        content: Text("This will permanently delete this memory.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Keep it", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteEntry(id);
      if (success) _loadEntries(); 
    }
  }

  void _showReflectionDialog(String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF27272A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 24),
            Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 32),
            SizedBox(height: 16),
            Text("A Little Insight ✨", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.6, color: Colors.white70)),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My ECHO 💭")),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF27272A),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.fromLTRB(20, 10, 10, 10),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
                  decoration: InputDecoration(
                    hintText: "How are you feeling today?",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    fillColor: Colors.transparent, 
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_upward_rounded, color: Colors.black87),
                        onPressed: _submitEntry,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final date = DateTime.parse(entry.createdAt);
                      final timeString = DateFormat.jm().format(date);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF27272A),
                                    borderRadius: BorderRadius.circular(16)
                                  ),
                                  child: Column(
                                    children: [
                                      Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(DateFormat('MMM').format(date).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38)),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(timeString, style: TextStyle(fontSize: 10, color: Colors.white24)),
                                SizedBox(height: 8),
                                IconButton(
                                  icon: Icon(Icons.delete_rounded, color: Colors.white12, size: 20),
                                  onPressed: () => _deleteEntry(entry.id),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (entry.analysis != null && entry.analysis!.reflection.isNotEmpty) {
                                    _showReflectionDialog(entry.analysis!.reflection);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF27272A),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(24),
                                      bottomLeft: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                      topLeft: Radius.circular(4)
                                    ),
                                  ),
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.content, style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5)),
                                      if (entry.analysis != null) ...[
                                        SizedBox(height: 16),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ...entry.analysis!.emotions.map((e) => _buildTag(e, Theme.of(context).colorScheme.secondary)),
                                            ...entry.analysis!.themes.map((t) => _buildTag(t, Theme.of(context).colorScheme.tertiary)),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}