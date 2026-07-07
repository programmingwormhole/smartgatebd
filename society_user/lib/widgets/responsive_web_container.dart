import 'package:flutter/material.dart';

class ResponsiveWebContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool wrapInCard;

  const ResponsiveWebContainer({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.wrapInCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > maxWidth;

        if (!isDesktop) {
          return child;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: wrapInCard
                ? Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: child,
                    ),
                  )
                : child,
          ),
        );
      },
    );
  }
}
