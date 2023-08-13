import 'package:sociality/Pages/Register/register_screen.dart';
import 'package:sociality/Pages/password/forget_password.dart';
import 'package:sociality/adaptive/indicator.dart';
import 'package:sociality/layout/Home/home_layout.dart';
import 'package:sociality/pages/email_verification/email_verification_screen.dart';
import 'package:sociality/shared/components/navigator.dart';
import 'package:sociality/shared/components/text_form_field.dart';
import 'package:sociality/shared/cubit/loginCubit/state.dart';
import 'package:sociality/shared/components/components.dart';
import 'package:sociality/shared/components/constants.dart';
import 'package:sociality/shared/cubit/loginCubit/cubit.dart';
import 'package:sociality/shared/cubit/socialCubit/social_cubit.dart';
import 'package:sociality/shared/network/cache_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    return BlocProvider(
      create: (BuildContext context) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginStates>(
        listener: (context, state) {
          if (state is LoginSuccessState) {
            SocialCubit.get(context).getUserData();
            CacheHelper.saveData(value: state.uid, key: 'uId').then((value) {
              uId = state.uid;
              SocialCubit.get(context).getUserData();
              SocialCubit.get(context).getPosts();
              SocialCubit.get(context).getAllUsers();
              showToast(
                text: 'Login is successfully',
                state: ToastStates.success,
              );
            });
          } else if (state is LoginErrorState) {
            showToast(
              text: state.error,
              state: ToastStates.error,
            );
          }
        },
        builder: (context, state) {
          var cubit = SocialCubit.get(context);
          return Scaffold(
            appBar: AppBar(),
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    space(0, 50.h),
                    Align(
                      child: Text(
                        'Sign in Now',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: cubit.isLight ? Colors.black : Colors.white,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    space(0, 10.h),
                    Text(
                      'Please enter your information',
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    space(0, 20.h),
                    Text(
                      'E-mail Address',
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    space(0, 10.h),
                    DefaultTextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validate: (String? value) {
                        if (value!.trim().isEmpty) {
                          return 'Please enter your E-mail';
                        }
                        return null;
                      },
                      label: 'E-mail',
                      prefix: Icons.alternate_email,
                    ),
                    space(0, 20.h),
                    Text(
                      'Password',
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    space(0, 10.h),
                    DefaultTextFormField(

                      controller: passController,
                      keyboardType: TextInputType.visiblePassword,
                      validate: (String? value) {
                        if (value!.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      prefix: Icons.lock_outline_rounded,
                      suffix: LoginCubit.get(context).suffix,
                      isPassword: LoginCubit.get(context).isPassword,
                      suffixPressed: () {
                        LoginCubit.get(context).showPassword();
                      }, label: 'Password',
                    ),
                    space(0, 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () {
                            navigateTo(
                              context,
                              RestPasswordScreen(),
                            );
                          },
                          child: Text(
                            'Forget Password ?',
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    space(0, 30.h),
                    state is! LoginLoadingState
                        ? Center(
                            child: defaultMaterialButton(
                              function: () {
                                if (formKey.currentState!.validate()) {
                                  LoginCubit.get(context)
                                      .userLogin(
                                        email: emailController.text,
                                        password: passController.text,
                                      )
                                      .then(
                                        (value) => {
                                          LoginCubit.get(context)
                                              .loginReloadUser()
                                              .then(
                                            (value) {
                                              if (LoginCubit.get(context)
                                                  .isEmailVerified) {
                                                navigateAndFinish(
                                                  context,
                                                  const HomeLayout(),
                                                );
                                              } else {
                                                navigateTo(
                                                  context,
                                                  const EmailVerificationScreen(),
                                                );
                                              }
                                            },
                                          )
                                        },
                                      );
                                }
                              },
                              text: 'Login',
                            ),
                          )
                        : Center(
                            child: AdaptiveIndicator(
                              os: getOs(),
                            ),
                          ),
                    space(0, 15.h),
                    Row(
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              color:
                                  cubit.isLight ? Colors.black : Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            navigateTo(
                              context,
                              const RegisterScreen(),
                            );
                          },
                          child: Text(
                            'Register Now !'.toUpperCase(),
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                color: Colors.blue,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
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
          );
        },
      ),
    );
  }
}
