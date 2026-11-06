import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import '../widgets/common.dart';

/// Yeni hesap açıldıktan sonra ad ve rol seçilir.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  UserRole _role = UserRole.parent;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _roleInfo => switch (_role) {
        UserRole.parent =>
          'Çocuklarınızı ekler, ödevlerini ve çalışmalarını takip edersiniz. '
              'Her çocuk için oluşan davet kodunu öğretmenlerle ve çocuğunuzla paylaşırsınız.',
        UserRole.student =>
          'Velinden aldığın davet koduyla kendi sayfana bağlanırsın. '
              'Ödevini yapınca "Yaptım" butonuna basarsın.',
        UserRole.teacher =>
          'Velilerin paylaştığı davet kodlarıyla öğrencilerinizi eklersiniz. '
              'Ödev verebilir, kontrol edebilir ve ilerlemeyi izleyebilirsiniz.',
      };

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showInfo(context, 'Lütfen adınızı yazın.');
      return;
    }
    setState(() => _busy = true);
    await runSafe(
      context,
      () => Db.createProfile(
        uid: widget.user.uid,
        name: name,
        email: widget.user.email ?? '',
        role: _role,
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Hoş geldiniz! Birkaç bilgiyle başlayalım.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Adınız Soyadınız',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Bu uygulamayı kim olarak kullanacaksınız?'),
          const SizedBox(height: 8),
          SegmentedButton<UserRole>(
            segments: UserRole.values
                .map((r) => ButtonSegment<UserRole>(
                      value: r,
                      label: Text(r.label),
                      icon: Icon(roleIcon(r)),
                    ))
                .toList(),
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_roleInfo),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _busy ? null : _save,
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }
}
