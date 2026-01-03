import 'package:flutter/material.dart';

class Accordion extends StatefulWidget {
  final Widget child;
  final bool expanded;

  const Accordion({super.key, required this.child, required this.expanded});

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant Accordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.expanded ? controller.forward() : controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: controller,
      axisAlignment: -1,
      child: widget.child,
    );
  }
}
