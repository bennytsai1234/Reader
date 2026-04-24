// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_temp_chapter_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$ReaderTempChapterCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReaderTempChapterCachesTable get readerTempChapterCaches =>
      attachedDatabase.readerTempChapterCaches;
  ReaderTempChapterCacheDaoManager get managers =>
      ReaderTempChapterCacheDaoManager(this);
}

class ReaderTempChapterCacheDaoManager {
  final _$ReaderTempChapterCacheDaoMixin _db;
  ReaderTempChapterCacheDaoManager(this._db);
  $$ReaderTempChapterCachesTableTableManager get readerTempChapterCaches =>
      $$ReaderTempChapterCachesTableTableManager(
        _db.attachedDatabase,
        _db.readerTempChapterCaches,
      );
}
