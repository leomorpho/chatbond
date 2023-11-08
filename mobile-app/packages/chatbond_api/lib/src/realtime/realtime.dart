import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond_api/src/auth/serializer/token_refresh.dart';
import 'package:chatbond_api/src/realtime/realtime_interface.dart';
import 'package:loggy/loggy.dart';

typedef VoidCallback = void Function();

class Realtime implements RealtimeInterface {
  Realtime({
    required this.realtimeUrl,
    required this.accessTokenGetter,
    required this.refreshTokenGetter,
    required this.refreshTokenFunction,
  });

  final String realtimeUrl;
  final TokenGetter accessTokenGetter;
  final TokenGetter refreshTokenGetter;
  final Future<TokenRefresh> Function({required String refreshToken})
      refreshTokenFunction;

  late centrifuge.Client _client;
  StreamSubscription<centrifuge.ConnectedEvent>? _connectedSub;
  StreamSubscription<centrifuge.ConnectingEvent>? _connectingSub;
  StreamSubscription<centrifuge.DisconnectedEvent>? _disconnSub;
  StreamSubscription<centrifuge.ErrorEvent>? _errorSub;

  late StreamSubscription<centrifuge.MessageEvent> _msgSub;
  late centrifuge.Subscription? subscription;

  final StreamController<String> _controller = StreamController.broadcast();

  Stream<String> get channelStream => _controller.stream;

  void init() {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = 'ws://$realtimeUrl/connection/websocket?format=protobuf';
    logInfo('Connecting to Centrifugo client at $url');
    _client = centrifuge.createClient(
      url,
      centrifuge.ClientConfig(
        // name: conf.userName,
        token: token,
        getToken: (context) async {
          final refreshToken = refreshTokenGetter();
          if (refreshToken == null) {
            throw 'No refresh token set';
          }
          try {
            // This function should implement the refresh logic for your tokens
            final token =
                await refreshTokenFunction(refreshToken: refreshToken);
            return token.access;
          } catch (e) {
            logError('Token refresh failed: $e');
            rethrow;
          }
        },
      ),
    );
    _msgSub = _client.message.listen((event) {
      logInfo('Msg: $event');
    });
  }

  Future<void> connect(VoidCallback onConnect) async {
    logInfo('Connecting to Centrifugo server at $realtimeUrl');
    _connectedSub = _client.connected.listen((event) {
      logInfo('Connected to server');
      onConnect();
    });
    _connectingSub = _client.connecting.listen((event) {
      logInfo('Connecting to server');
    });
    _disconnSub = _client.disconnected.listen((event) {
      logInfo('Disconnected from server');
    });
    _errorSub = _client.error.listen((event) {
      logInfo(event.error);
    });
    await _client.connect();
  }

  Future<void> subscribe(
    String channel,
    StreamSink<String> streamSink,
  ) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    logInfo('Subscribing to channel $channel with TOKEN $token');
    final subscription = _client.getSubscription(channel) ??
        _client.newSubscription(
          channel,
          centrifuge.SubscriptionConfig(
            token: token,
          ),
        );
    subscription.publication
        .map<String>((e) => utf8.decode(e.data))
        .listen((data) {
      logDebug('From channel $channel, received message $data');
      streamSink.add(data);
    });
    subscription.join.listen(logInfo);
    subscription.leave.listen(logInfo);
    subscription.subscribed.listen(logInfo);
    subscription.subscribing.listen(logInfo);
    subscription.error.listen(logInfo);
    subscription.unsubscribed.listen(logInfo);
    this.subscription = subscription;
    await subscription.subscribe();
  }

  Future<void> dispose() async {
    await _connectingSub?.cancel();
    await _connectedSub?.cancel();
    await _disconnSub?.cancel();
    await _errorSub?.cancel();
    await _msgSub.cancel();
  }

  // TODO: https://github.dev/robert-virkus/centrifuge-dart/tree/594acdc6201ddde8f5ca8eb0482f95857fefe114/example/chat_app/lib
  // Future<void> sendMsg(ChatMessage msg) async {
  //   final output = jsonEncode({'message': msg.text});
  //   logInfo("Sending msg : $output");
  //   final data = utf8.encode(output);
  //   try {
  //     await subscription?.publish(data);
  //   } on Exception {
  //     rethrow;
  //   }
  // }
}
