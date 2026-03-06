import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await ApiService.getUsername();
    if (mounted) {
      setState(() {
        username = name;
        isLoading = false;
      });
    }
  }

  Future<void> _showEditDialog(String title, String field, {bool isPassword = false, bool isNumber = false}) async {
    final controller = TextEditingController();
    if (field == 'username' && username != null) {
      controller.text = username!;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLength: isNumber ? 4 : null,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new value",
            hintStyle: TextStyle(color: Colors.white38),
            counterText: "",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = controller.text;
              if (val.isEmpty) return;
              if (isNumber && val.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Must be 4 digits")));
                return;
              }
              
              Navigator.pop(context); 
              await _update(field, val);
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _update(String field, String value) async {
    bool success = false;
    if (field == 'username') {
      success = await ApiService.updateProfile(username: value);
    } else if (field == 'password') {
      success = await ApiService.updateProfile(password: value);
    } else if (field == 'passcode') {
      success = await ApiService.updateProfile(passcode: value);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Updated successfully ✨"), backgroundColor: Colors.greenAccent));
      if (field == 'username') _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
        : SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF27272A),
                    child: Text(
                      username != null && username!.isNotEmpty ? username![0].toUpperCase() : "?",
                      style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(username ?? "User", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                
                SizedBox(height: 48),
                
                _buildActionItem(
                  icon: Icons.person_rounded, 
                  title: "Change Username", 
                  onTap: () => _showEditDialog("Update Username", "username")
                ),
                _buildActionItem(
                  icon: Icons.lock_rounded, 
                  title: "Change Password", 
                  onTap: () => _showEditDialog("Update Password", "password", isPassword: true)
                ),
                _buildActionItem(
                  icon: Icons.shield_rounded, 
                  title: "Change Safe Code", 
                  onTap: () => _showEditDialog("Update Safe Code", "passcode", isNumber: true)
                ),

                SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ApiService.logout();
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text("Log Out"),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF27272A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white24),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}