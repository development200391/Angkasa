import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Pemberitahuan harian.
///
/// **Lokal sepenuhnya** — tidak ada peladen, tidak ada token yang
/// dikirim ke mana pun, dan tetap jalan tanpa sinyal. Untuk aplikasi
/// anak, itu bukan cuma soal teknis: pemberitahuan push berarti ada
/// daftar perangkat di suatu tempat, dan daftar itu harus dijelaskan ke
/// orang tua.
///
/// Isinya menyebut angka streak yang nyata, bukan ajakan umum. Jamnya
/// dipelajari dari `question_attempts` — jam anak biasanya main — bukan
/// dipatok di kode.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _idHarian = 1001;
  static const _channelId = 'angkasa_harian';

  /// Dipakai kalau kebiasaannya belum terbaca: sore sepulang sekolah,
  /// sebelum jam belajar malam.
  static const jamBawaan = 17;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _siap = false;

  Future<void> init() async {
    if (_siap) return;
    tzdata.initializeTimeZones();

    // Tanpa ini `tz.local` tetap UTC, dan pengingat pukul 18.00 jatuh di
    // 01.00 dini hari untuk anak di Jakarta. Kalau nama zonanya tidak
    // dikenali, UTC dipakai apa adanya — pengingat yang meleset lebih
    // baik daripada aplikasi yang gagal jalan.
    try {
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (e) {
      debugPrint('Zona waktu perangkat tidak dikenali: $e');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _siap = true;
  }

  /// Izin diminta belakangan, bukan saat pertama buka. Anak yang belum
  /// tahu aplikasinya apa tidak punya alasan mengizinkan apa pun.
  Future<bool> mintaIzin() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final hasil =
        await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, sound: true) ??
        true;
    return hasil;
  }

  /// Satu pemberitahuan per hari, berulang di jam yang sama.
  Future<void> jadwalkanHarian({
    required int jam,
    required String judul,
    required String isi,
  }) async {
    await init();
    await batalkan();

    final sekarang = tz.TZDateTime.now(tz.local);
    var waktu = tz.TZDateTime(
      tz.local,
      sekarang.year,
      sekarang.month,
      sekarang.day,
      jam,
    );
    if (!waktu.isAfter(sekarang)) {
      waktu = waktu.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: _idHarian,
        title: judul,
        body: isi,
        scheduledDate: waktu,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Pengingat harian',
            channelDescription:
                'Satu pengingat per hari untuk menjaga streak belajar.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Perangkat yang menolak alarm tepat waktu tidak boleh membuat
      // aplikasinya gagal jalan — pengingat cuma pelengkap.
      debugPrint('Jadwal pemberitahuan gagal: $e');
    }
  }

  Future<void> batalkan() async {
    await init();
    await _plugin.cancel(id: _idHarian);
  }

  /// Kalimat pemberitahuan. Menyebut angka yang nyata — streak yang
  /// sedang berjalan dan pos yang menunggu — karena ajakan umum
  /// ("ayo belajar!") diabaikan setelah hari kedua.
  static ({String judul, String isi}) kalimat({
    required int streak,
    required String? posBerikutnya,
    required int menungguDiperbaiki,
  }) {
    final judul = streak > 0
        ? 'Streak $streak hari kamu menunggu'
        : 'Ayo mulai streak hari ini';

    final bagian = <String>[
      if (streak > 0)
        'Satu pos lagi hari ini, tiga menit saja.'
      else
        'Satu pos saja hari ini, tiga menit.',
      if (posBerikutnya != null) '$posBerikutnya sudah terbuka.',
      if (posBerikutnya == null && menungguDiperbaiki > 0)
        '$menungguDiperbaiki soal menunggu diperbaiki.',
    ];
    return (judul: judul, isi: bagian.join(' '));
  }
}
