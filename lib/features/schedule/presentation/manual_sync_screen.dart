import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/premium_button.dart';
import 'providers/timetable_provider.dart';

/// Fallback for when portal scraping is unavailable. The student types in
/// their registered unit codes directly. Backend matches these against the
/// master timetable the same way it would scraped codes.
class ManualSyncScreen extends ConsumerStatefulWidget {
  const ManualSyncScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManualSyncScreen> createState() => _ManualSyncScreenState();
}

class _ManualSyncScreenState extends ConsumerState<ManualSyncScreen> {
  final List<TextEditingController> _controllers = [TextEditingController()];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeField(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final unitCodes = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (unitCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one unit code')),
      );
      return;
    }

    final notifier = ref.read(timetableProvider.notifier);
    final success = await notifier.syncManually(unitCodes);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units synced successfully!')),
      );
      context.pop();
    } else {
      final error = ref.read(timetableProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Sync failed.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: AppTheme.getTextPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Enter Units Manually',
          style: TextStyle(
            color: AppTheme.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type each registered unit code (e.g. COSC328).',
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controllers[index],
                            decoration: InputDecoration(
                              hintText: 'e.g. COSC 328',
                              filled: true,
                              fillColor: AppTheme.getSurface(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (_controllers.length > 1)
                          IconButton(
                            icon: const Icon(Iconsax.trash, color: AppTheme.error),
                            onPressed: () => _removeField(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            TextButton.icon(
              icon: const Icon(Iconsax.add),
              label: const Text('Add another unit'),
              onPressed: _addField,
            ),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              PremiumButton(text: 'Sync Units', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
