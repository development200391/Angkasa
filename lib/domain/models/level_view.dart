import 'chapter.dart';
import 'enums.dart';
import 'grade.dart';
import 'level.dart';
import 'level_progress.dart';

/// Satu pos beserta progresnya — bentuk yang dipakai peta lintasan.
class LevelView {
  const LevelView({required this.level, required this.progress});

  final Level level;
  final LevelProgress progress;

  int get stars => progress.stars;

  LevelStatus get status {
    if (!progress.isUnlocked) return LevelStatus.locked;
    if (level.isBoss) return LevelStatus.boss;
    if (progress.isCompleted) return LevelStatus.completed;
    return LevelStatus.unlocked;
  }

  bool get isLocked => status == LevelStatus.locked;
}

/// Satu zona beserta pos-posnya.
class ChapterView {
  const ChapterView({required this.chapter, required this.levels});

  final Chapter chapter;
  final List<LevelView> levels;

  int get selesai => levels.where((l) => l.progress.isCompleted).length;

  int get total => levels.length;

  bool get terbuka => levels.any((l) => !l.isLocked);

  /// Zona dianggap selesai kalau Gerbang Planetnya sudah lulus.
  bool get tuntas =>
      levels.where((l) => l.level.isBoss).every((l) => l.progress.isCompleted);

  /// Pos yang harus dikerjakan berikutnya di zona ini.
  LevelView? get posAktif {
    for (final l in levels) {
      if (!l.isLocked && !l.progress.isCompleted) return l;
    }
    return null;
  }
}

/// Seluruh isi satu planet — yang dibaca layar Jelajah sekali jalan.
class PetaPlanet {
  const PetaPlanet({
    required this.grade,
    required this.chapters,
    required this.totalStars,
  });

  final Grade grade;
  final List<ChapterView> chapters;
  final int totalStars;

  bool get kosong => chapters.isEmpty;

  /// Zona yang sedang dikerjakan: zona terbuka pertama yang belum tuntas.
  ChapterView? get zonaAktif {
    for (final c in chapters) {
      if (c.terbuka && !c.tuntas) return c;
    }
    for (final c in chapters.reversed) {
      if (c.terbuka) return c;
    }
    return chapters.isEmpty ? null : chapters.first;
  }

  ChapterView? zonaDari(String chapterId) {
    for (final c in chapters) {
      if (c.chapter.id == chapterId) return c;
    }
    return null;
  }

  LevelView? levelDari(String levelId) {
    for (final c in chapters) {
      for (final l in c.levels) {
        if (l.level.id == levelId) return l;
      }
    }
    return null;
  }
}
