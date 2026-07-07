import 'package:flutter/material.dart';

class ResponsiveWebGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCrossAxisCount;
  final int desktopCrossAxisCount;
  final double childAspectRatioDesktop;
  final double childAspectRatioMobile;
  final double spacing;

  const ResponsiveWebGrid({
    super.key,
    required this.children,
    this.mobileCrossAxisCount = 1,
    this.desktopCrossAxisCount = 3,
    this.childAspectRatioDesktop = 3.5,
    this.childAspectRatioMobile = 1.0,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (!isDesktop && mobileCrossAxisCount == 1) {
          // Standard Column layout for mobile
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((e) => Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: e,
            )).toList(),
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? desktopCrossAxisCount : mobileCrossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: isDesktop ? childAspectRatioDesktop : childAspectRatioMobile,
          children: children,
        );
      },
    );
  }
}
