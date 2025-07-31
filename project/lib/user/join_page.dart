import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        String successMessage = l10n.joinSuccess;
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          successMessage = responseData['message'] ?? successMessage;
        }
        _showResultDialog(
            title: l10n.joinSuccess,
            content: successMessage,
            onConfirm: () => Navigator.of(context).pop());
      } else {
        String errorMessage = '알 수 없는 서버 오류';
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          errorMessage = errorData['message'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showResultDialog(
          title: l10n.joinFailed,
          content: e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResultDialog(
      {required String title,
      required String content,
      VoidCallback? onConfirm}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                    child: Text(l10n.confirm))
              ],
            ));
  }

  Future<void> _selectDate() async {
    /* ... 데이트 피커 로직 ... */
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF2d3748),
      appBar: AppBar(
          title: Text(l10n.join),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField(
                  controller: _usernameController, label: l10n.username),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _passwordController,
                  label: l10n.password,
                  obscureText: true),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _emailController,
                  label: l10n.email,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _firstnameController, label: l10n.firstName),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _lastnameController, label: l10n.lastName),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _nicknameController, label: l10n.nickname),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _birthdateController,
                  readOnly: true,
                  decoration: _inputDecoration(l10n.birthdate),
                  validator: (value) => value!.isEmpty
                      ? l10n.errorSelectItem(l10n.birthdate)
                      : null,
                  onTap: _selectDate),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                onPressed: _isLoading ? null : _performJoin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(l10n.joinComplete),
              ),
              const SizedBox(height: 20),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.alreadyHaveAccount)),
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
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
        validator: (value) => (value == null || value.isEmpty)
            ? l10n.errorSelectItem(label)
            : null);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)));
  }
}
