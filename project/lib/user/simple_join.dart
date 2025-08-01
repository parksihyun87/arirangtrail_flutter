import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// StatelessWidget을 StatefulWidget으로 변경합니다.
class SimpleJoin extends StatefulWidget {
  const SimpleJoin({super.key, required this.email, required this.username});

  final String email;
  final String username;

  @override
  State<SimpleJoin> createState() => _SimpleJoinState();
}

class _SimpleJoinState extends State<SimpleJoin> {
  // 폼의 상태를 관리하고 유효성을 검사하기 위한 GlobalKey
  final _formKey = GlobalKey<FormState>();

  // 각 입력 필드의 값을 제어하기 위한 컨트롤러
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _nicknameController = TextEditingController();

  // 사용자가 선택한 생년월일을 저장할 변수
  DateTime? _selectedDate;
  bool _isLoading = false; // 로딩 상태를 관리할 변수

  @override
  void dispose() {
    // 위젯이 제거될 때 컨트롤러의 리소스를 해제합니다.
    _lastNameController.dispose();
    _firstNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // API 요청을 처리하는 함수
  Future<void> _submitJoinForm() async {
    // 1. 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return; // 유효하지 않으면 함수 종료
    }
    // 생년월일이 선택되었는지 확인
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    // 2. API로 보낼 데이터 준비
    final Map<String, dynamic> requestBody = {
      'email': widget.email,
      'username': widget.username,
      'lastName': _lastNameController.text,
      'firstName': _firstNameController.text,
      'nickname': _nicknameController.text,
      // 날짜 형식을 'YYYY-MM-DD'로 맞춰서 보냅니다.
      'birthDate': _selectedDate!.toIso8601String().split('T').first,
    };

    try {
      // 3. API 요청 보내기
      // ※ URL은 실제 백엔드 API 주소로 변경해야 합니다.
      final url = Uri.parse('http://arirangtrail.duckdns.org/api/user/join');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // 4. 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공 시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다!')),
        );
        // 로그인 페이지나 메인 페이지로 이동
        // Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // 실패 시 (서버에서 보낸 에러 메시지 표시)
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '알 수 없는 오류가 발생했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가입 실패: $errorMessage')),
        );
      }
    } catch (e) {
      // 네트워크 오류 등 예외 발생 시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // 로딩 종료
      });
    }
  }

  // 날짜 선택기를 표시하는 함수
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추가 정보 입력'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Form 위젯으로 감싸서 유효성 검사를 활성화합니다.
        child: Form(
          key: _formKey,
          child: ListView( // 긴 화면에서도 스크롤이 가능하도록 ListView 사용
            children: [
              // 전달받은 이메일과 유저네임 표시 (수정 불가)
              Text('아이디: ${widget.username}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('이메일: ${widget.email}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),

              // 성, 이름 입력 필드
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: '성(Last Name)'),
                      validator: (value) =>
                      value!.isEmpty ? '성을 입력해주세요.' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: '이름(First Name)'),
                      validator: (value) =>
                      value!.isEmpty ? '이름을 입력해주세요.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 닉네임 입력 필드
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임'),
                validator: (value) => value!.isEmpty ? '닉네임을 입력해주세요.' : null,
              ),
              const SizedBox(height: 24),

              // 생년월일 선택
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? '생년월일을 선택해주세요.'
                          : '생년월일: ${_selectedDate!.toIso8601String().split('T').first}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 가입 완료 버튼
              // 로딩 중일 때는 비활성화하고 로딩 인디케이터 표시
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitJoinForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('가입 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}