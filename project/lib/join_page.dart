import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _birthdateController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _performJoin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.post('api/join', {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'email': _emailController.text,
        'firstname': _firstnameController.text,
        'lastname': _lastnameController.text,
        'birthdate': _birthdateController.text,
        'nickname': _nicknameController.text,
      });

      // 응답 본문을 JSON으로 해석하지 않고, 바로 텍스트로 읽습니다.
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showResultDialog(
          title: '회원가입 성공',
          content: '회원가입이 완료되었습니다. 로그인 페이지로 이동합니다.',
          onConfirm: () {
            Navigator.of(context).pop();
          },
        );
      } else {
        final errorMessage =
            responseBody.isNotEmpty ? responseBody : '알 수 없는 서버 오류가 발생했습니다.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showResultDialog(
          title: '회원가입 실패',
          content: e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showResultDialog(
      {required String title,
      required String content,
      VoidCallback? onConfirm}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(title: Text(title), content: Text(content), actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm?.call();
                  },
                  child: const Text('확인'))
            ]));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        _birthdateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2d3748),
      appBar: AppBar(
          title: const Text('회원가입'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField(
                  controller: _usernameController, label: '아이디'),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _passwordController,
                  label: '비밀번호',
                  obscureText: true),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _emailController,
                  label: '이메일',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _firstnameController, label: '성 (First Name)'),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _lastnameController, label: '이름 (Last Name)'),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _nicknameController, label: '닉네임'),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _birthdateController,
                  readOnly: true,
                  decoration: _inputDecoration('생년월일 (Birthdate)'),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => value!.isEmpty ? '생년월일을 선택해주세요.' : null,
                  onTap: _selectDate),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2d3748),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                onPressed: _isLoading ? null : _performJoin,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2d3748))))
                    : const Text('회원가입 완료',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('이미 계정이 있으신가요? 로그인',
                      style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      {required TextEditingController controller,
      required String label,
      bool obscureText = false,
      TextInputType? keyboardType}) {
    return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label 항목을 입력해주세요.';
          }
          return null;
        });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white)),
        errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2)));
  }
}
