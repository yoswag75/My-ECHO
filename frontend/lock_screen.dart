import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart'; 

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _code = "";
  bool _isLoading = false;
  String _error = "";

  void _onDigitPress(String digit) {
    if (_code.length < 4) {
      setState(() {
        _code += digit;
        _error = "";
      });
      if (_code.length == 4) {
        _verify();
      }
    }
  }

  void _onBackspace() {
    if (_code.isNotEmpty) {
      setState(() {
        _code = _code.substring(0, _code.length - 1);
        _error = "";
      });
    }
  }

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    final success = await ApiService.verifyPasscode(_code);
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      setState(() {
        _code = "";
        _error = "Incorrect code 🙈";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded, size: 48, color: Theme.of(context).primaryColor),
            ),
            SizedBox(height: 32),
            Text("Welcome Back", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Enter your safe code", style: TextStyle(color: Colors.white38)),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool filled = index < _code.length;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  width: filled ? 16 : 12,
                  height: filled ? 16 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Theme.of(context).primaryColor : Colors.white10,
                    boxShadow: filled ? [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 8)] : [],
                  ),
                );
              }),
            ),
            SizedBox(height: 24),
            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            SizedBox(height: 48),
            _buildKeypad(),
            SizedBox(height: 24),
            if (_isLoading) CircularProgressIndicator(color: Theme.of(context).primaryColor),
            TextButton(
              onPressed: () async {
                await ApiService.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              child: Text("Not you? Switch Account", style: TextStyle(color: Colors.white38)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildRow(["1", "2", "3"]),
          _buildRow(["4", "5", "6"]),
          _buildRow(["7", "8", "9"]),
          _buildRow(["", "0", "del"]),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: keys.map((k) {
          if (k.isEmpty) return SizedBox(width: 72, height: 72);
          if (k == "del") {
            return InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(36),
              child: Container(
                width: 72, height: 72,
                alignment: Alignment.center,
                child: Icon(Icons.backspace_rounded, color: Colors.white38),
              ),
            );
          }
          return InkWell(
            onTap: () => _onDigitPress(k),
            borderRadius: BorderRadius.circular(36),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF27272A),
              ),
              alignment: Alignment.center,
              child: Text(k, style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }
}