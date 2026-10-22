import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../core/constants/colors.dart';
import '../core/theme.dart';
import '../data/models.dart';

class Brand extends StatelessWidget {
  final Brightness? brightness;
  final double height;
  const Brand({super.key, this.brightness, this.height = 28});

  @override
  Widget build(BuildContext context) {
    final effectiveBrightness =
        brightness ?? Theme.of(context).brightness;
    final isDark = effectiveBrightness == Brightness.dark;
    return Image.asset(
      isDark
          ? 'assets/brand/yolo-business-brand-white.png'
          : 'assets/brand/yolo-business-brand-black.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Barlow Semi Condensed',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const PageHeading(this.eyebrow, this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkMuted : YoloTheme.muted;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Geist Mono',
              fontSize: 10,
              letterSpacing: 1.5,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(color: mutedColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class Notice extends StatelessWidget {
  final String message;
  final VoidCallback? retry;
  const Notice(this.message, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      liveRegion: true,
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Iconsax.info_circle, size: 19),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('Réessayer')),
          ],
        ),
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  final Delivery delivery;
  const StatusPill(this.delivery, {super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = delivery.finished
        ? (isDark
            ? theme.colorScheme.surfaceContainerHighest
            : YoloTheme.surface)
        : (isDark ? Colors.white : YoloTheme.ink);
    final fg = delivery.finished
        ? (isDark ? AppColors.darkMuted : YoloTheme.muted)
        : (isDark ? AppColors.ink : Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        delivery.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onTap;
  const DeliveryCard(this.delivery, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : YoloTheme.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      delivery.reference,
                      style: TextStyle(
                        fontFamily: 'Geist Mono',
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : YoloTheme.muted,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.north_east, size: 17),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Iconsax.box, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            delivery.recipient,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            delivery.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : YoloTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(delivery),
                    Text(
                      dateLabel(delivery.data['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : YoloTheme.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.icon = Iconsax.box,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkMuted : YoloTheme.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: mutedColor),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Future<bool> confirmAction(
  BuildContext context,
  String title,
  String body,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
