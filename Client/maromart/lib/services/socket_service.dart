import 'package:maromart/utils/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:maromart/utils/storage.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onMessageSent;

  Function(Map<String, dynamic>)? onNewNotification;

  bool get isConnected => _isConnected;

  // Kết nối socket
  void connect() {
    if (_socket != null && _isConnected) {
      print('[Socket] Đã kết nối rồi');
      return;
    }

    final token = StorageHelper.getToken();
    if (token == null || token.isEmpty) {
      print('[Socket] Không có token, không thể kết nối');
      return;
    }

    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.connect();


    _socket!.onConnect((_) {
      print('[Socket] Connected: ${_socket!.id}');
      _isConnected = true;

      _socket!.emit('register', token);
    });

    _socket!.on('register_success', (data) {
      print('[Socket] Register success: $data');
    });

    _socket!.on('register_fail', (data) {
      print('[Socket] Register fail: $data');
      disconnect();
    });

    _socket!.on('get_new_message', (data) {
      print('[Socket] Nhận tin nhắn mới: $data');
      if (onNewMessage != null) {
        onNewMessage!(data);
      }
    });

    _socket!.on('put_new_message', (data) {
      print('[Socket] Tin nhắn đã gửi: $data');
      if (onMessageSent != null) {
        onMessageSent!(data);
      }
    });

    _socket!.on('force_disconnect', (data) {
      print('[Socket]  Bị đăng xuất: $data');
      disconnect();
    });

    _socket!.on('new_notification', (data) {
      print('[Socket] Nhận thông báo mới: $data');

      if (onNewNotification != null) {
        onNewNotification!(data);
      }
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Disconnected');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('[Socket] Error: $error');
    });
  }

  // Ngắt kết nối
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('[Socket] Đã ngắt kết nối');
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      print('[Socket] Chưa kết nối, không thể emit');
    }
  }
}