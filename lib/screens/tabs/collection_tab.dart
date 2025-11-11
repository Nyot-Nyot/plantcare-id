import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class CollectionTab extends StatelessWidget {
  const CollectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Text(
          'Collection',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
