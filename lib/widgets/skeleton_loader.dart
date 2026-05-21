import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width, height, borderRadius;
  const SkeletonLoader({super.key, this.width = double.infinity, this.height = 16, this.borderRadius = 8});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_anim.value),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    ),
  );
}

// Dashboard skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        const SkeletonLoader(width: 40, height: 40, borderRadius: 20),
        const SizedBox(width: 12),
        const SkeletonLoader(width: 160, height: 18),
      ]),
      const SizedBox(height: 24),
      // Filter chips
      Row(children: List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: SkeletonLoader(width: 80, height: 34, borderRadius: 17),
      ))),
      const SizedBox(height: 24),
      // Balance card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const SkeletonLoader(width: 120, height: 14),
          const SizedBox(height: 12),
          const SkeletonLoader(width: 180, height: 36),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(3, (_) => Column(children: [
            const SkeletonLoader(width: 60, height: 12),
            const SizedBox(height: 6),
            const SkeletonLoader(width: 80, height: 18),
          ]))),
        ]),
      ),
      const SizedBox(height: 24),
      // Chart skeleton
      const SkeletonLoader(height: 180, borderRadius: 16),
      const SizedBox(height: 24),
      // Transactions
      const SkeletonLoader(width: 160, height: 18),
      const SizedBox(height: 12),
      ...List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          const SkeletonLoader(width: 44, height: 44, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonLoader(width: 140, height: 14),
            const SizedBox(height: 6),
            const SkeletonLoader(width: 90, height: 11),
          ])),
          const SkeletonLoader(width: 70, height: 16),
        ]),
      )),
    ]),
  );
}

// Transaction list skeleton
class TransactionSkeleton extends StatelessWidget {
  const TransactionSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 8,
    itemBuilder: (_, __) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const SkeletonLoader(width: 42, height: 42, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonLoader(width: 130, height: 14),
            const SizedBox(height: 6),
            const SkeletonLoader(width: 80, height: 11),
          ])),
          const SkeletonLoader(width: 60, height: 16),
        ]),
      ),
    ),
  );
}