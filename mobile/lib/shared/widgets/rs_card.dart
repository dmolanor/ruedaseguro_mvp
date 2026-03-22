import 'package:flutter/material.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';

class RSCard extends StatelessWidget {
  const RSCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(RSSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RSColors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(RSRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RSRadius.md),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RSRadius.md),
            border: Border.all(color: RSColors.border, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
