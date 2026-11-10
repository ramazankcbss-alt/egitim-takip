import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import 'common.dart';

/// Sağ üstte hesap menüsü: hesap türünü değiştir, çıkış yap.
class HesapMenusu extends StatelessWidget {
  const HesapMenusu({super.key, required this.me});
  final AppUser me;

  Future<void> _turDegistir(BuildContext context) async {
    final yeni = await showDialog<UserRole>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Hesap türünü değiştir'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Şu an: ${me.role.label}. Bağlı olduğunuz öğrenciler ve kayıtlar silinmez.',
                style: const TextStyle(fontSize: 13)),
          ),
          for (final (r, aciklama) in [
            (UserRole.student, 'Kendimi takip edeceğim ya da davet koduyla bağlanacağım'),
            (UserRole.parent, 'Çocuklarımı ekleyip takip edeceğim'),
            (UserRole.teacher, 'Öğrencilerimi davet koduyla ekleyeceğim'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(roleIcon(r)),
                title: Text(r.label,
                    style: TextStyle(
                        fontWeight: r == me.role ? FontWeight.w800 : FontWeight.w500)),
                subtitle: Text(aciklama),
                trailing: r == me.role ? const Icon(Icons.check) : null,
              ),
            ),
        ],
      ),
    );
    if (yeni == null || yeni == me.role || !context.mounted) return;
    await runSafe(context, () => Db.updateRole(me.uid, yeni),
        success: 'Hesap türü "${yeni.label}" olarak değiştirildi.');
  }

  Future<void> _epostaDegistir(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final eski = user?.email ?? '';
    if (user == null || eski.isEmpty) return;
    final yeniC = TextEditingController();
    final sifreC = TextEditingController();
    final tamam = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giriş e-postasını değiştir'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Şu anki adres: $eski\nÖğrenciler ve tüm kayıtlar hesabınızda kalır; '
                'yalnızca giriş adresi değişir.',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: yeniC,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Yeni e-posta adresi'),
            ),
            TextField(
              controller: sifreC,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şu anki şifreniz'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devam')),
        ],
      ),
    );
    final yeni = yeniC.text.trim().toLowerCase();
    final sifre = sifreC.text;
    if (tamam != true || !context.mounted) return;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(yeni) || sifre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir e-posta ve şifre girin.')));
      return;
    }
    if (yeni == eski.toLowerCase()) return;
    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: eski, password: sifre));
      await user.verifyBeforeUpdateEmail(yeni);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Onay e-postası gönderildi'),
          content: Text('$yeni adresine bir onay bağlantısı gönderildi (gelmezse Spam / '
              'Gereksiz klasörüne bakın). Bağlantıya dokunduğunuzda giriş adresiniz değişir; '
              'sonra uygulamaya yeni adres ve aynı şifreyle girin.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      final m = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Şifre yanlış.',
        'email-already-in-use' =>
          'Bu e-posta ile açılmış başka bir hesap var. O hesabı silmeden bu adrese geçilemez.',
        'invalid-email' => 'E-posta adresi geçersiz.',
        'too-many-requests' => 'Çok fazla deneme yapıldı; biraz sonra tekrar deneyin.',
        'network-request-failed' => 'İnternet bağlantısı yok.',
        _ => 'E-posta değiştirilemedi (${e.code}).',
      };
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Hesabım',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (v) async {
        if (v == 'tur') await _turDegistir(context);
        if (v == 'eposta' && context.mounted) await _epostaDegistir(context);
        if (v == 'cikis' && context.mounted) await cikisYap(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${me.name} • ${me.role.label}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        const PopupMenuItem(
          value: 'tur',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.swap_horiz),
            title: Text('Hesap türünü değiştir'),
          ),
        ),
        const PopupMenuItem(
          value: 'eposta',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.alternate_email),
            title: Text('Giriş e-postasını değiştir'),
          ),
        ),
        const PopupMenuItem(
          value: 'cikis',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Çıkış yap'),
          ),
        ),
      ],
    );
  }
}
