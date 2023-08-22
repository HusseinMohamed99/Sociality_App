import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:sociality/pages/chat/chat_screen.dart';
import 'package:sociality/pages/feed/feedscreen.dart';
import 'package:sociality/pages/setting/setting_screen.dart';
import 'package:sociality/pages/user/users_screen.dart';
import 'package:sociality/model/comment_model.dart';
import 'package:sociality/model/likes_model.dart';
import 'package:sociality/model/message_model.dart';
import 'package:sociality/model/notifications_model.dart';
import 'package:sociality/model/post_model.dart';
import 'package:sociality/model/story_model.dart';
import 'package:sociality/model/user_model.dart';
import 'package:sociality/pages/on-boarding/on_boarding_screen.dart';
import 'package:sociality/pages/story/create_story.dart';
import 'package:sociality/pages/story/stories_screen.dart';
import 'package:sociality/shared/components/constants.dart';
import 'package:sociality/shared/components/navigator.dart';
import 'package:sociality/shared/components/show_toast.dart';
import 'package:sociality/shared/cubit/socialCubit/social_state.dart';
import 'package:sociality/shared/network/cache_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:sociality/shared/styles/color.dart';

class SocialCubit extends Cubit<SocialStates> {
  SocialCubit() : super(SocialInitialState());
  static SocialCubit get(context) => BlocProvider.of(context);

  // ----------------------------------------------------------//
  ///START : Screens
  int currentIndex = 0;
  List<Widget> screens = const [
    FeedScreen(),
    ChatScreen(),
    UserScreen(),
    StoryScreen(),
    SettingScreen(),
  ];
  List<BottomNavigationBarItem> bottomNavigationBarItem = const [
    BottomNavigationBarItem(icon: Icon(IconlyBroken.home), label: ''),
    BottomNavigationBarItem(icon: Icon(IconlyBroken.message), label: ''),
    BottomNavigationBarItem(icon: Icon(IconlyBroken.user3), label: ''),
    BottomNavigationBarItem(icon: Icon(IconlyBroken.upload), label: ''),
    BottomNavigationBarItem(icon: Icon(IconlyBroken.setting), label: ''),
  ];

  ///END : Screens

  // ----------------------------------------------------------//

  ///START : Titles
  List<String> titles = [
    'Feed',
    'Chat',
    'User',
    'Story',
    'Setting',
  ];

  ///END : Titles

  // ----------------------------------------------------------//

  ///START : ChangeTabBar
  void changeNavBar(int index) {
    currentIndex = index;
    if (index == 0) {
      getUserStories(userModel!.uId);
      getUserData();
      getStories();
      getAllUsers();
      getPosts();
      getFriendsProfile(postModel!.uId);
      getUserPosts(postModel!.uId);
    }
    if (index == 1) {
      getAllUsers();
    }
    if (index == 2) {
      getFriends(userModel!.uId);
      getFriendRequest();
    }
    if (index == 3) {
      getUserStories(userModel!.uId);
    }
    if (index == 4) {
      getUserData();
    }
    emit(SocialChangeTabBarState());
  }

  ///START : GetUserData
  UserModel? userModel;
  void getUserData() {
    emit(GetUserDataLoadingState());
    FirebaseFirestore.instance.collection('users').doc(uId).get().then((value) {
      userModel = UserModel.fromJson(value.data()!);
      if (kDebugMode) {
        print(userModel!.uId);
      }
      emit(GetUserDataSuccessState());
    }).catchError((error) {
      debugPrint(error.toString());
      emit(GetUserDataErrorState(error.toString()));
    });
  }

  ///END : GetUserData

// ----------------------------------------------------------//
  ///START : GetAllUsers
  List<UserModel> users = [];
  void getAllUsers() {
    emit(GetAllUsersLoadingState());
    FirebaseFirestore.instance.collection('users').get().then((event) {
      users = [];
      for (var element in event.docs) {
        if (element.data()['uId'] != userModel!.uId) {
          users.add(UserModel.fromJson(element.data()));
        }
      }

      emit(GetAllUsersSuccessState());
    }).catchError((error) {
      emit(GetAllUsersErrorState(error.toString()));
    });
  }

  ///END : GetAllUsers

  // ----------------------------------------------------------//
  ///START : setUserToken
  void setUserToken() async {
    emit(SetUSerTokenLoadingState());
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint(' token $token');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .update({'token': token}).then(
            (value) => emit(SetUSerTokenSuccessState()));
  }

  ///END : setUserToken

  // ----------------------------------------------------------//

  ///START : ChangeMode
  bool isDark = false;
  Color backgroundColor = AppMainColors.whiteColor;

  void changeAppMode({bool? fromShared}) {
    if (fromShared == null) {
      isDark = !isDark;
    } else {
      isDark = fromShared;
    }
    CacheHelper.putBoolean(key: 'isDark', value: isDark).then((value) {
      if (isDark) {
        backgroundColor = AppColorsDark.primaryDarkColor;
        emit(ChangeThemeState());
      } else {
        backgroundColor = Colors.white;
        emit(ChangeThemeState());
      }
      emit(ChangeThemeState());
    });
  }

  ///END : ChaneMode

  ///START : GetProfileImage
  var picker = ImagePicker();
  File? profileImage;

  Future<void> getProfileImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      profileImage = File(pickedFile.path);
      profileImage = await cropImage(imageFile: profileImage!);
      emit(GetProfileImagePickedSuccessState());
    } else {
      debugPrint('No image selected');
      emit(GetProfileImagePickedErrorState());
    }
  }

  ///END : GetProfileImage

  ///START : GetCoverImage
  File? coverImage;
  Future<void> getCoverImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      coverImage = File(pickedFile.path);
      coverImage = await cropImage(imageFile: coverImage!);
      emit(GetCoverImagePickedSuccessState());
    } else {
      debugPrint('No image selected');
      emit(GetCoverImagePickedErrorState());
    }
  }

  Future<File?> cropImage({required File imageFile}) async {
    CroppedFile? croppedImage =
        await ImageCropper().cropImage(sourcePath: imageFile.path);
    if (croppedImage != null) {
      return File(croppedImage.path);
    }
    return null;
  }

  ///END : GetCoverImage

  ///START : UploadProfileImage

  void uploadProfileImage({
    required String email,
    required String phone,
    required String name,
    required String bio,
  }) {
    emit(UpdateUserLoadingState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child(
            'userProfileImage/${Uri.file(profileImage!.path).pathSegments.last}')
        .putFile(profileImage!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        updateUserData(
          email: email,
          phone: phone,
          name: name,
          bio: bio,
          image: value,
        );
      }).catchError((error) {
        emit(UploadProfileImageErrorState());
      });
    }).catchError((error) {
      emit(UploadProfileImageErrorState());
    });
  }

  ///END : UploadProfileImage

  ///START : UploadCoverImage

  void uploadCoverImage({
    required String email,
    required String phone,
    required String name,
    required String bio,
  }) {
    emit(UpdateUserLoadingState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child('userCoverImage/${Uri.file(coverImage!.path).pathSegments.last}')
        .putFile(coverImage!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        updateUserData(
          email: email,
          phone: phone,
          name: name,
          bio: bio,
          cover: value,
        );
      }).catchError((error) {
        emit(UploadCoverImageErrorState());
      });
    }).catchError((error) {
      emit(UploadCoverImageErrorState());
    });
  }

  ///END : UploadCoverImage

  ///START : UploadProfileAndCoverImage

  void uploadProfileAndCoverImage({
    required String email,
    required String phone,
    required String name,
    required String bio,
  }) {
    emit(UpdateUserLoadingState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child(
            'userProfileImage/${Uri.file(profileImage!.path).pathSegments.last}')
        .putFile(profileImage!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        updateUserData(
          email: email,
          phone: phone,
          name: name,
          bio: bio,
          image: value,
        );
      }).catchError((error) {
        emit(UploadProfileImageErrorState());
      });
    }).catchError((error) {
      emit(UploadProfileImageErrorState());
    });

    firebase_storage.FirebaseStorage.instance
        .ref()
        .child('userCoverImage/${Uri.file(coverImage!.path).pathSegments.last}')
        .putFile(coverImage!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        updateUserData(
          email: email,
          phone: phone,
          name: name,
          bio: bio,
          cover: value,
        );
      }).catchError((error) {
        emit(UploadCoverImageErrorState());
      });
    }).catchError((error) {
      emit(UploadCoverImageErrorState());
    });
  }

  ///END : UploadProfileAndCoverImage

// ----------------------------------------------------------//

  ///START : UpdateUserData
  void updateUserData({
    required String email,
    required String phone,
    required String name,
    required String bio,
    String? image,
    String? cover,
  }) {
    emit(UpdateUserLoadingState());
    UserModel model = UserModel(
      email: email,
      phone: phone,
      name: name,
      bio: bio,
      cover: cover ?? userModel!.cover,
      image: image ?? userModel!.image,
      uId: userModel!.uId,
      isEmailVerified: false,
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .update(model.toMap())
        .then((value) {
      getUserData();
    }).catchError((error) {
      emit(UpdateUserErrorState());
    });
  }

  ///END : UpdateUserData

// ----------------------------------------------------------//
  ///START : GetPostImage
  File? postImagePicked;
  Future<void> getPostImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      postImagePicked = File(pickedFile.path);
      emit(GetPostImagePickedSuccessState());
    } else {
      debugPrint('No image selected');
      emit(GetPostImagePickedErrorState());
    }
  }

  ///END : GetPostImage

  // ----------------------------------------------------------//
  ///START : uploadPostImage
  void uploadPostImage({
    required String dateTime,
    required String text,
  }) {
    emit(CreatePostLoadingState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child('postImage/${Uri.file(postImagePicked!.path).pathSegments.last}')
        .putFile(postImagePicked!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        createPost(
          dateTime: dateTime,
          text: text,
          postImage: value,
        );

        emit(CreatePostSuccessState());
      }).catchError((error) {
        emit(CreatePostErrorState());
      });
    }).catchError((error) {
      emit(CreatePostErrorState());
    });
  }

  ///END : uploadPostImage

// ----------------------------------------------------------//

  ///START : CreatePost
  void createPost({
    required String dateTime,
    required String text,
    String? postImage,
  }) {
    emit(CreatePostLoadingState());

    PostModel model = PostModel(
      uId: userModel!.uId,
      image: userModel!.image,
      name: userModel!.name,
      text: text,
      postImage: postImage ?? '',
      dateTime: dateTime,
    );
    FirebaseFirestore.instance
        .collection('posts')
        .add(model.toMap())
        .then((value) {
      emit(CreatePostSuccessState());
    }).catchError((error) {
      emit(CreatePostErrorState());
    });
  }

  ///END : CreatePost

// ----------------------------------------------------------//

  ///START : RemovePostImage
  void removePostImage() {
    postImagePicked = null;

    emit(RemovePostImageSuccessState());
  }

  ///END : RemovePostImage

// ----------------------------------------------------------//

  ///START : GetAllPosts
  List<PostModel> posts = [];
  List<String> postsId = [];
  List<int> commentsNum = [];
  PostModel? postModel;
  void getPosts() {
    FirebaseFirestore.instance
        .collection('posts')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .listen((event) async {
      posts = [];
      event.docs.forEach((element) async {
        posts.add(PostModel.fromJson(element.data()));
        postsId.add(element.id);
        var likes = await element.reference.collection('likes').get();
        var comments = await element.reference.collection('comments').get();
        commentsNum.add(element.id.length);
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(element.id)
            .update({
          'likes': likes.docs.length,
          'comments': comments.docs.length,
          'postId': element.id,
        });
      });
      emit(GetPostsSuccessState());
    });
  }

  ///END : GetAllPosts

// ----------------------------------------------------------//
  ///START : GetMyPosts
  List<PostModel> userPosts = [];
  void getUserPosts(String? userID) {
    FirebaseFirestore.instance
        .collection('posts')
        .orderBy('dateTime')
        .snapshots()
        .listen((event) {
      userPosts = [];
      for (var element in event.docs) {
        if (element.data()['uId'] == userID) {
          userPosts.add(PostModel.fromJson(element.data()));
        }
      }
      emit(GetUserPostsSuccessState());
    });
  }

  ///END : GetMyPosts

// ----------------------------------------------------------//
  ///START : Likes

  Future<bool> likeByMe({
    context,
    String? postId,
    PostModel? postModel,
    UserModel? postUser,
    required String dataTime,
  }) async {
    emit(LikedByMeCheckedLoadingState());
    bool isLikedByMe = false;
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get()
        .then((event) async {
      var likes = await event.reference.collection('likes').get();
      for (var element in likes.docs) {
        if (element.id == userModel!.uId) {
          isLikedByMe = true;
          disLikePost(postId!);
        }
      }
      if (isLikedByMe == false) {
        likePosts(
          postId: postId,
          context: context,
          postModel: postModel,
          postUser: postUser,
          dateTime: dataTime,
        );
      }
      if (kDebugMode) {
        print(isLikedByMe);
      }
      emit(LikedByMeCheckedSuccessState());
    });
    return isLikedByMe;
  }

  void likePosts({
    context,
    String? postId,
    PostModel? postModel,
    UserModel? postUser,
    required String dateTime,
  }) {
    LikesModel likesModel = LikesModel(
      uId: userModel!.uId,
      name: userModel!.name,
      image: userModel!.image,
      dateTime: dateTime,
    );
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userModel!.uId)
        .set(likesModel.toMap())
        .then((value) {
      getPosts();
      if (postModel!.uId != userModel!.uId) {
        SocialCubit.get(context).sendInAppNotification(
            receiverName: postUser!.name,
            receiverId: postModel.uId,
            contentId: postModel.uId,
            contentKey: 'likePost');
        SocialCubit.get(context).sendFCMNotification(
          token: postUser.uId,
          senderName: SocialCubit.get(context).userModel!.name,
          messageText: '${SocialCubit.get(context).userModel!.name}'
              ' likes a post you shared',
        );
      }
      emit(LikesSuccessState());
    }).catchError((error) {
      if (kDebugMode) {
        print(error.toString());
      }
      emit(LikesErrorState(error.toString()));
    });
  }

  ///END : Likes

// ----------------------------------------------------------//
  ///START : DisLikes
  void disLikePost(String postId) {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userModel!.uId)
        .delete()
        .then((value) {
      getPosts();
      emit(DisLikesSuccessState());
    }).catchError((error) {
      emit(DisLikesErrorState(error.toString()));
    });
  }

  ///END : DisLikes

//-----------------------------------------------------------//
  ///START : WhoLikes
  List<LikesModel> peopleReacted = [];
  void getLikes(
    String? postId,
  ) {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .snapshots()
        .listen((value) {
      peopleReacted = [];
      for (var element in value.docs) {
        peopleReacted.add(LikesModel.fromJson(element.data()));
      }
      emit(GetLikedUsersSuccessState());
    });
  }

  ///END : WhoLikes

// ----------------------------------------------------------//
  ///END : GetComments
  List<CommentModel> comments = [];
  void getComments(
    String? postId,
  ) {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .listen((event) {
      comments = [];
      for (var element in event.docs) {
        comments.add(CommentModel.fromJson(element.data()));
      }
    });
    emit(GetCommentsSuccessState());
  }

  ///END : GetComments

// ----------------------------------------------------------//

  ///START : SendComment
  CommentModel? comment;
  void sendComment({
    String? dateTime,
    String? text,
    String? postId,
  }) {
    CommentModel comment = CommentModel(
        dateTime: dateTime,
        uId: userModel!.uId,
        comment: text,
        image: userModel!.image,
        name: userModel!.name);

    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(comment.toMap())
        .then((value) {
      emit(SendCommentSuccessState());
    }).catchError((error) {
      emit(SendCommentErrorState());
      debugPrint(error.toString());
    });
  }

  ///END : SendComment

// ----------------------------------------------------------//
  ///START : SaveToGallery
  void saveToGallery(String imageUrl) {
    emit(SavedToGalleryLoadingState());
    GallerySaver.saveImage(imageUrl, albumName: 'Sociality-APP').then((value) {
      emit(SavedToGallerySuccessState());
    }).catchError((error) {
      debugPrint("${error.toString()} from saveToGallery");
      emit(SavedToGalleryErrorState());
    });
  }

  ///END : SaveToGallery

// ----------------------------------------------------------//
  ///START : EditPost
  void editPost(
      {required String dateTime,
      required PostModel postModel,
      required String postId,
      required String text,
      String? postImage}) {
    emit(EditPostLoadingState());
    postModel = PostModel(
        uId: postModel.uId,
        dateTime: postModel.dateTime,
        text: text,
        postImage: postImage ?? postModel.postImage);
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update(postModel.toMap())
        .then((value) {
      emit(EditPostSuccessState());
    }).catchError((error) {
      debugPrint("${error.toString()} from urlUpdatePost");
      emit(EditPostErrorState());
    });
  }

  ///END : EditPost

// ----------------------------------------------------------//
  ///START : EditPostWithImage
  void editPostWithImage({
    required String dateTime,
    required PostModel postModel,
    required String postId,
    required String text,
    String? postImage,
  }) {
    emit(EditPostLoadingState());

    firebase_storage.FirebaseStorage.instance
        .ref()
        .child(
            'editedPosts/${Uri.file(postImagePicked!.path).pathSegments.last}')
        .putFile(postImagePicked!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        editPost(
          postModel: postModel,
          postId: postId,
          text: text,
          postImage: value,
          dateTime: dateTime,
        );
      }).catchError((error) {
        emit(EditPostErrorState());
      });
    }).catchError((error) {
      emit(EditPostErrorState());
    });
  }

  ///END : EditPostWithImage

// ----------------------------------------------------------//
  ///START : DeleteAccount
  void deleteAccount(context) async {
    await FirebaseAuth.instance.currentUser!.delete().then((value) async {
      await FirebaseFirestore.instance.collection('users').doc(uId).delete();
      CacheHelper.removeData(key: 'uId');
      navigateAndFinish(context, const OnBoard());
    });
  }

  ///END : DeleteAccount

// ----------------------------------------------------------//
  ///START : DeletePost
  void deletePost(String? postId) {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .delete()
        .then((value) {
      showToast(text: 'Post Deleted', state: ToastStates.success);
      emit(DeletePostSuccessState());
    });
  }

  ///END : DeletePost

// ----------------------------------------------------------//
  ///START : ChangeUserPassword
  void changeUserPassword({
    required String password,
  }) {
    emit(ChangeUserPasswordLoadingState());
    FirebaseAuth.instance.currentUser?.updatePassword(password).then((value) {
      showToast(
        state: ToastStates.success,
        text: 'Change Successful',
      );
      emit(ChangeUserPasswordSuccessState());
      getUserData();
    }).catchError((error) {
      showToast(
        state: ToastStates.error,
        text: 'process failed\nYou Should Re-login Before Change Password',
      );
      emit(ChangeUserPasswordErrorState(error.toString()));
      debugPrint(error.toString());
    });
  }

  ///END : ChangeUserPassword

// ----------------------------------------------------------//
  ///START : Show Password
  IconData suffix = Icons.visibility_outlined;
  bool isPassword = true;
  void showPassword() {
    isPassword = !isPassword;
    suffix =
        isPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined;

    emit(ShowPasswordState());
  }

  ///END : Show Password

//------------------------------------------------------------//
  ///START : sendMessage
  MessageModel? messageModel;
  void sendMessage({
    required String receiverId,
    required String dateTime,
    String? text,
    String? messageImage,
  }) {
    MessageModel model = MessageModel(
      receiverId: receiverId,
      dateTime: dateTime,
      text: text ?? '',
      senderId: userModel!.uId,
      messageImage: messageImage ?? '',
    );

    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('chat')
        .doc(receiverId)
        .collection('message')
        .add(model.toMap())
        .then((value) {
      emit(SendMessageSuccessState());
    }).catchError((error) {
      emit(SendMessageErrorState());
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('chat')
        .doc(userModel!.uId)
        .collection('message')
        .add(model.toMap())
        .then((value) {
      emit(SendMessageSuccessState());
    }).catchError((error) {
      emit(SendMessageErrorState());
    });
  }

  ///END : sendMessage

//------------------------------------------------------------//
  ///START : getMessage
  List<MessageModel> message = [];

  void getMessage({
    required String receiverId,
  }) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('chat')
        .doc(receiverId)
        .collection('message')
        .orderBy('dateTime')
        .snapshots()
        .listen((event) {
      message = [];
      for (var element in event.docs) {
        message.add(MessageModel.fromJson(element.data()));
      }
      emit(GetMessageSuccessState());
    });
  }

  ///END : getMessage

//------------------------------------------------------------//
  ///START : get Message Image
  bool messageImageSelected = false;
  File? messageImagePicked;

  Future<void> getMessageImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      messageImagePicked = File(pickedFile.path);

      emit(MessageImagePickedSuccessState());
      messageImageSelected = true;
    } else {
      debugPrint('No image selected.');
      emit(MessageImagePickedErrorState());
    }
  }

  ///END : get Message Image

  //------------------------------------------------------------//
  ///START : remove Message Image
  void removeMessageImage() {
    messageImagePicked = null;
    emit(DeleteMessageImageSuccessState());
  }

  ///END : remove Message Image

  //------------------------------------------------------------//
  ///START : upload Message Image
  void uploadMessageImage({
    required String? receiverId,
    required String? datetime,
    required String? text,
  }) {
    emit(UploadMessageImageLoadingState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child(
            'messagesImage/${Uri.file(messageImagePicked!.path).pathSegments.last}')
        .putFile(messageImagePicked!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        sendMessage(
            dateTime: datetime!,
            text: text,
            messageImage: value,
            receiverId: receiverId!);
      }).catchError((error) {
        emit(UploadMessageImageErrorState());
      });
    }).catchError((error) {
      emit(UploadMessageImageErrorState());
    });
  }

  ///END : upload Message Image

//------------------------------------------------------------//
  ///START : getFriendsProfile
  UserModel? friendsProfile;

  void getFriendsProfile(String? friendsUID) {
    emit(GetFriendProfileLoadingState());
    FirebaseFirestore.instance.collection('users').snapshots().listen((value) {
      for (var element in value.docs) {
        if (element.data()['uId'] == friendsUID) {
          friendsProfile = UserModel.fromJson(element.data());
        }
      }
      emit(GetFriendProfileSuccessState());
    });
  }

  ///END : getFriendsProfile

  //------------------------------------------------------------//
  ///START : addFriend
  void addFriend({
    required String friendsUID,
    required String friendName,
    required String friendImage,
    required String friendPhone,
    required String friendEmail,
    required String friendCover,
    required String friendBio,
  }) {
    emit(AddFriendLoadingState());
    UserModel myFriendModel = UserModel(
      uId: friendsUID,
      name: friendName,
      image: friendImage,
      phone: friendPhone,
      email: friendEmail,
      cover: friendCover,
      bio: friendBio,
      isEmailVerified: userModel!.isEmailVerified,
    );
    UserModel myModel = UserModel(
      uId: userModel!.uId,
      name: userModel!.name,
      image: userModel!.image,
      cover: userModel!.cover,
      bio: userModel!.bio,
      phone: userModel!.phone,
      email: userModel!.email,
      isEmailVerified: userModel!.isEmailVerified,
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('friends')
        .doc(friendsUID)
        .set(myFriendModel.toMap())
        .then((value) {
      emit(AddFriendSuccessState());
    }).catchError((error) {
      debugPrint(error.toString());
      emit(AddFriendErrorState());
    });
    FirebaseFirestore.instance
        .collection('users')
        .doc(friendsUID)
        .collection('friends')
        .doc(userModel!.uId)
        .set(myModel.toMap())
        .then((value) {
      emit(AddFriendSuccessState());
    }).catchError((error) {
      debugPrint(error.toString());
      emit(AddFriendErrorState());
    });
  }

  ///END : addFriend

  //------------------------------------------------------------//
  ///START : getFriends
  List<UserModel> friends = [];
  void getFriends(String? userUID) {
    emit(GetFriendLoadingState());
    FirebaseFirestore.instance
        .collection('users')
        .doc(userUID)
        .collection('friends')
        .snapshots()
        .listen((value) {
      friends = [];
      for (var element in value.docs) {
        friends.add(UserModel.fromJson(element.data()));
      }
      emit(GetFriendSuccessState());
    });
  }

  ///END : getFriends

  //------------------------------------------------------------//
  ///START : checkFriends
  bool isFriend = false;
  bool checkFriends(String? friendUID) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('friends')
        .snapshots()
        .listen((value) {
      isFriend = false;
      for (var element in value.docs) {
        if (friendUID == element.id) isFriend = true;
      }
      emit(CheckFriendSuccessState());
    });
    return isFriend;
  }

  ///END : checkFriends

  //------------------------------------------------------------//
  ///START : unFriend
  void unFriend(String? friendsUID) {
    emit(UnFriendLoadingState());
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('friends')
        .doc(friendsUID)
        .delete()
        .then((value) {
      emit(UnFriendSuccessState());
    }).catchError((error) {
      emit(UnFriendErrorState());
      debugPrint(error.toString());
    });
    FirebaseFirestore.instance
        .collection('users')
        .doc(friendsUID)
        .collection('friends')
        .doc(userModel!.uId)
        .delete()
        .then((value) {
      emit(UnFriendSuccessState());
    }).catchError((error) {
      emit(UnFriendErrorState());
      debugPrint(error.toString());
    });
  }

  ///END : unFriend

  //------------------------------------------------------------//
  ///START : sendFriendRequest
  void sendFriendRequest(
      {required String? friendsUID,
      required String? friendName,
      required String? friendImage}) {
    emit(FriendRequestLoadingState());
    UserModel friendRequestModel = UserModel(
      uId: userModel!.uId,
      name: userModel!.name,
      image: userModel!.image,
      bio: userModel!.bio,
      phone: userModel!.phone,
      email: userModel!.email,
      cover: userModel!.cover,
      isEmailVerified: userModel!.isEmailVerified,
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(friendsUID)
        .collection('friendRequests')
        .doc(userModel!.uId)
        .set(friendRequestModel.toMap())
        .then((value) {
      emit(FriendRequestSuccessState());
    }).catchError((error) {
      debugPrint(error.toString());
      emit(FriendRequestErrorState());
    });
  }

  ///END : sendFriendRequest

  //------------------------------------------------------------//
  ///START : getFriendRequest
  List<UserModel> friendRequests = [];
  void getFriendRequest() {
    emit(GetFriendLoadingState());
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('friendRequests')
        .snapshots()
        .listen((value) {
      friendRequests = [];
      for (var element in value.docs) {
        friendRequests.add(UserModel.fromJson(element.data()));

        emit(GetFriendSuccessState());
      }
    });
  }

  ///END : getFriendRequest

  //------------------------------------------------------------//
  ///START : checkFriendRequest
  bool request = false;
  bool checkFriendRequest(String? friendUID) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(friendUID)
        .collection('friendRequests')
        .get()
        .then((value) {
      for (var element in value.docs) {
        if (element.data()['uId'] == userModel!.uId) {
          request = true;
        } else {
          request = false;
        }
      }
      emit(CheckFriendRequestSuccessState());
    });
    return request;
  }

  ///END : checkFriendRequest

  //------------------------------------------------------------//
  ///START : deleteFriendRequest
  void deleteFriendRequest(String? friendsUID) {
    emit(DeleteFriendRequestLoadingState());
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('friendRequests')
        .doc(friendsUID)
        .delete()
        .then((value) {
      emit(DeleteFriendRequestSuccessState());
    }).catchError((error) {
      emit(DeleteFriendRequestErrorState());
      debugPrint(error.toString());
    });
  }

  ///END : deleteFriendRequest

//------------------------------------------------------------//
  ///START : getSinglePost
  PostModel? singlePost;

  void getSinglePost(String? postId) {
    emit(GetPostsLoadingState());
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get()
        .then((value) {
      singlePost = PostModel.fromJson(value.data()!);
      emit(GetSinglePostSuccessState());
    }).catchError((error) {
      emit(GetPostsErrorState(error.toString()));
    });
  }

  ///END : getSinglePost
  void deleteForEveryone(
      {required String? messageId, required String? receiverId}) async {
    var myDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('chat')
        .doc(receiverId)
        .collection('message')
        .limit(1)
        .where('messageId', isEqualTo: messageId)
        .get();
    myDocument.docs[0].reference.delete();

    var hisDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('chat')
        .doc(userModel!.uId)
        .collection('message')
        .limit(1)
        .where('messageId', isEqualTo: messageId)
        .get();
    hisDocument.docs[0].reference.delete();
  }

  void deleteForMe(
      {required String? messageId, required String? receiverId}) async {
    var myDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('chat')
        .doc(receiverId)
        .collection('message')
        .limit(1)
        .where('messageId', isEqualTo: messageId)
        .get();
    myDocument.docs[0].reference.delete();
  }

  //------------------------------------------------------------//
  ///START : getStories
  List<StoryModel> stories = [];
  void getStories() {
    emit(GetStoryLoadingState());
    FirebaseFirestore.instance
        .collection('stories')
        .orderBy('date')
        .snapshots()
        .listen((event) {
      stories = [];
      for (var element in event.docs) {
        stories.add(StoryModel.fromJson(element.data()));
      }
    });
    emit(GetStorySuccessState());
  }

  ///END : getStories

  //------------------------------------------------------------//
  ///START : getStoryImage
  File? storyImage;

  Future<void> getStoryImage(context) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      storyImage = File(pickedFile.path);
      storyImage = await cropImage(imageFile: storyImage!);
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const CreateStory()));
      emit(CreateStoryImagePickedSuccessState());
    } else {
      Navigator.pop(context);
      debugPrint("No image selected");
      emit(CreateStoryImagePickedErrorState());
    }
  }

  ///END : getStoryImage

  //------------------------------------------------------------//
  ///START : getStoryImage
  void createStoryImage({
    required DateTime dateTime,
    String? text,
  }) {
    emit(CreateStoryLoadingState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child('stories/${Uri.file(storyImage!.path).pathSegments.last}')
        .putFile(storyImage!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        uploadStory(dateTime: dateTime, text: text, storyImage: value);
        emit(CreateStorySuccessState());
        debugPrint(value);
      }).catchError((error) {
        emit(CreateStoryErrorState());
        debugPrint(error.toString());
      });
    }).catchError((error) {
      emit(CreateStoryErrorState());
      debugPrint(error.toString());
    });
  }

  ///END : getStoryImage

  //------------------------------------------------------------//
  ///START : uploadStory
  void uploadStory({
    required DateTime dateTime,
    String? text,
    required String storyImage,
  }) {
    StoryModel storyModel = StoryModel(
      uId: userModel!.uId,
      dateTime: dateTime,
      name: userModel!.name,
      text: text ?? "",
      storyImage: storyImage,
      image: userModel!.image,
    );

    FirebaseFirestore.instance
        .collection('stories')
        .add(storyModel.toMap())
        .then((value) {
      emit(CreateStorySuccessState());
    }).catchError((error) {
      debugPrint(error.toString());
      emit(CreateStoryErrorState());
    });
  }

  ///END : uploadStory

  //------------------------------------------------------------//
  ///START : removeStoryImage
  void removeStoryImage() {
    storyImage = null;
    emit(RemoveStoryImagePickedSuccessState());
  }

  ///START : removeStoryImage

  //------------------------------------------------------------//
  ///START : AddText
  bool addText = false;
  void addTextStory() {
    addText = !addText;
    emit(AddTextSuccessState());
  }

  ///END : AddText

  //------------------------------------------------------------//
  ///START : closeStory
  void closeStory(context) {
    pop(context);
    emit(CloseCreateStoryScreenState());
  }

  ///END : closeStory

  //------------------------------------------------------------//
  ///START : getPersonalStory
  List<StoryModel> userStories = [];
  void getUserStories(String? storyUID) {
    emit(CreateStoryLoadingState());
    userStories = [];
    for (var element in stories) {
      if (element.uId == userModel!.uId) userStories.add(element);
    }
    emit(GetStorySuccessState());
  }

  ///END : getPersonalStory

  //------------------------------------------------------------//
  ///START : searchUser
  List<UserModel> searchList = [];
  Map<String, dynamic>? search;
  void searchUser(String? searchText) {
    emit(SearchLoadingState());
    FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: searchText)
        .get()
        .then((value) {
      search = value.docs[0].data();
      emit(SearchSuccessState());
    }).catchError((error) {
      debugPrint(error.toString());
      emit(SearchErrorState(error.toString()));
    });
  }

  ///END : searchUser

  //------------------------------------------------------------//
  ///START : sendFCMNotification
  String? imageURL;
  Future<void> sendFCMNotification({
    required String token,
    required String senderName,
    String? messageText,
    String? messageImage,
  }) async {
    const postUrl = 'https://fcm.googleapis.com/fcm/send';
    Dio dio = Dio();

    var token = await getDeviceToken();
    if (kDebugMode) {
      print('device token : $token');
    }

    final data = {
      "data": {
        "message": senderName,
        "title": messageText,
      },
      "to": token
    };

    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers["Authorization"] =
        'key= AAAAqnVMlS0:APA91bHd_ooZwkN81g8c0xaDHC0KPN1QrRhVcq_qG4MZ1pvciG6MF4MhiMDY1HnrscPQeONN_mgEOQl1eU80jZ2NgvYGJKTon8CJ2nLIxwGgkwNBtYhFEDhPYo3sYpXpeYzITVfDo9nT';

    try {
      final response = await dio.post(postUrl, data: data);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Request Sent To Driver');
        }
      } else {
        if (kDebugMode) {
          print('notification sending failed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('exception $e');
      }
    }
  }

  Future<String?> getDeviceToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  ///END : sendFCMNotification

  //------------------------------------------------------------//
  ///START : sendInAppNotification
  void sendInAppNotification({
    String? contentKey,
    String? contentId,
    String? content,
    String? receiverName,
    String? receiverId,
  }) {
    emit(SendInAppNotificationLoadingState());
    NotificationModel notificationModel = NotificationModel(
      contentKey: contentKey,
      contentId: contentId,
      content: content,
      senderName: userModel!.name,
      receiverName: receiverName,
      senderId: userModel!.uId,
      receiverId: receiverId,
      senderImage: userModel!.image,
      read: false,
      dateTime: Timestamp.now(),
      serverTimeStamp: FieldValue.serverTimestamp(),
    );

    FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('notifications')
        .add(notificationModel.toMap())
        .then((value) async {
      await setNotificationId();
      emit(SendInAppNotificationLoadingState());
    }).catchError((error) {
      emit(SendInAppNotificationLoadingState());
    });
  }

  ///END : sendInAppNotification

  //------------------------------------------------------------//
  ///START : getInAppNotification
  List<NotificationModel> notifications = [];

  void getInAppNotification() async {
    emit(GetInAppNotificationLoadingState());
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('notifications')
        .orderBy('serverTimeStamp', descending: true)
        .snapshots()
        .listen((event) async {
      notifications = [];
      for (var element in event.docs) {
        notifications.add(NotificationModel.fromJson(element.data()));
      }
      emit(GetInAppNotificationSuccessState());
    });
  }

  ///END : getInAppNotification

  //------------------------------------------------------------//
  ///START : getUnReadNotificationsCount
  int unReadNotificationsCount = 0;

  Future<int> getUnReadNotificationsCount() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('notifications')
        .snapshots()
        .listen((event) {
      unReadNotificationsCount = 0;
      for (int i = 0; i < event.docs.length; i++) {
        if (event.docs[i]['read'] == false) {
          unReadNotificationsCount++;
        }
      }
      emit(ReadNotificationSuccessState());
      debugPrint("UnRead: " '$unReadNotificationsCount');
    });

    return unReadNotificationsCount;
  }

  ///END : getUnReadNotificationsCount

  //------------------------------------------------------------//
  ///START : getUnReadNotificationsCount
  Future setNotificationId() async {
    await FirebaseFirestore.instance.collection('users').get().then((value) {
      value.docs.forEach((element) async {
        var notifications =
            await element.reference.collection('notifications').get();
        notifications.docs.forEach((notificationsElement) async {
          await notificationsElement.reference
              .update({'notificationId': notificationsElement.id});
        });
      });
      emit(SetNotificationIdSuccessState());
    });
  }

  ///END : getUnReadNotificationsCount

  //------------------------------------------------------------//
  ///START : readNotification
  Future readNotification(String? notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true}).then((value) {
      emit(ReadNotificationSuccessState());
    });
  }

  ///END : readNotification

  //------------------------------------------------------------//
  ///START : deleteNotification
  void deleteNotification(String? notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .collection('notifications')
        .doc(notificationId)
        .delete()
        .then((value) {
      emit(ReadNotificationSuccessState());
    });
  }

  ///END : deleteNotification

  //------------------------------------------------------------//
  ///START : notificationContent
  String notificationContent(String? contentKey) {
    if (contentKey == 'likePost') {
      return 'like Post';
    } else if (contentKey == 'commentPost') {
      return 'comment Post';
    } else if (contentKey == 'friendRequestAccepted') {
      return 'friend Request Accepted';
    } else {
      return ' friend Request';
    }
  }

  IconData notificationContentIcon(String? contentKey) {
    if (contentKey == 'likePost') {
      return IconlyBroken.heart;
    } else if (contentKey == 'commentPost') {
      return IconlyBroken.chat;
    } else if (contentKey == 'friendRequestAccepted') {
      return Icons.person;
    } else {
      return Icons.person;
    }
  }

  ///END : notificationContent
}
