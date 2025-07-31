
import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('축제 후기'),
      ),
      body: const Center(
        child: Text('축제 후기 페이지입니다.'),
      ),
    );
  }
}
