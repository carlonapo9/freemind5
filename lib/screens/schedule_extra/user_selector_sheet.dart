import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserSelectorSheet extends StatefulWidget {
  final VoidCallback? onSelectionChanged;

  const UserSelectorSheet({super.key, this.onSelectionChanged});

  @override
  State<UserSelectorSheet> createState() => _UserSelectorSheetState();
}

class _UserSelectorSheetState extends State<UserSelectorSheet> {
  late Box usersBox;
  late List<dynamic> userKeys;
  late List<dynamic> keys;
  late List<dynamic> selectedKeys;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users');

    userKeys = usersBox.keys.where((k) => k != 'selectedUserKeys').toList();
    keys = ["_all", ...userKeys];

    selectedKeys = List<dynamic>.from(usersBox.get('selectedUserKeys'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const Text("Select Users", style: TextStyle(fontSize: 18)),
        const SizedBox(height: 12),

        ...keys.map((key) {
          final bool isAll = key == "_all";

          // Build avatar
          Widget leadingAvatar;
          String displayName;

          if (isAll) {
            final allUsers = userKeys.map((k) => usersBox.get(k)).toList();
            final maxToShow = 3;
            final visible = allUsers.take(maxToShow).toList();
            final extra = allUsers.length - maxToShow;

            leadingAvatar = SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                children: [
                  for (int i = 0; i < visible.length; i++)
                    Positioned(
                      left: i * 14,
                      child: CircleAvatar(
                        radius: 12,
                        child: Icon(
                          IconData(
                            visible[i]["avatar"],
                            fontFamily: 'MaterialIcons',
                          ),
                          size: 14,
                        ),
                      ),
                    ),
                  if (extra > 0)
                    Positioned(
                      left: maxToShow * 14,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.teal.shade200,
                        child: Text(
                          "+$extra",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );

            displayName = "All";
          } else {
            final user = usersBox.get(key);
            leadingAvatar = CircleAvatar(
              child: Icon(
                IconData(user["avatar"], fontFamily: 'MaterialIcons'),
                size: 20,
              ),
            );
            displayName = user["name"];
          }

          // Correct selection logic for ALL
          final bool isAllSelected =
              isAll &&
              selectedKeys.length == userKeys.length &&
              userKeys.every((k) => selectedKeys.contains(k));

          final bool isSelected = isAll
              ? isAllSelected
              : selectedKeys.contains(key);

          return ListTile(
            onTap: () {
              if (isAll) {
                usersBox.put('selectedUserKeys', userKeys);
              } else {
                usersBox.put('selectedUserKeys', [key]);
              }

              widget.onSelectionChanged?.call(); // LIVE UPDATE
              Navigator.pop(context);
            },
            leading: leadingAvatar,
            title: Text(displayName),
            trailing: GestureDetector(
              onTap: () {
                if (isAll) {
                  if (isAllSelected) {
                    usersBox.put('selectedUserKeys', ['main']);
                    selectedKeys = ['main'];
                  } else {
                    usersBox.put('selectedUserKeys', userKeys);
                    selectedKeys = List<dynamic>.from(userKeys);
                  }
                } else {
                  if (isSelected) {
                    selectedKeys.remove(key);
                  } else {
                    selectedKeys.add(key);
                  }

                  if (selectedKeys.isEmpty) {
                    selectedKeys.add('main');
                  }

                  usersBox.put('selectedUserKeys', selectedKeys);
                }

                widget.onSelectionChanged?.call(); // LIVE UPDATE
                setState(() {});
              },
              child: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 26,
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 12),
      ],
    );
  }
}
