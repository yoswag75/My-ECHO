import 'package:flutter/material.dart';
import 'api.dart';
import 'journal.dart';
import 'people.dart';
import 'dashboard.dart';
import 'coach.dart';
import 'lock_screen.dart';
import 'profile.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init(); // Load token from storage
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My ECHO',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent, 
        primaryColor: Color(0xFFE1BEE7), 
        cardColor: Color(0xFF27272A), 
        dividerColor: Colors.white10,
        fontFamily: 'Roboto', 
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFE1BEE7), 
          secondary: Color(0xFFFFB7B2), 
          tertiary: Color(0xFFB5EAD7), 
          surface: Color(0xFF27272A),
          onSurface: Color(0xFFF4F4F5),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: Color(0xFFF4F4F5)),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Color(0xFFE1BEE7)),
          bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: Color(0xFFE4E4E7)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFA1A1AA)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE1BEE7), letterSpacing: 1.0),
          iconTheme: IconThemeData(color: Color(0xFFE1BEE7)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF18181B), 
          selectedItemColor: Color(0xFFE1BEE7),
          unselectedItemColor: Colors.white24,
          showUnselectedLabels: false,
          showSelectedLabels: false, 
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE1BEE7),
            foregroundColor: Color(0xFF27272A),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF27272A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.transparent)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Color(0xFFE1BEE7), width: 1.5)),
          hintStyle: TextStyle(color: Colors.white24),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
        iconTheme: IconThemeData(color: Color(0xFFE1BEE7)),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            DoodleBackground(),
            if (child != null) child,
          ],
        );
      },
      home: ApiService.hasToken ? LockScreen() : LoginScreen(),
    );
  }
}

class DoodleBackground extends StatelessWidget {
  const DoodleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final Random random = Random(42); 
    final icons = [
      Icons.edit_note, Icons.book, Icons.favorite_border, Icons.star_border, 
      Icons.cloud_outlined, Icons.coffee, Icons.music_note, Icons.camera_alt_outlined, 
      Icons.lightbulb_outline, Icons.brush, Icons.spa_outlined, Icons.emoji_emotions_outlined,
      Icons.wb_sunny_outlined, Icons.bedtime_outlined, Icons.local_florist_outlined,
      Icons.attach_file, Icons.folder_open
    ];
    
    final colors = [
      Color(0xFFE1BEE7), 
      Color(0xFFFFB7B2), 
      Color(0xFFB5EAD7), 
      Color(0xFFFFF9C4), 
      Color(0xFFE0F7FA), 
    ];

    return Container(
      color: Color(0xFF18181B), 
      child: Stack(
        children: List.generate(40, (index) {
          final top = random.nextDouble() * 800; 
          final left = random.nextDouble() * 400; 
          final icon = icons[random.nextInt(icons.length)];
          final color = colors[random.nextInt(colors.length)];
          final angle = random.nextDouble() * 2 * pi;
          final size = 20.0 + random.nextDouble() * 20.0;

          return Positioned(
            top: top,
            left: left,
            child: Transform.rotate(
              angle: angle,
              child: Icon(
                icon,
                size: size,
                color: color.withOpacity(0.06), 
              ),
            ),
          );
        }),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureCode = true;
  bool _isLoading = false; // Added loading state

  void _auth() async {
    final user = _userCtrl.text;
    final pass = _passCtrl.text;
    final code = _codeCtrl.text;

    if (user.isEmpty || pass.isEmpty) return;
    if (!_isLogin && (code.isEmpty || code.length != 4)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Safe Code must be 4 digits"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);

    String? error;
    if (_isLogin) {
      error = await ApiService.login(user, pass);
    } else {
      error = await ApiService.register(user, pass, code);
    }

    setState(() => _isLoading = false);

    if (error == null) {
      // Success
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      // Show specific error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4), // Longer duration to read
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.2), blurRadius: 20)]
                ),
                child: Icon(Icons.auto_stories_rounded, size: 64, color: Theme.of(context).primaryColor),
              ),
              SizedBox(height: 32),
              Text("My ECHO", style: Theme.of(context).textTheme.displayLarge),
              SizedBox(height: 8),
              Text("Your cozy space for thoughts", style: TextStyle(color: Colors.white54)),
              SizedBox(height: 48),
              TextField(
                controller: _userCtrl, 
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Username", 
                  prefixIcon: Icon(Icons.person_rounded, size: 20, color: Colors.white38)
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passCtrl, 
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password", 
                  prefixIcon: Icon(Icons.lock_rounded, size: 20, color: Colors.white38),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white38,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ), 
                obscureText: _obscurePassword,
              ),
              if (!_isLogin) ...[
                SizedBox(height: 16),
                TextField(
                  controller: _codeCtrl,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: "Safe Code (4 digits)", 
                    prefixIcon: Icon(Icons.shield_rounded, size: 20, color: Colors.white38),
                    counterText: "",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCode ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white38,
                      ),
                      onPressed: () => setState(() => _obscureCode = !_obscureCode),
                    ),
                  ),
                  obscureText: _obscureCode,
                ),
              ],
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _auth,
                  child: _isLoading 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                    : Text(_isLogin ? "Unlock My ECHO" : "Start My New ECHO"),
                ),
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "First time? Create a space." : "Already have a space? Log in.", 
                  style: TextStyle(color: Colors.white38)
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final List<Widget> _screens = [
    JournalScreen(),
    DashboardScreen(),
    PeopleScreen(),
    CoachScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF27272A), 
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _idx,
            backgroundColor: Color(0xFF27272A),
            onTap: (i) => setState(() => _idx = i),
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.edit_note_rounded), activeIcon: Icon(Icons.edit_note_rounded, size: 30), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), activeIcon: Icon(Icons.pie_chart_rounded, size: 30), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), activeIcon: Icon(Icons.people_alt_rounded, size: 30), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.lightbulb_rounded), activeIcon: Icon(Icons.lightbulb_rounded, size: 30), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), activeIcon: Icon(Icons.person_rounded, size: 30), label: ""),
            ],
          ),
        ),
      ),
      extendBody: true, 
    );
  }
}