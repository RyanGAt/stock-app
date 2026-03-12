import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(22, 30, 58, 0.06),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: compact ? 12 : 16),
          child,
        ],
      ),
    );
  }
}
