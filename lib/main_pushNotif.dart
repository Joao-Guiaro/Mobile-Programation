import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // O handler de background não controla a interface Flutter.
  debugPrint('Push em background: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  runApp(const PushDemoApp());
}

class PushDemoApp extends StatelessWidget {
  const PushDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demonstração de Push',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const PushHomePage(),
    );
  }
}

class PushHomePage extends StatefulWidget {
  const PushHomePage({super.key});

  @override
  State<PushHomePage> createState() => _PushHomePageState();
}

class _PushHomePageState extends State<PushHomePage> {
  String? _token;
  String _status = 'Ative as notificações para obter um token de teste.';
  String _lastMessage = 'Nenhuma mensagem recebida ainda.';
  late final StreamSubscription<RemoteMessage> _foregroundSubscription;
  late final StreamSubscription<RemoteMessage> _openedSubscription;
  late final StreamSubscription<String> _tokenSubscription;

  @override
  void initState() {
    super.initState();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => _showMessage(message, 'Recebida com o app aberto'),
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) =>
          _showMessage(message, 'App aberto pelo toque na notificação'),
    );
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) {
      if (!mounted) return;
      setState(() {
        _token = newToken;
        _status = 'O token foi atualizado.';
      });
    });
    unawaited(_checkLaunchMessage());
  }

  Future<void> _checkLaunchMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      _showMessage(message, 'App iniciado pelo toque na notificação');
    }
  }

  Future<void> _requestPermissionAndToken() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!allowed) {
      if (!mounted) return;
      setState(() {
        _status = 'Permissão não concedida. O sistema pode bloquear os avisos.';
      });
      return;
    }

    final token = await messaging.getToken();
    if (!mounted) return;
    setState(() {
      _token = token;
      _status = token == null
          ? 'Não foi possível obter o token neste dispositivo.'
          : 'Token obtido. Use-o apenas para teste e mantenha-o privado.';
    });
  }

  void _showMessage(RemoteMessage message, String source) {
    if (!mounted) return;
    final title = message.notification?.title ?? 'Mensagem de dados';
    final body = message.notification?.body ?? message.data.toString();
    setState(() {
      _status = source;
      _lastMessage = '$title\n$body\nDados extras: ${message.data}';
    });
  }

  @override
  void dispose() {
    _foregroundSubscription.cancel();
    _openedSubscription.cancel();
    _tokenSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notification em Flutter')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Este app de estudo recebe push pelo FCM. O Flutter cuida da tela; '
            'o serviço de push encaminha a mensagem ao dispositivo.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _requestPermissionAndToken,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Ativar notificações e obter token'),
          ),
          const SizedBox(height: 12),
          Text(_status),
          if (_token != null) ...[
            const SizedBox(height: 8),
            const Text('Token FCM de teste (não publique nem compartilhe):'),
            SelectableText(_token!),
          ],
          const SizedBox(height: 24),
          Text('Último evento', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_lastMessage),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Teste: deixe o app em segundo plano e envie uma notificação ao '
            'token pelo Firebase Console. Depois toque no aviso. Com o app '
            'aberto, observe o evento aparecer neste cartão.',
          ),
        ],
      ),
    );
  }
}
