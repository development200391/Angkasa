import 'dart:convert';
import 'dart:io';

import 'package:angkasa/core/constants/app_assets.dart';
import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/question_generator.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uji yang menjaga isinya, bukan kodenya.
///
/// Aturan emas — satu pos hanya boleh menaikkan satu sumbu — gampang
/// dilanggar tanpa sadar waktu menambah zona baru, dan akibatnya baru
/// terasa berbulan-bulan kemudian sebagai anak yang berhenti di pos
/// keempat. Jadi aturannya dijalankan di sini, atas seluruh 78 pos.
void main() {
  final planet = <String, Map<String, dynamic>>{};
  for (final berkas in AppAssets.seedFiles) {
    planet[berkas] =
        jsonDecode(File(berkas).readAsStringSync()) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> zonaDari(Map<String, dynamic> p) =>
      (p['chapters'] as List<dynamic>).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> posDari(Map<String, dynamic> z) =>
      (z['levels'] as List<dynamic>).cast<Map<String, dynamic>>();

  DifficultyConfig cfg(Map<String, dynamic> pos) => DifficultyConfig.fromJson(
    pos['difficultyConfig'] as Map<String, dynamic>,
  );

  test('enam planet, 42 zona, 250 pos', () {
    expect(planet.length, 6);
    final zona = planet.values.expand(zonaDari).toList();
    expect(zona.length, 42);
    expect(zona.expand(posDari).length, 250);
  });

  test('tiap planet punya jumlah pos yang dijanjikan layar Galaksi', () {
    // Angka-angka ini tertulis di kartu planet pada mockup layar 25 dan
    // di README. Kalau isinya bergeser tanpa keduanya ikut berubah,
    // yang dibaca orang tua sebelum membayar jadi salah.
    const dijanjikan = {
      'grade-1': 36,
      'grade-2': 42,
      'grade-3': 44,
      'grade-4': 40,
      'grade-5': 42,
      'grade-6': 46,
    };
    for (final p in planet.values) {
      final id = (p['grade'] as Map<String, dynamic>)['id'] as String;
      expect(zonaDari(p).expand(posDari).length, dijanjikan[id], reason: id);
    }
  });

  test('tiap zona 4–8 pos, yang terakhir Gerbang Planet', () {
    // Tahap 1–2 memakai enam pos untuk seluruh zona. Tahap 4
    // melonggarkannya karena materinya tidak lagi seragam: ranah persen
    // cuma punya tiga sumbu yang benar-benar berpengaruh, dan memaksanya
    // jadi enam pos berarti dua peralihan yang tidak mengubah apa pun
    // buat anak. Yang tidak dilonggarkan: pos terakhir selalu gerbang.
    for (final p in planet.values) {
      for (final z in zonaDari(p)) {
        final pos = posDari(z);
        expect(
          pos.length,
          inInclusiveRange(4, 8),
          reason: z['title'] as String,
        );
        expect(pos.last['type'], 'boss', reason: z['title'] as String);
        expect(
          pos.take(pos.length - 1).every((l) => l['type'] == 'practice'),
          isTrue,
          reason: z['title'] as String,
        );
      }
    }
  });

  test('Gerbang Planet: 15 soal, 30 XP, tanpa bantuan visual, pakai timer', () {
    for (final p in planet.values) {
      for (final z in zonaDari(p)) {
        final gerbang = posDari(z).last;
        final c = cfg(gerbang);
        expect(gerbang['xpReward'], 30, reason: z['title'] as String);
        expect(c.questionCount, 15, reason: z['title'] as String);
        expect(c.visualAid, VisualAid.tidakAda, reason: z['title'] as String);
        expect(c.timeLimitSeconds, isNotNull, reason: z['title'] as String);
      }
    }
  });

  test('pos biasa: 10 soal dan 10 XP', () {
    for (final p in planet.values) {
      for (final z in zonaDari(p)) {
        for (final pos in posDari(z).where((l) => l['type'] != 'boss')) {
          expect(cfg(pos).questionCount, 10, reason: pos['id'] as String);
          expect(pos['xpReward'], 10, reason: pos['id'] as String);
        }
      }
    }
  });

  test('ATURAN EMAS: tiap pos menaikkan tepat satu sumbu dari pos '
      'sebelumnya', () {
    for (final p in planet.values) {
      for (final z in zonaDari(p)) {
        // Seluruh pos latihan, bukan lima pertama: zona sekarang boleh
        // lebih panjang, dan peralihan keenam sama pentingnya dengan
        // yang pertama.
        final pos = posDari(z).where((l) => l['type'] != 'boss').toList();
        for (var i = 1; i < pos.length; i++) {
          final beda = cfg(pos[i]).bedaSumbuDari(cfg(pos[i - 1]));
          expect(
            beda.length,
            1,
            reason:
                '${z['title']} · ${pos[i]['id']} mengubah ${beda.length} '
                'sumbu sekaligus: ${beda.join(", ")}',
          );
        }
      }
    }
  });

  test('pos pertama tiap zona bisa dijawab tanpa mengetik dan tanpa '
      'dikejar waktu — pintu masuk yang bisa dilewati siapa pun', () {
    // Dulu aturannya "harus pilihanGanda". Tahap 4 menambah tiga bentuk
    // soal yang juga berpilihan — cerita, geometri, statistik — dan
    // menuntut `pilihanGanda` secara harfiah akan menolaknya tanpa
    // alasan. Yang sebenarnya dijaga aturan ini dua hal: tidak ada
    // ketikan, dan tidak ada timer.
    for (final p in planet.values) {
      for (final z in zonaDari(p)) {
        final c = cfg(posDari(z).first);
        expect(
          c.formats,
          isNot(contains(QuestionFormat.isian)),
          reason: z['title'] as String,
        );
        expect(c.timeLimitSeconds, isNull, reason: z['title'] as String);
      }
    }
  });

  test('id pos dan zona tidak ada yang kembar', () {
    final idZona = <String>[];
    final idPos = <String>[];
    for (final p in planet.values) {
      for (final z in zonaDari(p)) {
        idZona.add(z['id'] as String);
        idPos.addAll(posDari(z).map((l) => l['id'] as String));
      }
    }
    expect(idZona.toSet().length, idZona.length);
    expect(idPos.toSet().length, idPos.length);
  });

  test('tiap konfigurasi benar-benar bisa membangkitkan soalnya', () {
    final gen = QuestionGenerator();
    for (final p in planet.values) {
      for (final z in zonaDari(p)) {
        for (final pos in posDari(z)) {
          final c = cfg(pos);
          final soal = gen.generate(c);
          expect(
            soal.length,
            c.questionCount,
            reason: '${pos['id']} kurang soal',
          );
          for (final s in soal) {
            expect(s.answer, isNotEmpty, reason: '${pos['id']}: ${s.prompt}');
            if (s.format == QuestionFormat.pilihanGanda) {
              expect(
                s.options.where((o) => o.isCorrect).length,
                1,
                reason: '${pos['id']}: ${s.prompt}',
              );
              expect(
                s.options.length,
                c.optionCount,
                reason:
                    '${pos['id']}: ${s.prompt} → '
                    '${s.options.map((o) => o.label).join(" | ")}',
              );
            }
            // Papan angka cuma punya angka: soal isian tidak boleh
            // pernah meminta lambang operasi.
            if (s.format == QuestionFormat.isian) {
              expect(
                int.tryParse(s.answer),
                isNotNull,
                reason: '${pos['id']}: ${s.prompt}',
              );
            }
          }
        }
      }
    }
  });
}
