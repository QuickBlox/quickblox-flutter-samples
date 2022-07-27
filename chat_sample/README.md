# Table of Content

- [About](#about)
- [Screenshots](#screenshots)
- [Features](#features)
- [How to launch](#how-to-launch)
  * [1. Get application credentials](#1-get-application-credentials)
  * [2. Download samples from GitHub](#2-download-samples-from-github)
  * [3. Open sample](#3-open-sample)
  * [4. Set application credentials](#4-set-application-credentials)
- [License](#license)

# About

The Flutter Sample Chat project is a sample text chat base on QuickBlox Flutter SDK.

The QuickBlox Flutter SDK provides a Flutter library making it even easier to access the QuickBlox cloud communication backend platform.

[QuickBlox](https://quickblox.com) is a suite of communication features & data services (APIs, SDKs, code samples, admin panel, tutorials) which help digital agencies, mobile developers and publishers to add great communication functionality to smartphone applications like in Skype, WhatsApp, Viber.

# Screenshots

1. Enter to chat;

   <img src="assets\screenshots\login.jpg" width=190 />

2. Chat dashboard with list of dialogs;

   <img src="assets\screenshots\dialogs.png" width=190 />

3. Active Group public/private Chat;

    <img src="assets\screenshots\chat.png" width=190 />

4. Create new chat;

    <img src="assets\screenshots\create_new_chat.png" width=190 />

# Features

- Log in
- Create chat
- Remove/Leave chat
- See Public chat
- Send messages
- Message's statuses
- Receive messages 
- Add users to chat
- Log out

# How to launch
[Article - How to Launch a Flutter Chat Sample](https://quickblox.com/blog/how-to-launch-a-flutter-chat-sample/)

## 1. Get application credentials.
[Article - How to Create an App and Use the QuickBlox Admin Panel](https://quickblox.com/blog/how-to-create-an-app-and-use-quickblox-admin-panel/)

QuickBlox application includes everything that brings messaging right into your application - chat, video calling, users, push notifications, etc. To create a QuickBlox application, follow the steps below:  
  1. Register a new account following [this link](https://admin.quickblox.com/signup). Type in your email and password to sign in. You can also sign in with your Google or Github accounts.  
  2. Create the app clicking **New app** button.  
  3. Configure the app. Type in the information about your organization into corresponding fields and click **Add** button.  
  4. Go to **Dashboard => _YOUR_APP_ => Overview** section and copy your **Application ID**, **Authorization Key**, **Authorization Secret**, and **Account Key**.


## 2. Download samples from GitHub. 

[GitHub - QuickBlox Flutter Samples](https://github.com/QuickBlox/quickblox-flutter-samples). To download samples, click on the button **“Code”** and select the format you need.
 
The simple ways to download samples from GitHub are:
 
 – HTTPS  
 – Download ZIP

## 3. Open sample. 
Open the sample in [Android Studio](https://developer.android.com/studio), or [VS Code](https://code.visualstudio.com/download). If you don’t have it installed – install one of them first. Pay attention – if you want to deploy the sample onto an iOS device you should install the latest [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) version.
We recommend opening the sample using:

– minimal supported version of Android Studio 4.2.2  
– minimal supported version of  VS Code 1.61 

For example, in **Android Studio**:

- open android studio  
- click on **“Open an Existing Project”**  
- select the sample you downloaded  
- click on the **"open"** button


## 4. Set application credentials 
- [Get application credentials](#1-get-application-credentials) and get **Application ID**, **Authorization Key**, **Authorization Secret**, and **Account Key**.  
- Open **main.dart file** and paste the credentials into the values of constants.

# License

**BSD 3-Clause**