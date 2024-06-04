class Response{
  dynamic response;

  Response({
    required this.response,
  });

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      response: json["response"],
    );
  }
//
}