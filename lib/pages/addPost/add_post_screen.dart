import 'package:sociality/model/user_model.dart';
import 'package:sociality/shared/components/image_with_shimmer.dart';
import 'package:sociality/shared/components/navigator.dart';
import 'package:sociality/shared/components/show_toast.dart';
import 'package:sociality/shared/cubit/socialCubit/social_cubit.dart';
import 'package:sociality/shared/cubit/socialCubit/social_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sociality/shared/styles/color.dart';

class AddPostScreen extends StatelessWidget {
  const AddPostScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    SocialCubit cubit = SocialCubit.get(context);
    UserModel userModel = SocialCubit.get(context).userModel!;
    return BlocConsumer<SocialCubit, SocialStates>(
      listener: (context, state) {
        if (state is CreatePostSuccessState) {
          cubit.getPosts();
          pop(context);
          showToast(
              text: 'Create Post Successfully', state: ToastStates.success);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                pop(context);
                cubit.removePostImage();
              },
              icon: Icon(
                IconlyLight.arrowLeft2,
                size: 24.sp,
                color: cubit.isDark
                    ? AppMainColors.blackColor
                    : AppMainColors.titanWithColor,
              ),
            ),
            titleSpacing: 1,
            title: Text(
              'Create Post',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  DateTime now = DateTime.now();
                  if (textController.text.trim().isNotEmpty &&
                      cubit.postImagePicked == null) {
                    cubit.createPost(
                      dateTime: now.toString(),
                      text: textController.text,
                    );
                    cubit.removePostImage();
                  } else if (cubit.postImagePicked != null) {
                    cubit.uploadPostImage(
                      dateTime: now.toString(),
                      text: textController.text,
                    );
                    pop(context);
                    cubit.removePostImage();
                  } else {
                    pop(context);
                  }
                },
                child: Text(
                  'Share',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
            elevation: 0,
          ),
          body: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      if (state is CreatePostLoadingState)
                        const LinearProgressIndicator(),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 20,
                          right: 20,
                          left: 20,
                        ).r,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35.r,
                              child: ImageWithShimmer(
                                radius: 75.r,
                                imageUrl: userModel.image,
                                width: 100.w,
                                height: 100.h,
                                boxFit: BoxFit.fill,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userModel.name,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Icon(
                                      IconlyLight.user2,
                                      color: cubit.isDark
                                          ? Colors.black
                                          : Colors.white,
                                      size: 24.sp,
                                    ),
                                    SizedBox(width: 5.w),
                                    Text(
                                      'public',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: AppMainColors.greyColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20).r,
                        child: TextFormField(
                          maxLines: 6,
                          minLines: 1,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(color: AppMainColors.blackColor),
                          controller: textController,
                          decoration: InputDecoration(
                            hintText: "' What's on your mind ? '",
                            hintStyle:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: AppMainColors.greyColor,
                                    ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (SocialCubit.get(context).postImagePicked != null)
                        Stack(
                          alignment: AlignmentDirectional.topEnd,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10).r,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppMainColors.greyColor
                                          .withOpacity(0.4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10).r,
                                  child: Image(
                                    image: FileImage(cubit.postImagePicked!),
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                cubit.removePostImage();
                              },
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppMainColors.greyColor
                                          .withOpacity(0.4),
                                      blurRadius: 9,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: AppMainColors.titanWithColor,
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cubit.isDark
                            ? AppMainColors.titanWithColor
                            : AppColorsLight.primaryColor,
                      ),
                      onPressed: () {
                        cubit.getPostImage();
                      },
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      label: Text(
                        'Add photo'.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      icon: Icon(
                        IconlyLight.image,
                        color: AppMainColors.titanWithColor,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
