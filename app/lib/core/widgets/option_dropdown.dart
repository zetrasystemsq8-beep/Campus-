import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/option.dart';

/// Dropdown fed by an async list, with loading, retry and empty states.
class OptionDropdown extends StatelessWidget {
  const OptionDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.onRetry,
    this.validator,
  });

  final String label;
  final AsyncValue<List<Option>> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return options.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: const LinearProgressIndicator(),
      ),
      error: (_, __) => InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: 'Could not load. Check your connection.'),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(labelText: label, helperText: 'Nothing available yet'),
            child: const Text('-'),
          );
        }
        return DropdownButtonFormField<String>(
          value: items.any((o) => o.id == value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in items)
              DropdownMenuItem(value: o.id, child: Text(o.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
          validator: validator,
        );
      },
    );
  }
}
