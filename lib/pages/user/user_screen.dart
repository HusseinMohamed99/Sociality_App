import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/foundation.dart';
import 'package:sociality/model/user_model.dart';
import 'package:sociality/pages/chat/private_chat.dart';
import 'package:sociality/pages/friend/profile_screen.dart';
import 'package:sociality/shared/components/navigator.dart';
import 'package:sociality/shared/cubit/socialCubit/social_cubit.dart';
import 'package:sociality/shared/cubit/socialCubit/social_state.dart';
import 'package:sociality/shared/components/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_fonts/google_fonts.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      SocialCubit.get(context).getFriendRequest();
      SocialCubit.get(context).getAllUsers();
      SocialCubit.get(context)
          .getFriends(SocialCubit.get(context).userModel!.uId);
      return BlocConsumer<SocialCubit, SocialStates>(
        listener: (context, state) {},
        builder: (context, state) {
          List<UserModel> peopleYouMayKnow =
              SocialCubit.get(context).users.cast<UserModel>();
          List<UserModel> friendRequests =
              SocialCubit.get(context).friendRequests.cast<UserModel>();
          List<UserModel> friends =
              SocialCubit.get(context).friends.cast<UserModel>();
          return SocialCubit.get(context).users.isEmpty
              ? Scaffold(
                  body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            IconlyLight.user3,
                            size: 70,
                            color: Colors.grey,
                          ),
                          Center(
                            child: Text(
                              'No Users Yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ]),
                  ),
                )
              : Scaffold(
                  body: RefreshIndicator(
                    onRefresh: onRefresh,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            Text(
                              'friend Request',
                              style: GoogleFonts.lobster(
                                fontSize: 16,
                                color: SocialCubit.get(context).isDark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                            ConditionalBuilder(
                                condition: friendRequests.isNotEmpty,
                                builder: (context) => ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) =>
                                          friendRequestBuildItem(
                                              context, friendRequests[index]),
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(width: 10),
                                      itemCount: friendRequests.length,
                                    ),
                                fallback: (context) => Container(
                                      padding: const EdgeInsetsDirectional.only(
                                          top: 15, bottom: 5),
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        'NoFriendRequest',
                                        style: GoogleFonts.lobster(
                                          fontSize: 16,
                                          color: SocialCubit.get(context).isDark
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    )),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'peopleMayKnow',
                              style: GoogleFonts.lobster(
                                fontSize: 16,
                                color: SocialCubit.get(context).isDark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              height: 330,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  return peopleMayKnow(
                                      context, peopleYouMayKnow[index], index);
                                },
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 10),
                                itemCount: peopleYouMayKnow.length,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'friends',
                              style: GoogleFonts.lobster(
                                fontSize: 16,
                                color: SocialCubit.get(context).isDark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ConditionalBuilder(
                              condition: friends.isNotEmpty,
                              builder: (context) => ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (context, index) =>
                                    friendBuildItem(context, friends[index]),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(
                                  height: 10,
                                ),
                                itemCount: friends.length,
                              ),
                              fallback: (context) => Container(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 15, bottom: 5),
                                  alignment: AlignmentDirectional.center,
                                  child: Text(
                                    'No Friends',
                                    style: GoogleFonts.lobster(
                                      fontSize: 16,
                                      color: SocialCubit.get(context).isDark
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
        },
      );
    });
  }

  Future<void> onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    SocialCubit.get(BuildContext).getUserData();
    SocialCubit.get(BuildContext).getFriendRequest();
    SocialCubit.get(BuildContext).getAllUsers();
    SocialCubit.get(BuildContext)
        .getFriends(SocialCubit.get(BuildContext).userModel!.uId);
  }

  Widget friendBuildItem(context, UserModel userModel) {
    return InkWell(
      onTap: () {
        Navigator.of(context).build(context);
        navigateTo(context, FriendsProfileScreen(userModel.uId));
      },
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(userModel.image),
              radius: 27,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                userModel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lobster(
                  fontSize: 16,
                  color: SocialCubit.get(context).isDark
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                    SocialCubit.get(context).isDark
                        ? Colors.blue
                        : Colors.white,
                  )),
                  onPressed: () => navigateTo(
                      context, PrivateChatScreen(userModel: userModel)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconlyBroken.chat,
                        color: SocialCubit.get(context).isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        'message',
                        style: GoogleFonts.lobster(
                          fontSize: 16,
                          color: SocialCubit.get(context).isDark
                              ? Colors.white
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget peopleMayKnow(context, UserModel userModel, index) {
    return Container(
      height: 350,
      width: 230,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green, style: BorderStyle.solid)),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
              onTap: () {
                SocialCubit.get(context).getFriends(userModel.uId);
                SocialCubit.get(context).checkFriends(userModel.uId);
                SocialCubit.get(context).checkFriendRequest(userModel.uId);
                navigateTo(context, FriendsProfileScreen(userModel.uId));
              },
              child: Image(
                image: NetworkImage(userModel.image),
                height: 200,
                width: 230,
                fit: BoxFit.fill,
              )),
          space(0, 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userModel.name,
                  style: GoogleFonts.lobster(
                    fontSize: 16,
                    color: SocialCubit.get(context).isDark
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                space(0, 5),
                Text(
                  userModel.bio,
                  style: GoogleFonts.lobster(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          space(0, 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blueAccent),
                            padding:
                                MaterialStateProperty.all(EdgeInsets.zero)),
                        onPressed: () {
                          SocialCubit.get(context).sendFriendRequest(
                            friendsUID: userModel.uId,
                            friendName: userModel.name,
                            friendImage: userModel.image,
                          );
                          SocialCubit.get(context).sendInAppNotification(
                            contentKey: 'friendRequest',
                            contentId: userModel.uId,
                            content: 'sent you a friend request, check it out!',
                            receiverId: userModel.uId,
                            receiverName: userModel.name,
                          );
                          SocialCubit.get(context).sendFCMNotification(
                              token: userModel.uId,
                              senderName:
                                  SocialCubit.get(context).userModel!.name,
                              messageText:
                                  '${SocialCubit.get(context).userModel!.name}'
                                  'sent you a friend request, check it out!');
                        },
                        child: SocialCubit.get(context).isFriend == false
                            ? SocialCubit.get(context).request
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text('requestSent',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text('addFriend',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    'profileFriends',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget friendRequestBuildItem(context, UserModel userModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              navigateTo(context, FriendsProfileScreen(userModel.uId));
              if (kDebugMode) {
                print(userModel.uId);
              }
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(userModel.image),
              radius: 45,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userModel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle()),
                Text(
                  userModel.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blueAccent),
                            fixedSize: MaterialStateProperty.all(
                                const Size.fromWidth(120))),
                        onPressed: () {
                          SocialCubit.get(context).addFriend(
                            friendsUID: userModel.uId,
                            friendName: userModel.name,
                            friendImage: userModel.image,
                            friendCover: userModel.cover,
                            friendBio: userModel.bio,
                            friendEmail: userModel.email,
                            friendPhone: userModel.phone,
                          );
                          SocialCubit.get(context)
                              .deleteFriendRequest(userModel.uId);
                          SocialCubit.get(context).sendInAppNotification(
                            contentKey: 'friendRequestAccepted',
                            contentId: SocialCubit.get(context).userModel!.uId,
                            content:
                                'accepted your friend request, you are now friends checkout his profile',
                            receiverId: userModel.uId,
                            receiverName: userModel.name,
                          );
                          SocialCubit.get(context).sendFCMNotification(
                              token: userModel.uId,
                              senderName:
                                  SocialCubit.get(context).userModel!.name,
                              messageText:
                                  '${SocialCubit.get(context).userModel!.name}'
                                  'accepted your friend request, you are now friends checkout his profile');
                        },
                        child: const Text('Confirm',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: OutlinedButton(
                          style: ButtonStyle(
                              fixedSize: MaterialStateProperty.all(
                                  const Size.fromWidth(120))),
                          onPressed: () {
                            SocialCubit.get(context)
                                .deleteFriendRequest(userModel.uId);
                          },
                          child: const Text('Delete')),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
