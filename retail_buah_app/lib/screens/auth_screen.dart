import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'admin_dashboard.dart';
import 'staff_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _selectedRole = 'staff';
  final dio = Dio();

  String get baseUrl => kIsWeb ? 'http://localhost:3000/api/auth' : 'http://10.0.2.2:3000/api/auth';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _handleAuth(bool isLogin) async {
    try {
      final url = isLogin ? '$baseUrl/login' : '$baseUrl/register';
      final data = {
        "username": _userController.text,
        "password": _passController.text,
        if (!isLogin) "role": _selectedRole,
      };

      final response = await dio.post(url, data: data);

      if (isLogin) {
        String role = response.data['role'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminDashboard() : const StaffDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil! Silakan Login")));
        _tabController.animateTo(0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi Kesalahan!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Retail Buah - Auth"),
        backgroundColor: Colors.green,
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "LOGIN"), Tab(text: "REGISTER")]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildForm(true), _buildForm(false)],
      ),
    );
  }

  Widget _buildForm(bool isLogin) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
          TextField(controller: _passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
          if (!isLogin)
            DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              items: ['admin', 'staff'].map((r) => DropdownMenuItem(value: r, child: Text("Role: $r"))).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => _handleAuth(isLogin), child: Text(isLogin ? "MASUK" : "DAFTAR")),
        ],
      ),
    );
  }
}