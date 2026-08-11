import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../data/models/enums/room_category.dart';
import '../../data/models/room.dart';
import '../../providers/property_provider.dart';
import 'add_room_sheet.dart';

class RoomSection extends StatelessWidget {
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final RoomCategory category;
  final List<Room> rooms;
  final PropertyViewModel viewModel;
  final ValueChanged<String> onRoomTap;

  const RoomSection({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.category,
    required this.rooms,
    required this.viewModel,
    required this.onRoomTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRooms = rooms.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderLight),
      ),
      child: ExpansionTile(
        initiallyExpanded: hasRooms,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.displayString,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${rooms.length}',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        children: [
          if (!hasRooms) ...[
            const SizedBox(height: 4),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No rooms added yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: _buildAddButton(context),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              itemBuilder: (context, idx) {
                final room = rooms[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      viewModel.selectRoomForEditing(room.id);
                      onRoomTap(room.id);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.borderLight.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  room.conditionRating != null
                                      ? 'Condition: Level ${room.conditionRating}'
                                      : 'Condition: Not rated',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: room.conditionRating != null
                                        ? theme.completeColor
                                        : theme.pendingColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _confirmDeleteRoom(context, room),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.borderLight.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: theme.textSecondary.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _buildAddButton(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => AddRoomSheet.show(
        context,
        viewModel,
        category,
        theme,
        textTheme,
      ),
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Add Room'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, Room room) {
    showRealEstateDialog(
      context: context,
      title: 'Remove Room',
      theme: theme,
      content: Text(
        'Are you sure you want to remove "${room.name}"?',
        style: textTheme.bodyLarge,
      ),
      actions: [
        dialogCancelButton(context: context, theme: theme),
        dialogActionButton(
          theme: theme,
          text: 'Remove',
          onPressed: () {
            viewModel.removeRoom(room.id);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
