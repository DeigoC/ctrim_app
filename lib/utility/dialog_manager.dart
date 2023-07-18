import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/user_avatar.dart';

class DialogManager {
  static void showUserProfile({required User selectedUser, required BuildContext context}) {
    Widget buildVerticalUserViewer(final User selectedUser) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: MyUserAvatar(
              selectedUser,
              radius: MediaQuery.of(context).size.width * 0.35,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            '${selectedUser.fullname} (${selectedUser.id})',
            style: const TextStyle(
              fontSize: 21,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            selectedUser.isAreaAdmin ? '${selectedUser.location} (Admin)' : selectedUser.location,
            style: const TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      );
    }

    Widget buildHorizontalUserViewer(final User selectedUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: MyUserAvatar(
              selectedUser,
              radius: MediaQuery.of(context).size.height * 0.35,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 16,
              ),
              Text(
                '${selectedUser.fullname} (${selectedUser.id})',
                style: const TextStyle(
                  fontSize: 21,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                selectedUser.isAreaAdmin ? '${selectedUser.location} (Admin)' : selectedUser.location,
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 32,
              ),
            ],
          ),
          const SizedBox(
            width: 16,
          ),
        ],
      );
    }

    showDialog(
        context: context,
        builder: (_) {
          return OrientationBuilder(builder: (context, orientation) {
            return Dialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32))),
              child: SingleChildScrollView(
                  child: orientation == Orientation.portrait
                      ? buildVerticalUserViewer(selectedUser)
                      : buildHorizontalUserViewer(selectedUser)),
            );
          });
        });
  }
}
