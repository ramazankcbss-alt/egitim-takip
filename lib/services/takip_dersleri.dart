import 'package:flutter/material.dart';

import '../lgs.dart';
import '../models.dart';
import '../osym.dart';
import '../screens/ogrenci_profil.dart' show dersOnerisi, hedefOnerisi;
import 'oneri_motoru.dart' show osymKonuDersi;

/// Soru takibinde kullanılan dersler ve konular, öğrencinin hedef sınavına göre.
///
/// * LGS: LGS dersleri ve kazanımları (önceki davranış).
/// * YKS / KPSS / AGS: öğrencinin profilindeki dersler; konular ÖSYM sınav
///   tanımlarından (osym.dart) ders ders çıkarılır. Önerilerim de aynı ders
///   adlarını kullandığı için soru takibi verisi önerilere doğrudan yansır.
/// * Okul: profildeki okul dersleri; LGS'de karşılığı olan derslerin konuları.
class TakipDersleri {
  TakipDersleri._(this.profil, this.dersler, this.konular);

  final String profil;
  final List<LgsDers> dersler;
  final Map<String, List<String>> konular;

  static final Map<String, TakipDersleri> _onbellek = {};

  factory TakipDersleri.ogrenci(Student s) {
    final profil = s.hedefSinav.isNotEmpty ? s.hedefSinav : hedefOnerisi(s.grade);
    final anahtar = '$profil|${s.alan}|${s.grade}|${s.dersler.join(',')}';
    return _onbellek[anahtar] ??= _olustur(profil, s);
  }

  static TakipDersleri _olustur(String profil, Student s) {
    if (profil == 'LGS') return TakipDersleri._(profil, lgsDersler, lgsKonular);
    final adlar = s.dersler.isNotEmpty ? s.dersler : dersOnerisi(s.grade, profil, s.alan);
    if (adlar.isEmpty) return TakipDersleri._(profil, lgsDersler, lgsKonular);

    final konular = <String, List<String>>{for (final a in adlar) a: <String>[]};
    final renk = <String, Color>{};
    if (const ['YKS', 'KPSS', 'AGS'].contains(profil)) {
      for (final sinav in osymSinavlari.where((x) => x.grup == profil)) {
        for (final t in sinav.testler) {
          for (final k in t.konular) {
            final d = osymKonuDersi(t, k, adlar);
            if (d == null) continue;
            final i = k.indexOf(': ');
            final ad = i > 0 ? k.substring(i + 2) : k;
            final l = konular[d]!;
            if (!l.contains(ad)) l.add(ad);
            renk[d] ??= t.renk;
          }
        }
      }
    } else {
      for (final a in adlar) {
        final l = lgsKonular[a];
        if (l != null) konular[a] = [...l];
      }
    }

    var i = 0;
    final dersler = [
      for (final a in adlar) _ders(a, renk[a] ?? lgsDers(a)?.renk ?? _palet[i++ % _palet.length]),
    ];
    return TakipDersleri._(profil, dersler, konular);
  }

  /// Adı verilen ders; listede yoksa LGS derslerine, o da yoksa yeni bir tanıma bakılır.
  LgsDers ders(String ad) {
    for (final d in dersler) {
      if (d.ad == ad) return d;
    }
    return lgsDers(ad) ?? _ders(ad, _palet[ad.hashCode.abs() % _palet.length]);
  }

  /// Dersler + eski kayıtlarda geçen ama listede olmayan dersler (veri kaybolmasın).
  List<LgsDers> ileEk(Iterable<String> ekler) {
    final adlar = {for (final d in dersler) d.ad};
    return [
      ...dersler,
      for (final e in ekler)
        if (e.isNotEmpty && !adlar.contains(e)) ders(e),
    ];
  }

  static LgsDers _ders(String ad, Color renk) {
    final l = lgsDers(ad);
    if (l != null) return l;
    return LgsDers(ad: ad, kisa: _kisa(ad), soru: 20, katsayi: 1, ikon: _ikon(ad), renk: renk);
  }

  static String _kisa(String ad) {
    final ilk = ad.split(RegExp(r'[\s(]')).first;
    return ilk.length <= 9 ? ilk : ilk.substring(0, 8);
  }

  static IconData _ikon(String ad) {
    final a = ad.toLowerCase();
    if (a.contains('matematik') || a.contains('sayısal') || a.contains('geometri')) {
      return Icons.calculate_outlined;
    }
    if (a.contains('türkçe') || a.contains('edebiyat') || a.contains('sözel')) {
      return Icons.menu_book_outlined;
    }
    if (a.contains('fizik') || a.contains('kimya') || a.contains('biyoloji') || a.contains('fen')) {
      return Icons.science_outlined;
    }
    if (a.contains('tarih')) return Icons.account_balance_outlined;
    if (a.contains('coğrafya')) return Icons.public;
    if (a.contains('vatandaş') || a.contains('mevzuat')) return Icons.gavel_outlined;
    if (a.contains('eğitim')) return Icons.school_outlined;
    if (a.contains('ingilizce') || a.contains('dil')) return Icons.translate;
    if (a.contains('felsefe')) return Icons.psychology_outlined;
    if (a.contains('din')) return Icons.mosque_outlined;
    if (a.contains('alan')) return Icons.workspace_premium_outlined;
    return Icons.book_outlined;
  }

  static const _palet = [
    Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFF8E24AA),
    Color(0xFFF9A825), Color(0xFF6D4C41), Color(0xFF00897B), Color(0xFF3949AB),
    Color(0xFFD81B60), Color(0xFF546E7A),
  ];
}
