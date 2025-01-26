import 'package:flutter/material.dart';

class RewardButton extends StatelessWidget {
  final void Function()? onTap;
  final IconData iconData;
  const RewardButton({
    super.key,
    required this.onTap,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Icon(
              iconData,
              color: Theme.of(context).colorScheme.primary,
            ),
          )),
    );
  }
}
