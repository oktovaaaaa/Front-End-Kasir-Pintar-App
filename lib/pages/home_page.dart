import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onUserActivity;
  final Future<void> Function() onForceLogout;

  const HomePage({
    super.key,
    required this.onUserActivity,
    required this.onForceLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onUserActivity,
      onPanDown: (_) => widget.onUserActivity(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Kasir'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.logout();
                await widget.onForceLogout();
              },
            ),
          ],
        ),
        body: const Center(
          child: Text('Ini halaman kasir. Nanti isi menu transaksi dsb.'),
        ),
      ),
    );
  }
}
