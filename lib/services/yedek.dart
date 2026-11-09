import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import 'db.dart';

/// Kullanıcının görebildiği tüm öğrencilerin verisini tek bir JSON dosyasına
/// yazar ve paylaşım ekranını açar ("Drive'a kaydet" seçilerek Drive'a konur).
class Yedek {
  static final _fs = FirebaseFirestore.instance;

  static Object? _deger(Object? v) {
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is GeoPoint) return {'lat': v.latitude, 'lng': v.longitude};
    if (v is DocumentReference) return v.path;
    if (v is List) return v.map(_deger).toList();
    if (v is Map) return v.map((k, e) => MapEntry(k.toString(), _deger(e)));
    return v;
  }

  static Map<String, Object?> _belge(DocumentSnapshot<Map<String, dynamic>> d) =>
      {'id': d.id, ...(_deger(d.data() ?? {}) as Map<String, Object?>)};

  static Future<Map<String, Object?>> veriTopla(AppUser me) async {
    final ogrenciler = await Db.myStudents(me).first;
    final liste = <Map<String, Object?>>[];
    for (final s in ogrenciler) {
      final ref = _fs.collection('students').doc(s.id);
      final kayit = _belge(await ref.get());
      for (final ad in Db.subCollections) {
        final q = await ref.collection(ad).get();
        kayit[ad] = q.docs.map(_belge).toList();
      }
      liste.add(kayit);
    }
    return {
      'uygulama': 'Eğitim Takip',
      'surum': 1,
      'tarih': DateTime.now().toIso8601String(),
      'kullanici': {'uid': me.uid, 'ad': me.name},
      'ogrenciler': liste,
    };
  }

  static Future<void> yedekleVePaylas(AppUser me) async {
    final veri = await veriTopla(me);
    final metin = const JsonEncoder.withIndent('  ').convert(veri);
    final t = DateTime.now();
    String iki(int n) => n.toString().padLeft(2, '0');
    final ad = 'egitim-takip-yedek-${t.year}-${iki(t.month)}-${iki(t.day)}'
        '-${iki(t.hour)}${iki(t.minute)}.json';
    final klasor = await getTemporaryDirectory();
    final dosya = File('${klasor.path}/$ad');
    await dosya.writeAsString(metin);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(dosya.path, mimeType: 'application/json')],
      subject: 'Eğitim Takip yedeği',
      text: 'Eğitim Takip yedeği (${ogrenciSayisi(veri)} öğrenci)',
    ));
  }

  static int ogrenciSayisi(Map<String, Object?> veri) =>
      (veri['ogrenciler'] as List).length;
}
