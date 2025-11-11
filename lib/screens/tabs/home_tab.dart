import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Text(
          'Home',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
