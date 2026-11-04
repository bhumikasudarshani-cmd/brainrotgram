import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'brand_mark.dart';

/// Keep the app's name together, including on narrow screens and large text.
class BrandWordmark extends StatelessWidget {
  final double fontSize;

  const BrandWordmark({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: fontSize * 1.3),
          const SizedBox(width: 8),
          Text(
            'brainrotgram',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontFamily: AppFonts.basteleur,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.plum,
            ),
          ),
        ],
      ),
    );
  }
}
