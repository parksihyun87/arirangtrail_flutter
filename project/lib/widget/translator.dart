import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import '../provider/locale_provider.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const TranslatedText({super.key, required this.text, this.style});

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';
  String? _currentLanguageCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentLanguageCode = context.read<LocaleProvider>().locale.languageCode;
    _translate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguageCode = context.watch<LocaleProvider>().locale.languageCode;

    if (_currentLanguageCode != newLanguageCode) {
      _currentLanguageCode = newLanguageCode;
      _translate();
    }
  }

  Future<void> _translate() async {
    if (mounted) setState(() => _isLoading = true);

    if (widget.text.isEmpty) {
      if (mounted)
        setState(() {
          _translatedText = '';
          _isLoading = false;
        });
      return;
    }

    if (_currentLanguageCode == 'ko') {
      if (mounted)
        setState(() {
          _translatedText = widget.text;
          _isLoading = false;
        });
      return;
    }

    try {
      final translator = GoogleTranslator();
      final translation = await translator.translate(widget.text,
          from: 'ko', to: _currentLanguageCode!);
      if (mounted)
        setState(() {
          _translatedText = translation.text;
        });
    } catch (e) {
      print("Translation Error: $e");
      if (mounted)
        setState(() {
          _translatedText = widget.text;
        });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Text('...', style: widget.style);
    }

    return Text(_translatedText, style: widget.style);
  }
}
