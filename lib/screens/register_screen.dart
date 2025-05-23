import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_apps/screens/login_screen.dart';
import 'package:health_apps/services/auth_service.dart';
import 'package:health_apps/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  double _dragStartX = 0.0;
  double _dragDeltaX = 0.0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mật khẩu xác nhận không khớp")),
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _userService.updateUserData(user.uid, {
            'name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': Timestamp.now(),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng ký thành công, vui lòng đăng nhập")),
          );
        }

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              const begin = Offset(-1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Đăng ký thất bại: ${e.message}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF008DFF),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
          _dragDeltaX = 0.0;
        },
        onHorizontalDragUpdate: (details) {
          _dragDeltaX = details.globalPosition.dx - _dragStartX;
        },
        onHorizontalDragEnd: (details) {
          if (_dragDeltaX > 100) {
            if (mounted) Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        Image.asset('assets/xoa.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("SSKĐT",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text("Sổ sức khỏe điện tử", style: TextStyle(fontSize: 16, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text("Đăng ký",
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _fullNameController,
                                        hintText: "Họ và tên",
                                        icon: Icons.person,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        controller: _emailController,
                                        hintText: "Email",
                                        icon: Icons.email,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        controller: _passwordController,
                                        hintText: "Mật khẩu",
                                        icon: Icons.lock,
                                        isPassword: true,
                                        obscureText: _obscurePassword,
                                        toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        controller: _confirmPasswordController,
                                        hintText: "Xác nhận mật khẩu",
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        obscureText: _obscurePassword,
                                        toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      const SizedBox(height: 24),
                                      _buildGradientButton(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Bạn đã có tài khoản? "),
                                    GestureDetector(
                                      onTap: () {
                                        if (mounted) Navigator.pop(context);
                                      },
                                      child: const Text("Đăng nhập", style: TextStyle(color: Colors.blue)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text("Hotline 19009095", style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Vui lòng nhập $hintText";
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: toggleObscure,
              )
            : null,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildGradientButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF008DFF), Color(0xFF4FC1FF)]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Đăng ký", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
