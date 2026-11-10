import 'package:flutter/material.dart';

/// Кнопки действий над записью в строке таблицы или в карточке.
/// Действующую запись можно изменить и удалить, удалённую — восстановить
/// или стереть насовсем.
List<Widget> recordActions({
  required bool isDeleted,
  required VoidCallback onEdit,
  required VoidCallback onSoftDelete,
  required VoidCallback onRestore,
  required VoidCallback onHardDelete,
}) {
  return [
    if (!isDeleted) ...[
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined),
        onPressed: onEdit,
      ),
      IconButton(
        tooltip: 'Удалить (можно восстановить)',
        icon: const Icon(Icons.delete_outline),
        onPressed: onSoftDelete,
      ),
    ] else ...[
      IconButton(
        tooltip: 'Восстановить',
        icon: const Icon(Icons.restore_from_trash_outlined),
        onPressed: onRestore,
      ),
      IconButton(
        tooltip: 'Удалить навсегда',
        icon: const Icon(Icons.delete_forever_outlined),
        onPressed: onHardDelete,
      ),
    ],
  ];
}
