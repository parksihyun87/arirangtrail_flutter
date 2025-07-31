import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/locale_provider.dart';
import 'package:translator/translator.dart';

// API로 받아온 텍스트를 현재 언어 설정에 맞게 "자동으로" 번역해주는 위젯
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const TranslatedText({super.key, required this.text, this.style});

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';

  // 위젯의 상태를 관리하기 위해 didChangeDependencies에서 언어 코드를 추적
  String? _currentLanguageCode;

  // Provider를 통해 언어 설정이 변경될 때마다 이 메소드가 호출
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguageCode = context.watch<LocaleProvider>().locale.languageCode;

    // 언어가 실제로 변경되었을 때만 번역을 다시 실행.
    if (_currentLanguageCode != newLanguageCode) {
      _currentLanguageCode = newLanguageCode;
      _translate();
    }
  }

  Future<void> _translate() async {
    if (widget.text.isEmpty) {
      setState(() => _translatedText = '');
      return;
    }
    // 목표 언어가 한국어면 번역할 필요 없이 원본을 그대로 사용
    if (_currentLanguageCode == 'ko') {
      setState(() => _translatedText = widget.text);
      return;
    }

    // 번역이 시작되기 전에 '...'를 잠시 보여줌
    if (mounted) setState(() => _translatedText = '...');

    try {
      final translator = GoogleTranslator();
      final translation = await translator.translate(widget.text,
          from: 'ko', to: _currentLanguageCode!);
      if (mounted) setState(() => _translatedText = translation.text);
    } catch (e) {
      print("Translation Error: $e");
      if (mounted) setState(() => _translatedText = widget.text); // 실패 시 원본 표시
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_translatedText, style: widget.style);
  }
}
