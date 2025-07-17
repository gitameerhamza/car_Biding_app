import 'package:flutter/material.dart';

/// A widget that helps prevent layout overflow by providing safe constraints
class SafeLayoutWidget extends StatelessWidget {
  final Widget child;
  final bool enableDebugMode;

  const SafeLayoutWidget({
    super.key,
    required this.child,
    this.enableDebugMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (enableDebugMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: child,
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// A safe Row widget that prevents overflow
class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const SafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the content might overflow, use a scrollable row
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// A safe Column widget that prevents overflow
class SafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const SafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: IntrinsicWidth(
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// A responsive text widget that scales down to fit
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style,
        maxLines: maxLines ?? 1,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.ellipsis,
      ),
    );
  }
}
