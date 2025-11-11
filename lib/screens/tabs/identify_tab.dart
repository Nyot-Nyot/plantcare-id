import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class IdentifyTab extends StatelessWidget {
  const IdentifyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Text(
          'Identify',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
