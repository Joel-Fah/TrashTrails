import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:trashtrails/controllers/controllers.dart';
import 'package:trashtrails/ui/components/default_snack_bar.dart';
import 'package:trashtrails/ui/pages/reports/my_reports.dart';
import 'package:trashtrails/utils/constants.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../controllers/auth_controller.dart';
import '../components/user_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String routeName = "/profile";

  @override
  Widget build(BuildContext context) {
    // GetX Controllers
    final AuthController authController = Get.find<AuthController>();
    final ReportController reportController = Get.find<ReportController>();

    final user = authController.currentUser;

    debugPrint("User Infooo  >>> ${authController.currentUser}");

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Avatar et stats
          Row(
            children: [
              UserAvatar(
                tag: 'user_avatar',
                imageUrl: user?.avatarUrl,
                name: user?.displayName,
                initials: user?.initials,
                radius: 48.0,
              ),
              const Gap(24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(label: "Trails", value: reportController.userReports.length.toString()),
                  const Gap(32.0),
                  _StatItem(
                    label: "Joined",
                    value: dateFormatter(user?.dateJoined ?? DateTime.now()),
                  ),
                ],
              ),
            ],
          ),
          const Gap(32.0),

          // Auth provider headline
          Text(
            "Authentication Provider",
            style: AppTextStyles.body.copyWith(color: greyColor),
          ),
          const Gap(8.0),

          // Auth provider info
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: infoColor.withValues(alpha: 0.1),
              borderRadius: borderRadius * 4.0,
            ),
            child: ListTile(
              leading: SvgPicture.asset(
                googleIconColor,
                width: 32.0,
                height: 32.0,
              ),
              title: Text(
                "Google",
                style: AppTextStyles.h3.copyWith(color: infoColor),
              ),
              subtitle: Text(
                "You joined TrashTrails with your Google Account. To update your displayed info, get to your Google account.",
                style: AppTextStyles.body.copyWith(
                  color: greyColor,
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
          const Gap(32.0),
          Text(
            "Account actions",
            style: AppTextStyles.body.copyWith(color: greyColor),
          ),
          const Gap(8.0),
          ListTile(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.pushNamed(
                removeLeadingSlash(MyReportsFeedPage.routeName),
              );
            },
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedInvoice01,
              color: seedColor,
            ),
            title: Text("My Reports"),
            trailing: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowUpRight01,
              color: seedColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Divider(color: greyColor, thickness: 0.5),
          ),
          // Logout button
          ListTile(
            onTap: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return Padding(
                    padding: EdgeInsets.all(16.0).copyWith(
                      bottom: MediaQuery.paddingOf(context).bottom + 16.0,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: seedPalette.shade50,
                        borderRadius: borderRadius * 3.0,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Are you sure you want to logout?",
                            style: AppTextStyles.h2,
                          ),
                          const Gap(8.0),
                          Text(
                            "Are you sure you want to log out? You will be redirected to the login page and will need to enter your credentials again to access your dashboard. All active sessions will be terminated",
                            style: AppTextStyles.body,
                          ),
                          const Gap(16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16.0,
                                    horizontal: 24.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: borderRadius * 2.25,
                                  ),
                                ),
                                onPressed: () => context.pop(),
                                child: Text("Cancel"),
                              ),
                              const Gap(16.0),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: errorColor,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16.0,
                                    horizontal: 24.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: borderRadius * 2.25,
                                  ),
                                ),
                                onPressed: authController.isLoading
                                    ? null
                                    : () async {
                                        await authController.signOut().then((
                                          value,
                                        ) {
                                          if (value) {
                                            // Show success message
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                buildSnackBar(
                                                  backgroundColor: successColor,
                                                  prefixIcon: HugeIcon(
                                                    icon: successIcon,
                                                    color: lightColor,
                                                  ),
                                                  label: Text(
                                                    "Account successfully logged out",
                                                  ),
                                                ),
                                              );
                                          } else {
                                            // Show success error message
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                buildSnackBar(
                                                  backgroundColor: errorColor,
                                                  prefixIcon: HugeIcon(
                                                    icon: errorIcon,
                                                    color: lightColor,
                                                  ),
                                                  label: Text(
                                                    "There was an error logging out",
                                                  ),
                                                ),
                                              );
                                          }
                                        });
                                        context.pop();
                                      },
                                child: authController.isLoading
                                    ? LoadingAnimationWidget.staggeredDotsWave(
                                        color: lightColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        size: 32.0,
                                      )
                                    : Text("Yes, logout"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            splashColor: errorColor.withValues(alpha: 0.1),
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              color: errorColor,
            ),
            title: Text(
              "Logout",
              style: AppTextStyles.h3.copyWith(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4.0,
      children: [
        Text(value, style: AppTextStyles.h4.copyWith(color: darkColor)),
        Text(label, style: AppTextStyles.small),
      ],
    );
  }
}
