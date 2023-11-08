import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

@RoutePage()
class UserTermsPage extends StatelessWidget {
  const UserTermsPage({super.key, this.cameFromSignup = false});

  final bool cameFromSignup;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('Terms of Service'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (cameFromSignup) {
                  context.router.pop();
                } else {
                  AutoRouter.of(context).replaceAll(
                    [
                      const AnonymousRouterRoute(),
                      SignUpRoute(),
                    ],
                  );
                }
              },
            ),
          ),
          body: MaxWidthView(
              child: const Markdown(
            data: '''
# Chatbond: Terms of Service

---

## Introduction

Welcome to Chatbond, a unique platform designed to facilitate meaningful conversations between users. Please read these Terms of Service ("Terms") and our Privacy Policy carefully. By using or accessing Chatbond ("the App"), you agree to comply with these Terms and our Privacy Policy.

---

## Acceptance of Terms

By accessing or using the App, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use the App.

---

## Modifications

We reserve the right to modify these Terms at any time. Your continued use of the App after any such changes constitutes your acceptance of the new Terms.

---

## Account Registration

To participate in conversations within the App, you'll need to create an account. You must provide accurate and complete information and keep your account information updated.

---

## Privacy Policy

By using the App, you consent to the collection, use, and disclosure of your information as outlined in our Privacy Policy, which is a part of these Terms.

---

## User Content

You are solely responsible for all content that you upload, publish, or display on the App.

---

## User Conduct

You agree not to engage in any unlawful conduct or harassment while using the App.

---

## Data Handling

- Your information will not be sold to third parties.
- All information shared within a conversation thread will remain private among the participants unless otherwise explicitly shared by the user.

---

## Limitation of Liability

To the maximum extent permitted by applicable law, Chatbond shall not be liable for any indirect, incidental, or consequential damages.

---

## Governing Law

These Terms shall be governed by and interpreted in accordance with the laws of the jurisdiction in which the company resides.

---

# Chatbond: Privacy Policy

---

## Introduction

This Privacy Policy explains how we collect, use, and disclose information from and/or about you when you use the Chatbond App.

---

## Information We Collect

- Account Information
- Content you create within the App
- Usage Data

---

## How We Use Your Information

We use your information to provide, analyze, and improve the App. We also use it to facilitate conversations and suggest questions based on our intelligent algorithm.

---

## Information Sharing

We do not sell your information. All data remains private among conversation participants unless explicitly shared by a user.

---

## Security

We use appropriate physical, electronic, and procedural safeguards to protect your information.

---

## Contact Us

If you have questions about this Privacy Policy, please contact us at [support@chatbond.app](mailto:support@chatbond.app)

''',
            // styleSheet:
            //     MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            //   h1: Theme.of(context).textTheme.headline1.copyWith(
            //         color: Colors.blue, // Your desired color
            //       ),
            //   p: Theme.of(context).textTheme.bodyText1.copyWith(
            //         color: Colors.red, // Your desired color
            //       ),
            // ),
          )),
        );
      },
    );
  }
}
