import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:webview_flutter/webview_flutter.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naver Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final String clientId = 'YOUR_CLIENT_ID';
  final String clientSecret = 'YOUR_CLIENT_SECRET';
  final String redirectUri = 'YOUR_REDIRECT_URI';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Naver Login Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final String state = DateTime.now().millisecondsSinceEpoch.toString();
            final String url =
                'https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$state';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebViewLogin(
                  url: url,
                  redirectUri: redirectUri,
                  clientId: clientId,
                  clientSecret: clientSecret,
                ),
              ),
            );
          },
          child: Text('Login with Naver'),
        ),
      ),
    );
  }
}

class WebViewLogin extends StatefulWidget {
  final String url;
  final String redirectUri;
  final String clientId;
  final String clientSecret;

  WebViewLogin({
    required this.url,
    required this.redirectUri,
    required this.clientId,
    required this.clientSecret,
  });

  @override
  _WebViewLoginState createState() => _WebViewLoginState();
}

class _WebViewLoginState extends State<WebViewLogin> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Naver Login'),
      ),
      body: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
        navigationDelegate: (NavigationRequest request) {
          if (request.url.startsWith(widget.redirectUri)) {
            final Uri uri = Uri.parse(request.url);
            final String? code = uri.queryParameters['code'];
            final String? state = uri.queryParameters['state'];

            if (code != null) {
              _getAccessToken(code, state!);
            }
            Navigator.pop(context);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  Future<void> _getAccessToken(String code, String state) async {
    final dio = Dio();

    try {
      final response = await dio.post(
        'https://nid.naver.com/oauth2.0/token',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
        data: {
          'grant_type': 'authorization_code',
          'client_id': widget.clientId,
          'client_secret': widget.clientSecret,
          'code': code,
          'state': state,
        },
      );

      final Map<String, dynamic> responseBody = response.data;
      final String accessToken = responseBody['access_token'];

      // 여기서 accessToken을 사용하여 네이버 API 호출
      // 예: 사용자 프로필 정보 가져오기

      final profileResponse = await dio.get(
        'https://openapi.naver.com/v1/nid/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final Map<String, dynamic> profile = profileResponse.data;
      print(profile);
    } catch (e) {
      print('Error: $e');
    }
  }
}
