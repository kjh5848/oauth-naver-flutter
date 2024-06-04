import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:oauth_naver_flutter/http.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
GlobalKey<ScaffoldMessengerState>();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Naver Login',
      scaffoldMessengerKey: snackbarKey,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF00c73c),
        canvasColor: const Color(0xFFfafafa),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(
              fontSize: 12.0,
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontFamily: "Roboto",
            ),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   /// Show [error] content in a ScaffoldMessenger snackbar
  void _showSnackError(String error) {
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(error.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter Naver Login Sample',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        children: [
          ElevatedButton(
            onPressed: buttonLoginPressed,
            child: const Text("네이버 로그인"),
          ),
          ElevatedButton(
            onPressed: buttonLogoutPressed,
            child: const Text("LogOut"),
          ),
          ElevatedButton(
            onPressed: buttonLogoutAndDeleteTokenPressed,
            child: const Text("LogOutAndDeleteToken"),
          ),
          ElevatedButton(
            onPressed: buttonTokenPressed,
            child: const Text("GetToken"),
          ),
          ElevatedButton(
            onPressed: buttonGetUserPressed,
            child: const Text("GetUser"),
          )
        ],
      ),
    );
  }

  Future<void> buttonLoginPressed() async {
    try {
      final NaverAccessToken res = await FlutterNaverLogin.refreshAccessTokenWithRefreshToken();
      final  naverAccessTokenoken = res.accessToken;
      print("네이버 로그인 : ${naverAccessTokenoken}");

      //2. 토큰을 스프링 서버에 전달하기(스프링 서버한테 나 인증했어!! 라고 알려주는 것)
      final response =  await dio.get("/oauth/naver/callback", queryParameters: {"accessToken" : naverAccessTokenoken});
      print("👍👍👍👍👍👍👍👍👍👍");
      response.toString();

      //3. 토큰(스프링서버)의 토큰 응답받기
      final blogAccessToken = response.headers["Authorization"]!.first;
      print("blogAccessToken : ${blogAccessToken}");

      //4. 시큐어 스토리지에 저장
      secureStorage.write(key: "blogAccessToken", value: blogAccessToken);

      //5. static, const 변수, riverpod 상태관리(생략)

    } catch (error) {
      print('네이버 로그인 실패 $error');
    }
  }

  Future<void> buttonTokenPressed() async {
    try {
      final NaverAccessToken res = await FlutterNaverLogin.currentAccessToken;

    } catch (error) {
      _showSnackError(error.toString());
    }
  }

  Future<void> buttonLogoutPressed() async {
    try {
      await FlutterNaverLogin.logOut();
    } catch (error) {
      print(error);

    }
  }

  Future<void> buttonLogoutAndDeleteTokenPressed() async {
    try {
      await FlutterNaverLogin.logOutAndDeleteToken();

    } catch (error) {
      _showSnackError(error.toString());
    }
  }

  Future<void> buttonGetUserPressed() async {
    try {
      final NaverAccountResult res = await FlutterNaverLogin.currentAccount();

    } catch (error) {
      _showSnackError(error.toString());
    }
  }
}