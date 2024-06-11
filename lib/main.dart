import 'dart:async'; // 비동기 프로그래밍을 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 라이브러리
import 'package:webview_flutter/webview_flutter.dart'; // WebView 패키지
import 'package:dio/dio.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '_core/http.dart'; // 네이버 OAuth 인증을 처리하기 위한 커스텀 HTTP 모듈

void main() => runApp(const MaterialApp(home: WebViewExample()));

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late WebViewController _controller; // WebViewController를 정의
  bool _isLoggedIn = false; // 로그인 상태 관리
  String? blogAccessToken; // 접근 토큰 저장 변수

  // 네이버 OAuth 파라미터 설정
  final String clientId = 'hagbQ0neJqK_tY4moEfX'; // 네이버 클라이언트 ID
  final String clientSecret = '9UeKuj_kcO'; // 네이버 클라이언트 시크릿
  final String redirectUri =
      'http://localhost:8080/oauth/naver/callback'; // 리다이렉트 URI
  final String state = 'test'; // 상태값
  final String responseType = 'code'; // 응답 타입

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true, // 인라인 미디어 재생 허용
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{}, // 사용자 액션 없이 재생할 미디어 타입 설정
      );
    } else {
      params = const PlatformWebViewControllerCreationParams(); // 기본 매개변수
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
            params); // WebViewController 생성

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // JavaScript 실행 허용
      ..setBackgroundColor(const Color(0x00000000)) // 배경색 설정
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('웹뷰 로딩 중 (진행률 : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('페이지 로딩 시작: $url');
          },
          onPageFinished: (String url) {
            debugPrint('페이지 로딩 완료: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
페이지 리소스 오류:
  코드: ${error.errorCode}
  설명: ${error.description}
  오류 유형: ${error.errorType}
  메인 프레임 오류: ${error.isForMainFrame}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith(redirectUri)) {
              // 리다이렉트 URI 감지
              final Uri redirectUriObj = Uri.parse(request.url);
              final String? code = redirectUriObj.queryParameters['code'];
              if (code != null) {
                debugPrint('인증 코드: $code');
                await sendCodeToServer(code); // 인증 코드를 서버로 전송
                setState(() {
                  _isLoggedIn = true; // 로그인 상태로 설정
                });
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _controller = controller; // 생성한 컨트롤러를 할당
  }

  // 동적으로 URL 생성하는 메서드
  String buildAuthUrl() {
    return Uri(
      scheme: 'https',
      host: 'nid.naver.com',
      path: '/oauth2.0/authorize',
      queryParameters: {
        'response_type': responseType,
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'state': state,
      },
    ).toString();
  }

  Future<void> sendCodeToServer(String code) async {
    final response = await dio.get(
      '/oauth/naver/code/callback',queryParameters: {"code": code},
    );

    debugPrint('서버 응답: ${response.data}');
    setState(() {
      final blogAccessToken = response.headers["Authorization"]!.first;
      print("blogAccessToken : ${blogAccessToken}");
      debugPrint("👍👍👍👍👍👍👍👍: $blogAccessToken");
      secureStorage.write(key: "blogAccessToken", value: blogAccessToken);
    });
  }

  // 네이버 API를 통해 접근 토큰 삭제 요청을 보내는 메서드
  Future<void> deleteBlogAccessToken() async {
    if (blogAccessToken == null) {
      return;
    }

    final dio = Dio();
    final response = await dio.post(
      'https://nid.naver.com/oauth2.0/token',
      data: {
        'grant_type': 'delete',
        'client_id': clientId,
        'client_secret': clientSecret,
        'access_token': Uri.encodeComponent(blogAccessToken!),
        'service_provider': 'NAVER',
      },
    );

    debugPrint('토큰 삭제 응답: ${response.data}');
  }

  // 로그아웃 메서드
  Future<void> _logout() async {
    await deleteBlogAccessToken(); // 접근 토큰 삭제 요청

    // 쿠키 및 세션 데이터 삭제
    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();

    // WebView 초기화
    _controller.clearCache();
    _controller.loadRequest(Uri.parse(buildAuthUrl())); // 로그아웃 시 기본 로그인 페이지 로드

    setState(() {
      _isLoggedIn = false; // 로그아웃 상태로 설정
      blogAccessToken = null; // 접근 토큰 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 버튼 영역
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _controller
                        .loadRequest(Uri.parse(buildAuthUrl())); // 로그인 URL 로드
                    setState(() {
                      _isLoggedIn = true; // 로그인 버튼 클릭 시 로그인 상태 초기화
                    });
                  },
                  child: const Text('로그인'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoggedIn ? _logout : null, // 로그인된 상태에서만 로그아웃 가능
                  child: const Text('로그아웃'),
                ),
              ],
            ),
          ),
          // WebView 영역
          Expanded(
            child: _isLoggedIn
                ? WebViewWidget(controller: _controller)
                : const Center(child: Text('로그인해주세요')),
          ),
        ],
      ),
    );
  }
}
