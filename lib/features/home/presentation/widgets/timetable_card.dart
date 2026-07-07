import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';

class TimetableCard extends StatelessWidget {
  final String time;
  final String subject;
  final String instructor;
  final String location;
  final Color color;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBreak;

  const TimetableCard({
    super.key,
    required this.time,
    required this.subject,
    required this.instructor,
    required this.location,
    required this.color,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isBreak = false,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isCompleted ? 0.5 : 1.0;
    final borderColor = isCurrent ? color : AppTheme.border;
    final bgColor = isBreak ? color.withOpacity(0.1) : AppTheme.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isBreak ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  time.split(' ')[0],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isBreak ? Colors.white : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Subject details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isBreak ? Colors.grey : AppTheme.textPrimary,
                              ),
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                      else if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Now',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (instructor.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Iconsax.user, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            instructor,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Iconsax.location, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Navigation arrow
            if (!isBreak)
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.arrow_right_3, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
