// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookUrlMeta = const VerificationMeta(
    'bookUrl',
  );
  @override
  late final GeneratedColumn<String> bookUrl = GeneratedColumn<String>(
    'bookUrl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tocUrlMeta = const VerificationMeta('tocUrl');
  @override
  late final GeneratedColumn<String> tocUrl = GeneratedColumn<String>(
    'tocUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originNameMeta = const VerificationMeta(
    'originName',
  );
  @override
  late final GeneratedColumn<String> originName = GeneratedColumn<String>(
    'originName',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customTagMeta = const VerificationMeta(
    'customTag',
  );
  @override
  late final GeneratedColumn<String> customTag = GeneratedColumn<String>(
    'customTag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'coverUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customCoverUrlMeta = const VerificationMeta(
    'customCoverUrl',
  );
  @override
  late final GeneratedColumn<String> customCoverUrl = GeneratedColumn<String>(
    'customCoverUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _introMeta = const VerificationMeta('intro');
  @override
  late final GeneratedColumn<String> intro = GeneratedColumn<String>(
    'intro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customIntroMeta = const VerificationMeta(
    'customIntro',
  );
  @override
  late final GeneratedColumn<String> customIntro = GeneratedColumn<String>(
    'customIntro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _charsetMeta = const VerificationMeta(
    'charset',
  );
  @override
  late final GeneratedColumn<String> charset = GeneratedColumn<String>(
    'charset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<int> group = GeneratedColumn<int>(
    'group',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _latestChapterTitleMeta =
      const VerificationMeta('latestChapterTitle');
  @override
  late final GeneratedColumn<String> latestChapterTitle =
      GeneratedColumn<String>(
        'latestChapterTitle',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestChapterTimeMeta = const VerificationMeta(
    'latestChapterTime',
  );
  @override
  late final GeneratedColumn<int> latestChapterTime = GeneratedColumn<int>(
    'latestChapterTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCheckTimeMeta = const VerificationMeta(
    'lastCheckTime',
  );
  @override
  late final GeneratedColumn<int> lastCheckTime = GeneratedColumn<int>(
    'lastCheckTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCheckCountMeta = const VerificationMeta(
    'lastCheckCount',
  );
  @override
  late final GeneratedColumn<int> lastCheckCount = GeneratedColumn<int>(
    'lastCheckCount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalChapterNumMeta = const VerificationMeta(
    'totalChapterNum',
  );
  @override
  late final GeneratedColumn<int> totalChapterNum = GeneratedColumn<int>(
    'totalChapterNum',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durChapterTitleMeta = const VerificationMeta(
    'durChapterTitle',
  );
  @override
  late final GeneratedColumn<String> durChapterTitle = GeneratedColumn<String>(
    'durChapterTitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durChapterIndexMeta = const VerificationMeta(
    'durChapterIndex',
  );
  @override
  late final GeneratedColumn<int> durChapterIndex = GeneratedColumn<int>(
    'durChapterIndex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durChapterPosMeta = const VerificationMeta(
    'durChapterPos',
  );
  @override
  late final GeneratedColumn<int> durChapterPos = GeneratedColumn<int>(
    'durChapterPos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durChapterTimeMeta = const VerificationMeta(
    'durChapterTime',
  );
  @override
  late final GeneratedColumn<int> durChapterTime = GeneratedColumn<int>(
    'durChapterTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<String> wordCount = GeneratedColumn<String>(
    'wordCount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canUpdateMeta = const VerificationMeta(
    'canUpdate',
  );
  @override
  late final GeneratedColumn<int> canUpdate = GeneratedColumn<int>(
    'canUpdate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _originOrderMeta = const VerificationMeta(
    'originOrder',
  );
  @override
  late final GeneratedColumn<int> originOrder = GeneratedColumn<int>(
    'originOrder',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _variableMeta = const VerificationMeta(
    'variable',
  );
  @override
  late final GeneratedColumn<String> variable = GeneratedColumn<String>(
    'variable',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readConfigMeta = const VerificationMeta(
    'readConfig',
  );
  @override
  late final GeneratedColumn<String> readConfig = GeneratedColumn<String>(
    'readConfig',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncTimeMeta = const VerificationMeta(
    'syncTime',
  );
  @override
  late final GeneratedColumn<int> syncTime = GeneratedColumn<int>(
    'syncTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isInBookshelfMeta = const VerificationMeta(
    'isInBookshelf',
  );
  @override
  late final GeneratedColumn<int> isInBookshelf = GeneratedColumn<int>(
    'isInBookshelf',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookUrl,
    tocUrl,
    origin,
    originName,
    name,
    author,
    kind,
    customTag,
    coverUrl,
    customCoverUrl,
    intro,
    customIntro,
    charset,
    type,
    group,
    latestChapterTitle,
    latestChapterTime,
    lastCheckTime,
    lastCheckCount,
    totalChapterNum,
    durChapterTitle,
    durChapterIndex,
    durChapterPos,
    durChapterTime,
    wordCount,
    canUpdate,
    order,
    originOrder,
    variable,
    readConfig,
    syncTime,
    isInBookshelf,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bookUrl')) {
      context.handle(
        _bookUrlMeta,
        bookUrl.isAcceptableOrUnknown(data['bookUrl']!, _bookUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bookUrlMeta);
    }
    if (data.containsKey('tocUrl')) {
      context.handle(
        _tocUrlMeta,
        tocUrl.isAcceptableOrUnknown(data['tocUrl']!, _tocUrlMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('originName')) {
      context.handle(
        _originNameMeta,
        originName.isAcceptableOrUnknown(data['originName']!, _originNameMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('customTag')) {
      context.handle(
        _customTagMeta,
        customTag.isAcceptableOrUnknown(data['customTag']!, _customTagMeta),
      );
    }
    if (data.containsKey('coverUrl')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['coverUrl']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('customCoverUrl')) {
      context.handle(
        _customCoverUrlMeta,
        customCoverUrl.isAcceptableOrUnknown(
          data['customCoverUrl']!,
          _customCoverUrlMeta,
        ),
      );
    }
    if (data.containsKey('intro')) {
      context.handle(
        _introMeta,
        intro.isAcceptableOrUnknown(data['intro']!, _introMeta),
      );
    }
    if (data.containsKey('customIntro')) {
      context.handle(
        _customIntroMeta,
        customIntro.isAcceptableOrUnknown(
          data['customIntro']!,
          _customIntroMeta,
        ),
      );
    }
    if (data.containsKey('charset')) {
      context.handle(
        _charsetMeta,
        charset.isAcceptableOrUnknown(data['charset']!, _charsetMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('group')) {
      context.handle(
        _groupMeta,
        group.isAcceptableOrUnknown(data['group']!, _groupMeta),
      );
    }
    if (data.containsKey('latestChapterTitle')) {
      context.handle(
        _latestChapterTitleMeta,
        latestChapterTitle.isAcceptableOrUnknown(
          data['latestChapterTitle']!,
          _latestChapterTitleMeta,
        ),
      );
    }
    if (data.containsKey('latestChapterTime')) {
      context.handle(
        _latestChapterTimeMeta,
        latestChapterTime.isAcceptableOrUnknown(
          data['latestChapterTime']!,
          _latestChapterTimeMeta,
        ),
      );
    }
    if (data.containsKey('lastCheckTime')) {
      context.handle(
        _lastCheckTimeMeta,
        lastCheckTime.isAcceptableOrUnknown(
          data['lastCheckTime']!,
          _lastCheckTimeMeta,
        ),
      );
    }
    if (data.containsKey('lastCheckCount')) {
      context.handle(
        _lastCheckCountMeta,
        lastCheckCount.isAcceptableOrUnknown(
          data['lastCheckCount']!,
          _lastCheckCountMeta,
        ),
      );
    }
    if (data.containsKey('totalChapterNum')) {
      context.handle(
        _totalChapterNumMeta,
        totalChapterNum.isAcceptableOrUnknown(
          data['totalChapterNum']!,
          _totalChapterNumMeta,
        ),
      );
    }
    if (data.containsKey('durChapterTitle')) {
      context.handle(
        _durChapterTitleMeta,
        durChapterTitle.isAcceptableOrUnknown(
          data['durChapterTitle']!,
          _durChapterTitleMeta,
        ),
      );
    }
    if (data.containsKey('durChapterIndex')) {
      context.handle(
        _durChapterIndexMeta,
        durChapterIndex.isAcceptableOrUnknown(
          data['durChapterIndex']!,
          _durChapterIndexMeta,
        ),
      );
    }
    if (data.containsKey('durChapterPos')) {
      context.handle(
        _durChapterPosMeta,
        durChapterPos.isAcceptableOrUnknown(
          data['durChapterPos']!,
          _durChapterPosMeta,
        ),
      );
    }
    if (data.containsKey('durChapterTime')) {
      context.handle(
        _durChapterTimeMeta,
        durChapterTime.isAcceptableOrUnknown(
          data['durChapterTime']!,
          _durChapterTimeMeta,
        ),
      );
    }
    if (data.containsKey('wordCount')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['wordCount']!, _wordCountMeta),
      );
    }
    if (data.containsKey('canUpdate')) {
      context.handle(
        _canUpdateMeta,
        canUpdate.isAcceptableOrUnknown(data['canUpdate']!, _canUpdateMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('originOrder')) {
      context.handle(
        _originOrderMeta,
        originOrder.isAcceptableOrUnknown(
          data['originOrder']!,
          _originOrderMeta,
        ),
      );
    }
    if (data.containsKey('variable')) {
      context.handle(
        _variableMeta,
        variable.isAcceptableOrUnknown(data['variable']!, _variableMeta),
      );
    }
    if (data.containsKey('readConfig')) {
      context.handle(
        _readConfigMeta,
        readConfig.isAcceptableOrUnknown(data['readConfig']!, _readConfigMeta),
      );
    }
    if (data.containsKey('syncTime')) {
      context.handle(
        _syncTimeMeta,
        syncTime.isAcceptableOrUnknown(data['syncTime']!, _syncTimeMeta),
      );
    }
    if (data.containsKey('isInBookshelf')) {
      context.handle(
        _isInBookshelfMeta,
        isInBookshelf.isAcceptableOrUnknown(
          data['isInBookshelf']!,
          _isInBookshelfMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookUrl};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      bookUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookUrl'],
          )!,
      tocUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tocUrl'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      originName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}originName'],
      ),
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      customTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customTag'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverUrl'],
      ),
      customCoverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customCoverUrl'],
      ),
      intro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intro'],
      ),
      customIntro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customIntro'],
      ),
      charset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}charset'],
      ),
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}type'],
          )!,
      group:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}group'],
          )!,
      latestChapterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latestChapterTitle'],
      ),
      latestChapterTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}latestChapterTime'],
          )!,
      lastCheckTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}lastCheckTime'],
          )!,
      lastCheckCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}lastCheckCount'],
          )!,
      totalChapterNum:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}totalChapterNum'],
          )!,
      durChapterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}durChapterTitle'],
      ),
      durChapterIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}durChapterIndex'],
          )!,
      durChapterPos:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}durChapterPos'],
          )!,
      durChapterTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}durChapterTime'],
          )!,
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wordCount'],
      ),
      canUpdate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}canUpdate'],
          )!,
      order:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}order'],
          )!,
      originOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}originOrder'],
          )!,
      variable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variable'],
      ),
      readConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}readConfig'],
      ),
      syncTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}syncTime'],
          )!,
      isInBookshelf:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}isInBookshelf'],
          )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final String bookUrl;
  final String? tocUrl;
  final String? origin;
  final String? originName;
  final String name;
  final String? author;
  final String? kind;
  final String? customTag;
  final String? coverUrl;
  final String? customCoverUrl;
  final String? intro;
  final String? customIntro;
  final String? charset;
  final int type;
  final int group;
  final String? latestChapterTitle;
  final int latestChapterTime;
  final int lastCheckTime;
  final int lastCheckCount;
  final int totalChapterNum;
  final String? durChapterTitle;
  final int durChapterIndex;
  final int durChapterPos;
  final int durChapterTime;
  final String? wordCount;
  final int canUpdate;
  final int order;
  final int originOrder;
  final String? variable;
  final String? readConfig;
  final int syncTime;
  final int isInBookshelf;
  const BookRow({
    required this.bookUrl,
    this.tocUrl,
    this.origin,
    this.originName,
    required this.name,
    this.author,
    this.kind,
    this.customTag,
    this.coverUrl,
    this.customCoverUrl,
    this.intro,
    this.customIntro,
    this.charset,
    required this.type,
    required this.group,
    this.latestChapterTitle,
    required this.latestChapterTime,
    required this.lastCheckTime,
    required this.lastCheckCount,
    required this.totalChapterNum,
    this.durChapterTitle,
    required this.durChapterIndex,
    required this.durChapterPos,
    required this.durChapterTime,
    this.wordCount,
    required this.canUpdate,
    required this.order,
    required this.originOrder,
    this.variable,
    this.readConfig,
    required this.syncTime,
    required this.isInBookshelf,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bookUrl'] = Variable<String>(bookUrl);
    if (!nullToAbsent || tocUrl != null) {
      map['tocUrl'] = Variable<String>(tocUrl);
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || originName != null) {
      map['originName'] = Variable<String>(originName);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || customTag != null) {
      map['customTag'] = Variable<String>(customTag);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['coverUrl'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || customCoverUrl != null) {
      map['customCoverUrl'] = Variable<String>(customCoverUrl);
    }
    if (!nullToAbsent || intro != null) {
      map['intro'] = Variable<String>(intro);
    }
    if (!nullToAbsent || customIntro != null) {
      map['customIntro'] = Variable<String>(customIntro);
    }
    if (!nullToAbsent || charset != null) {
      map['charset'] = Variable<String>(charset);
    }
    map['type'] = Variable<int>(type);
    map['group'] = Variable<int>(group);
    if (!nullToAbsent || latestChapterTitle != null) {
      map['latestChapterTitle'] = Variable<String>(latestChapterTitle);
    }
    map['latestChapterTime'] = Variable<int>(latestChapterTime);
    map['lastCheckTime'] = Variable<int>(lastCheckTime);
    map['lastCheckCount'] = Variable<int>(lastCheckCount);
    map['totalChapterNum'] = Variable<int>(totalChapterNum);
    if (!nullToAbsent || durChapterTitle != null) {
      map['durChapterTitle'] = Variable<String>(durChapterTitle);
    }
    map['durChapterIndex'] = Variable<int>(durChapterIndex);
    map['durChapterPos'] = Variable<int>(durChapterPos);
    map['durChapterTime'] = Variable<int>(durChapterTime);
    if (!nullToAbsent || wordCount != null) {
      map['wordCount'] = Variable<String>(wordCount);
    }
    map['canUpdate'] = Variable<int>(canUpdate);
    map['order'] = Variable<int>(order);
    map['originOrder'] = Variable<int>(originOrder);
    if (!nullToAbsent || variable != null) {
      map['variable'] = Variable<String>(variable);
    }
    if (!nullToAbsent || readConfig != null) {
      map['readConfig'] = Variable<String>(readConfig);
    }
    map['syncTime'] = Variable<int>(syncTime);
    map['isInBookshelf'] = Variable<int>(isInBookshelf);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      bookUrl: Value(bookUrl),
      tocUrl:
          tocUrl == null && nullToAbsent ? const Value.absent() : Value(tocUrl),
      origin:
          origin == null && nullToAbsent ? const Value.absent() : Value(origin),
      originName:
          originName == null && nullToAbsent
              ? const Value.absent()
              : Value(originName),
      name: Value(name),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      customTag:
          customTag == null && nullToAbsent
              ? const Value.absent()
              : Value(customTag),
      coverUrl:
          coverUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(coverUrl),
      customCoverUrl:
          customCoverUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(customCoverUrl),
      intro:
          intro == null && nullToAbsent ? const Value.absent() : Value(intro),
      customIntro:
          customIntro == null && nullToAbsent
              ? const Value.absent()
              : Value(customIntro),
      charset:
          charset == null && nullToAbsent
              ? const Value.absent()
              : Value(charset),
      type: Value(type),
      group: Value(group),
      latestChapterTitle:
          latestChapterTitle == null && nullToAbsent
              ? const Value.absent()
              : Value(latestChapterTitle),
      latestChapterTime: Value(latestChapterTime),
      lastCheckTime: Value(lastCheckTime),
      lastCheckCount: Value(lastCheckCount),
      totalChapterNum: Value(totalChapterNum),
      durChapterTitle:
          durChapterTitle == null && nullToAbsent
              ? const Value.absent()
              : Value(durChapterTitle),
      durChapterIndex: Value(durChapterIndex),
      durChapterPos: Value(durChapterPos),
      durChapterTime: Value(durChapterTime),
      wordCount:
          wordCount == null && nullToAbsent
              ? const Value.absent()
              : Value(wordCount),
      canUpdate: Value(canUpdate),
      order: Value(order),
      originOrder: Value(originOrder),
      variable:
          variable == null && nullToAbsent
              ? const Value.absent()
              : Value(variable),
      readConfig:
          readConfig == null && nullToAbsent
              ? const Value.absent()
              : Value(readConfig),
      syncTime: Value(syncTime),
      isInBookshelf: Value(isInBookshelf),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      bookUrl: serializer.fromJson<String>(json['bookUrl']),
      tocUrl: serializer.fromJson<String?>(json['tocUrl']),
      origin: serializer.fromJson<String?>(json['origin']),
      originName: serializer.fromJson<String?>(json['originName']),
      name: serializer.fromJson<String>(json['name']),
      author: serializer.fromJson<String?>(json['author']),
      kind: serializer.fromJson<String?>(json['kind']),
      customTag: serializer.fromJson<String?>(json['customTag']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      customCoverUrl: serializer.fromJson<String?>(json['customCoverUrl']),
      intro: serializer.fromJson<String?>(json['intro']),
      customIntro: serializer.fromJson<String?>(json['customIntro']),
      charset: serializer.fromJson<String?>(json['charset']),
      type: serializer.fromJson<int>(json['type']),
      group: serializer.fromJson<int>(json['group']),
      latestChapterTitle: serializer.fromJson<String?>(
        json['latestChapterTitle'],
      ),
      latestChapterTime: serializer.fromJson<int>(json['latestChapterTime']),
      lastCheckTime: serializer.fromJson<int>(json['lastCheckTime']),
      lastCheckCount: serializer.fromJson<int>(json['lastCheckCount']),
      totalChapterNum: serializer.fromJson<int>(json['totalChapterNum']),
      durChapterTitle: serializer.fromJson<String?>(json['durChapterTitle']),
      durChapterIndex: serializer.fromJson<int>(json['durChapterIndex']),
      durChapterPos: serializer.fromJson<int>(json['durChapterPos']),
      durChapterTime: serializer.fromJson<int>(json['durChapterTime']),
      wordCount: serializer.fromJson<String?>(json['wordCount']),
      canUpdate: serializer.fromJson<int>(json['canUpdate']),
      order: serializer.fromJson<int>(json['order']),
      originOrder: serializer.fromJson<int>(json['originOrder']),
      variable: serializer.fromJson<String?>(json['variable']),
      readConfig: serializer.fromJson<String?>(json['readConfig']),
      syncTime: serializer.fromJson<int>(json['syncTime']),
      isInBookshelf: serializer.fromJson<int>(json['isInBookshelf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookUrl': serializer.toJson<String>(bookUrl),
      'tocUrl': serializer.toJson<String?>(tocUrl),
      'origin': serializer.toJson<String?>(origin),
      'originName': serializer.toJson<String?>(originName),
      'name': serializer.toJson<String>(name),
      'author': serializer.toJson<String?>(author),
      'kind': serializer.toJson<String?>(kind),
      'customTag': serializer.toJson<String?>(customTag),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'customCoverUrl': serializer.toJson<String?>(customCoverUrl),
      'intro': serializer.toJson<String?>(intro),
      'customIntro': serializer.toJson<String?>(customIntro),
      'charset': serializer.toJson<String?>(charset),
      'type': serializer.toJson<int>(type),
      'group': serializer.toJson<int>(group),
      'latestChapterTitle': serializer.toJson<String?>(latestChapterTitle),
      'latestChapterTime': serializer.toJson<int>(latestChapterTime),
      'lastCheckTime': serializer.toJson<int>(lastCheckTime),
      'lastCheckCount': serializer.toJson<int>(lastCheckCount),
      'totalChapterNum': serializer.toJson<int>(totalChapterNum),
      'durChapterTitle': serializer.toJson<String?>(durChapterTitle),
      'durChapterIndex': serializer.toJson<int>(durChapterIndex),
      'durChapterPos': serializer.toJson<int>(durChapterPos),
      'durChapterTime': serializer.toJson<int>(durChapterTime),
      'wordCount': serializer.toJson<String?>(wordCount),
      'canUpdate': serializer.toJson<int>(canUpdate),
      'order': serializer.toJson<int>(order),
      'originOrder': serializer.toJson<int>(originOrder),
      'variable': serializer.toJson<String?>(variable),
      'readConfig': serializer.toJson<String?>(readConfig),
      'syncTime': serializer.toJson<int>(syncTime),
      'isInBookshelf': serializer.toJson<int>(isInBookshelf),
    };
  }

  BookRow copyWith({
    String? bookUrl,
    Value<String?> tocUrl = const Value.absent(),
    Value<String?> origin = const Value.absent(),
    Value<String?> originName = const Value.absent(),
    String? name,
    Value<String?> author = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    Value<String?> customTag = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> customCoverUrl = const Value.absent(),
    Value<String?> intro = const Value.absent(),
    Value<String?> customIntro = const Value.absent(),
    Value<String?> charset = const Value.absent(),
    int? type,
    int? group,
    Value<String?> latestChapterTitle = const Value.absent(),
    int? latestChapterTime,
    int? lastCheckTime,
    int? lastCheckCount,
    int? totalChapterNum,
    Value<String?> durChapterTitle = const Value.absent(),
    int? durChapterIndex,
    int? durChapterPos,
    int? durChapterTime,
    Value<String?> wordCount = const Value.absent(),
    int? canUpdate,
    int? order,
    int? originOrder,
    Value<String?> variable = const Value.absent(),
    Value<String?> readConfig = const Value.absent(),
    int? syncTime,
    int? isInBookshelf,
  }) => BookRow(
    bookUrl: bookUrl ?? this.bookUrl,
    tocUrl: tocUrl.present ? tocUrl.value : this.tocUrl,
    origin: origin.present ? origin.value : this.origin,
    originName: originName.present ? originName.value : this.originName,
    name: name ?? this.name,
    author: author.present ? author.value : this.author,
    kind: kind.present ? kind.value : this.kind,
    customTag: customTag.present ? customTag.value : this.customTag,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    customCoverUrl:
        customCoverUrl.present ? customCoverUrl.value : this.customCoverUrl,
    intro: intro.present ? intro.value : this.intro,
    customIntro: customIntro.present ? customIntro.value : this.customIntro,
    charset: charset.present ? charset.value : this.charset,
    type: type ?? this.type,
    group: group ?? this.group,
    latestChapterTitle:
        latestChapterTitle.present
            ? latestChapterTitle.value
            : this.latestChapterTitle,
    latestChapterTime: latestChapterTime ?? this.latestChapterTime,
    lastCheckTime: lastCheckTime ?? this.lastCheckTime,
    lastCheckCount: lastCheckCount ?? this.lastCheckCount,
    totalChapterNum: totalChapterNum ?? this.totalChapterNum,
    durChapterTitle:
        durChapterTitle.present ? durChapterTitle.value : this.durChapterTitle,
    durChapterIndex: durChapterIndex ?? this.durChapterIndex,
    durChapterPos: durChapterPos ?? this.durChapterPos,
    durChapterTime: durChapterTime ?? this.durChapterTime,
    wordCount: wordCount.present ? wordCount.value : this.wordCount,
    canUpdate: canUpdate ?? this.canUpdate,
    order: order ?? this.order,
    originOrder: originOrder ?? this.originOrder,
    variable: variable.present ? variable.value : this.variable,
    readConfig: readConfig.present ? readConfig.value : this.readConfig,
    syncTime: syncTime ?? this.syncTime,
    isInBookshelf: isInBookshelf ?? this.isInBookshelf,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      bookUrl: data.bookUrl.present ? data.bookUrl.value : this.bookUrl,
      tocUrl: data.tocUrl.present ? data.tocUrl.value : this.tocUrl,
      origin: data.origin.present ? data.origin.value : this.origin,
      originName:
          data.originName.present ? data.originName.value : this.originName,
      name: data.name.present ? data.name.value : this.name,
      author: data.author.present ? data.author.value : this.author,
      kind: data.kind.present ? data.kind.value : this.kind,
      customTag: data.customTag.present ? data.customTag.value : this.customTag,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      customCoverUrl:
          data.customCoverUrl.present
              ? data.customCoverUrl.value
              : this.customCoverUrl,
      intro: data.intro.present ? data.intro.value : this.intro,
      customIntro:
          data.customIntro.present ? data.customIntro.value : this.customIntro,
      charset: data.charset.present ? data.charset.value : this.charset,
      type: data.type.present ? data.type.value : this.type,
      group: data.group.present ? data.group.value : this.group,
      latestChapterTitle:
          data.latestChapterTitle.present
              ? data.latestChapterTitle.value
              : this.latestChapterTitle,
      latestChapterTime:
          data.latestChapterTime.present
              ? data.latestChapterTime.value
              : this.latestChapterTime,
      lastCheckTime:
          data.lastCheckTime.present
              ? data.lastCheckTime.value
              : this.lastCheckTime,
      lastCheckCount:
          data.lastCheckCount.present
              ? data.lastCheckCount.value
              : this.lastCheckCount,
      totalChapterNum:
          data.totalChapterNum.present
              ? data.totalChapterNum.value
              : this.totalChapterNum,
      durChapterTitle:
          data.durChapterTitle.present
              ? data.durChapterTitle.value
              : this.durChapterTitle,
      durChapterIndex:
          data.durChapterIndex.present
              ? data.durChapterIndex.value
              : this.durChapterIndex,
      durChapterPos:
          data.durChapterPos.present
              ? data.durChapterPos.value
              : this.durChapterPos,
      durChapterTime:
          data.durChapterTime.present
              ? data.durChapterTime.value
              : this.durChapterTime,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      canUpdate: data.canUpdate.present ? data.canUpdate.value : this.canUpdate,
      order: data.order.present ? data.order.value : this.order,
      originOrder:
          data.originOrder.present ? data.originOrder.value : this.originOrder,
      variable: data.variable.present ? data.variable.value : this.variable,
      readConfig:
          data.readConfig.present ? data.readConfig.value : this.readConfig,
      syncTime: data.syncTime.present ? data.syncTime.value : this.syncTime,
      isInBookshelf:
          data.isInBookshelf.present
              ? data.isInBookshelf.value
              : this.isInBookshelf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('bookUrl: $bookUrl, ')
          ..write('tocUrl: $tocUrl, ')
          ..write('origin: $origin, ')
          ..write('originName: $originName, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('customTag: $customTag, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('customCoverUrl: $customCoverUrl, ')
          ..write('intro: $intro, ')
          ..write('customIntro: $customIntro, ')
          ..write('charset: $charset, ')
          ..write('type: $type, ')
          ..write('group: $group, ')
          ..write('latestChapterTitle: $latestChapterTitle, ')
          ..write('latestChapterTime: $latestChapterTime, ')
          ..write('lastCheckTime: $lastCheckTime, ')
          ..write('lastCheckCount: $lastCheckCount, ')
          ..write('totalChapterNum: $totalChapterNum, ')
          ..write('durChapterTitle: $durChapterTitle, ')
          ..write('durChapterIndex: $durChapterIndex, ')
          ..write('durChapterPos: $durChapterPos, ')
          ..write('durChapterTime: $durChapterTime, ')
          ..write('wordCount: $wordCount, ')
          ..write('canUpdate: $canUpdate, ')
          ..write('order: $order, ')
          ..write('originOrder: $originOrder, ')
          ..write('variable: $variable, ')
          ..write('readConfig: $readConfig, ')
          ..write('syncTime: $syncTime, ')
          ..write('isInBookshelf: $isInBookshelf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    bookUrl,
    tocUrl,
    origin,
    originName,
    name,
    author,
    kind,
    customTag,
    coverUrl,
    customCoverUrl,
    intro,
    customIntro,
    charset,
    type,
    group,
    latestChapterTitle,
    latestChapterTime,
    lastCheckTime,
    lastCheckCount,
    totalChapterNum,
    durChapterTitle,
    durChapterIndex,
    durChapterPos,
    durChapterTime,
    wordCount,
    canUpdate,
    order,
    originOrder,
    variable,
    readConfig,
    syncTime,
    isInBookshelf,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.bookUrl == this.bookUrl &&
          other.tocUrl == this.tocUrl &&
          other.origin == this.origin &&
          other.originName == this.originName &&
          other.name == this.name &&
          other.author == this.author &&
          other.kind == this.kind &&
          other.customTag == this.customTag &&
          other.coverUrl == this.coverUrl &&
          other.customCoverUrl == this.customCoverUrl &&
          other.intro == this.intro &&
          other.customIntro == this.customIntro &&
          other.charset == this.charset &&
          other.type == this.type &&
          other.group == this.group &&
          other.latestChapterTitle == this.latestChapterTitle &&
          other.latestChapterTime == this.latestChapterTime &&
          other.lastCheckTime == this.lastCheckTime &&
          other.lastCheckCount == this.lastCheckCount &&
          other.totalChapterNum == this.totalChapterNum &&
          other.durChapterTitle == this.durChapterTitle &&
          other.durChapterIndex == this.durChapterIndex &&
          other.durChapterPos == this.durChapterPos &&
          other.durChapterTime == this.durChapterTime &&
          other.wordCount == this.wordCount &&
          other.canUpdate == this.canUpdate &&
          other.order == this.order &&
          other.originOrder == this.originOrder &&
          other.variable == this.variable &&
          other.readConfig == this.readConfig &&
          other.syncTime == this.syncTime &&
          other.isInBookshelf == this.isInBookshelf);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<String> bookUrl;
  final Value<String?> tocUrl;
  final Value<String?> origin;
  final Value<String?> originName;
  final Value<String> name;
  final Value<String?> author;
  final Value<String?> kind;
  final Value<String?> customTag;
  final Value<String?> coverUrl;
  final Value<String?> customCoverUrl;
  final Value<String?> intro;
  final Value<String?> customIntro;
  final Value<String?> charset;
  final Value<int> type;
  final Value<int> group;
  final Value<String?> latestChapterTitle;
  final Value<int> latestChapterTime;
  final Value<int> lastCheckTime;
  final Value<int> lastCheckCount;
  final Value<int> totalChapterNum;
  final Value<String?> durChapterTitle;
  final Value<int> durChapterIndex;
  final Value<int> durChapterPos;
  final Value<int> durChapterTime;
  final Value<String?> wordCount;
  final Value<int> canUpdate;
  final Value<int> order;
  final Value<int> originOrder;
  final Value<String?> variable;
  final Value<String?> readConfig;
  final Value<int> syncTime;
  final Value<int> isInBookshelf;
  final Value<int> rowid;
  const BooksCompanion({
    this.bookUrl = const Value.absent(),
    this.tocUrl = const Value.absent(),
    this.origin = const Value.absent(),
    this.originName = const Value.absent(),
    this.name = const Value.absent(),
    this.author = const Value.absent(),
    this.kind = const Value.absent(),
    this.customTag = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.customCoverUrl = const Value.absent(),
    this.intro = const Value.absent(),
    this.customIntro = const Value.absent(),
    this.charset = const Value.absent(),
    this.type = const Value.absent(),
    this.group = const Value.absent(),
    this.latestChapterTitle = const Value.absent(),
    this.latestChapterTime = const Value.absent(),
    this.lastCheckTime = const Value.absent(),
    this.lastCheckCount = const Value.absent(),
    this.totalChapterNum = const Value.absent(),
    this.durChapterTitle = const Value.absent(),
    this.durChapterIndex = const Value.absent(),
    this.durChapterPos = const Value.absent(),
    this.durChapterTime = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.canUpdate = const Value.absent(),
    this.order = const Value.absent(),
    this.originOrder = const Value.absent(),
    this.variable = const Value.absent(),
    this.readConfig = const Value.absent(),
    this.syncTime = const Value.absent(),
    this.isInBookshelf = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String bookUrl,
    this.tocUrl = const Value.absent(),
    this.origin = const Value.absent(),
    this.originName = const Value.absent(),
    required String name,
    this.author = const Value.absent(),
    this.kind = const Value.absent(),
    this.customTag = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.customCoverUrl = const Value.absent(),
    this.intro = const Value.absent(),
    this.customIntro = const Value.absent(),
    this.charset = const Value.absent(),
    this.type = const Value.absent(),
    this.group = const Value.absent(),
    this.latestChapterTitle = const Value.absent(),
    this.latestChapterTime = const Value.absent(),
    this.lastCheckTime = const Value.absent(),
    this.lastCheckCount = const Value.absent(),
    this.totalChapterNum = const Value.absent(),
    this.durChapterTitle = const Value.absent(),
    this.durChapterIndex = const Value.absent(),
    this.durChapterPos = const Value.absent(),
    this.durChapterTime = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.canUpdate = const Value.absent(),
    this.order = const Value.absent(),
    this.originOrder = const Value.absent(),
    this.variable = const Value.absent(),
    this.readConfig = const Value.absent(),
    this.syncTime = const Value.absent(),
    this.isInBookshelf = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookUrl = Value(bookUrl),
       name = Value(name);
  static Insertable<BookRow> custom({
    Expression<String>? bookUrl,
    Expression<String>? tocUrl,
    Expression<String>? origin,
    Expression<String>? originName,
    Expression<String>? name,
    Expression<String>? author,
    Expression<String>? kind,
    Expression<String>? customTag,
    Expression<String>? coverUrl,
    Expression<String>? customCoverUrl,
    Expression<String>? intro,
    Expression<String>? customIntro,
    Expression<String>? charset,
    Expression<int>? type,
    Expression<int>? group,
    Expression<String>? latestChapterTitle,
    Expression<int>? latestChapterTime,
    Expression<int>? lastCheckTime,
    Expression<int>? lastCheckCount,
    Expression<int>? totalChapterNum,
    Expression<String>? durChapterTitle,
    Expression<int>? durChapterIndex,
    Expression<int>? durChapterPos,
    Expression<int>? durChapterTime,
    Expression<String>? wordCount,
    Expression<int>? canUpdate,
    Expression<int>? order,
    Expression<int>? originOrder,
    Expression<String>? variable,
    Expression<String>? readConfig,
    Expression<int>? syncTime,
    Expression<int>? isInBookshelf,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookUrl != null) 'bookUrl': bookUrl,
      if (tocUrl != null) 'tocUrl': tocUrl,
      if (origin != null) 'origin': origin,
      if (originName != null) 'originName': originName,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (kind != null) 'kind': kind,
      if (customTag != null) 'customTag': customTag,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (customCoverUrl != null) 'customCoverUrl': customCoverUrl,
      if (intro != null) 'intro': intro,
      if (customIntro != null) 'customIntro': customIntro,
      if (charset != null) 'charset': charset,
      if (type != null) 'type': type,
      if (group != null) 'group': group,
      if (latestChapterTitle != null) 'latestChapterTitle': latestChapterTitle,
      if (latestChapterTime != null) 'latestChapterTime': latestChapterTime,
      if (lastCheckTime != null) 'lastCheckTime': lastCheckTime,
      if (lastCheckCount != null) 'lastCheckCount': lastCheckCount,
      if (totalChapterNum != null) 'totalChapterNum': totalChapterNum,
      if (durChapterTitle != null) 'durChapterTitle': durChapterTitle,
      if (durChapterIndex != null) 'durChapterIndex': durChapterIndex,
      if (durChapterPos != null) 'durChapterPos': durChapterPos,
      if (durChapterTime != null) 'durChapterTime': durChapterTime,
      if (wordCount != null) 'wordCount': wordCount,
      if (canUpdate != null) 'canUpdate': canUpdate,
      if (order != null) 'order': order,
      if (originOrder != null) 'originOrder': originOrder,
      if (variable != null) 'variable': variable,
      if (readConfig != null) 'readConfig': readConfig,
      if (syncTime != null) 'syncTime': syncTime,
      if (isInBookshelf != null) 'isInBookshelf': isInBookshelf,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? bookUrl,
    Value<String?>? tocUrl,
    Value<String?>? origin,
    Value<String?>? originName,
    Value<String>? name,
    Value<String?>? author,
    Value<String?>? kind,
    Value<String?>? customTag,
    Value<String?>? coverUrl,
    Value<String?>? customCoverUrl,
    Value<String?>? intro,
    Value<String?>? customIntro,
    Value<String?>? charset,
    Value<int>? type,
    Value<int>? group,
    Value<String?>? latestChapterTitle,
    Value<int>? latestChapterTime,
    Value<int>? lastCheckTime,
    Value<int>? lastCheckCount,
    Value<int>? totalChapterNum,
    Value<String?>? durChapterTitle,
    Value<int>? durChapterIndex,
    Value<int>? durChapterPos,
    Value<int>? durChapterTime,
    Value<String?>? wordCount,
    Value<int>? canUpdate,
    Value<int>? order,
    Value<int>? originOrder,
    Value<String?>? variable,
    Value<String?>? readConfig,
    Value<int>? syncTime,
    Value<int>? isInBookshelf,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      bookUrl: bookUrl ?? this.bookUrl,
      tocUrl: tocUrl ?? this.tocUrl,
      origin: origin ?? this.origin,
      originName: originName ?? this.originName,
      name: name ?? this.name,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      customTag: customTag ?? this.customTag,
      coverUrl: coverUrl ?? this.coverUrl,
      customCoverUrl: customCoverUrl ?? this.customCoverUrl,
      intro: intro ?? this.intro,
      customIntro: customIntro ?? this.customIntro,
      charset: charset ?? this.charset,
      type: type ?? this.type,
      group: group ?? this.group,
      latestChapterTitle: latestChapterTitle ?? this.latestChapterTitle,
      latestChapterTime: latestChapterTime ?? this.latestChapterTime,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      lastCheckCount: lastCheckCount ?? this.lastCheckCount,
      totalChapterNum: totalChapterNum ?? this.totalChapterNum,
      durChapterTitle: durChapterTitle ?? this.durChapterTitle,
      durChapterIndex: durChapterIndex ?? this.durChapterIndex,
      durChapterPos: durChapterPos ?? this.durChapterPos,
      durChapterTime: durChapterTime ?? this.durChapterTime,
      wordCount: wordCount ?? this.wordCount,
      canUpdate: canUpdate ?? this.canUpdate,
      order: order ?? this.order,
      originOrder: originOrder ?? this.originOrder,
      variable: variable ?? this.variable,
      readConfig: readConfig ?? this.readConfig,
      syncTime: syncTime ?? this.syncTime,
      isInBookshelf: isInBookshelf ?? this.isInBookshelf,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookUrl.present) {
      map['bookUrl'] = Variable<String>(bookUrl.value);
    }
    if (tocUrl.present) {
      map['tocUrl'] = Variable<String>(tocUrl.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (originName.present) {
      map['originName'] = Variable<String>(originName.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (customTag.present) {
      map['customTag'] = Variable<String>(customTag.value);
    }
    if (coverUrl.present) {
      map['coverUrl'] = Variable<String>(coverUrl.value);
    }
    if (customCoverUrl.present) {
      map['customCoverUrl'] = Variable<String>(customCoverUrl.value);
    }
    if (intro.present) {
      map['intro'] = Variable<String>(intro.value);
    }
    if (customIntro.present) {
      map['customIntro'] = Variable<String>(customIntro.value);
    }
    if (charset.present) {
      map['charset'] = Variable<String>(charset.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (group.present) {
      map['group'] = Variable<int>(group.value);
    }
    if (latestChapterTitle.present) {
      map['latestChapterTitle'] = Variable<String>(latestChapterTitle.value);
    }
    if (latestChapterTime.present) {
      map['latestChapterTime'] = Variable<int>(latestChapterTime.value);
    }
    if (lastCheckTime.present) {
      map['lastCheckTime'] = Variable<int>(lastCheckTime.value);
    }
    if (lastCheckCount.present) {
      map['lastCheckCount'] = Variable<int>(lastCheckCount.value);
    }
    if (totalChapterNum.present) {
      map['totalChapterNum'] = Variable<int>(totalChapterNum.value);
    }
    if (durChapterTitle.present) {
      map['durChapterTitle'] = Variable<String>(durChapterTitle.value);
    }
    if (durChapterIndex.present) {
      map['durChapterIndex'] = Variable<int>(durChapterIndex.value);
    }
    if (durChapterPos.present) {
      map['durChapterPos'] = Variable<int>(durChapterPos.value);
    }
    if (durChapterTime.present) {
      map['durChapterTime'] = Variable<int>(durChapterTime.value);
    }
    if (wordCount.present) {
      map['wordCount'] = Variable<String>(wordCount.value);
    }
    if (canUpdate.present) {
      map['canUpdate'] = Variable<int>(canUpdate.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (originOrder.present) {
      map['originOrder'] = Variable<int>(originOrder.value);
    }
    if (variable.present) {
      map['variable'] = Variable<String>(variable.value);
    }
    if (readConfig.present) {
      map['readConfig'] = Variable<String>(readConfig.value);
    }
    if (syncTime.present) {
      map['syncTime'] = Variable<int>(syncTime.value);
    }
    if (isInBookshelf.present) {
      map['isInBookshelf'] = Variable<int>(isInBookshelf.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('bookUrl: $bookUrl, ')
          ..write('tocUrl: $tocUrl, ')
          ..write('origin: $origin, ')
          ..write('originName: $originName, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('customTag: $customTag, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('customCoverUrl: $customCoverUrl, ')
          ..write('intro: $intro, ')
          ..write('customIntro: $customIntro, ')
          ..write('charset: $charset, ')
          ..write('type: $type, ')
          ..write('group: $group, ')
          ..write('latestChapterTitle: $latestChapterTitle, ')
          ..write('latestChapterTime: $latestChapterTime, ')
          ..write('lastCheckTime: $lastCheckTime, ')
          ..write('lastCheckCount: $lastCheckCount, ')
          ..write('totalChapterNum: $totalChapterNum, ')
          ..write('durChapterTitle: $durChapterTitle, ')
          ..write('durChapterIndex: $durChapterIndex, ')
          ..write('durChapterPos: $durChapterPos, ')
          ..write('durChapterTime: $durChapterTime, ')
          ..write('wordCount: $wordCount, ')
          ..write('canUpdate: $canUpdate, ')
          ..write('order: $order, ')
          ..write('originOrder: $originOrder, ')
          ..write('variable: $variable, ')
          ..write('readConfig: $readConfig, ')
          ..write('syncTime: $syncTime, ')
          ..write('isInBookshelf: $isInBookshelf, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters
    with TableInfo<$ChaptersTable, ChapterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVolumeMeta = const VerificationMeta(
    'isVolume',
  );
  @override
  late final GeneratedColumn<int> isVolume = GeneratedColumn<int>(
    'isVolume',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'baseUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookUrlMeta = const VerificationMeta(
    'bookUrl',
  );
  @override
  late final GeneratedColumn<String> bookUrl = GeneratedColumn<String>(
    'bookUrl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indexMeta = const VerificationMeta('index');
  @override
  late final GeneratedColumn<int> index = GeneratedColumn<int>(
    'index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVipMeta = const VerificationMeta('isVip');
  @override
  late final GeneratedColumn<int> isVip = GeneratedColumn<int>(
    'isVip',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPayMeta = const VerificationMeta('isPay');
  @override
  late final GeneratedColumn<int> isPay = GeneratedColumn<int>(
    'isPay',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resourceUrlMeta = const VerificationMeta(
    'resourceUrl',
  );
  @override
  late final GeneratedColumn<String> resourceUrl = GeneratedColumn<String>(
    'resourceUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<String> wordCount = GeneratedColumn<String>(
    'wordCount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
    'start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
    'end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startFragmentIdMeta = const VerificationMeta(
    'startFragmentId',
  );
  @override
  late final GeneratedColumn<String> startFragmentId = GeneratedColumn<String>(
    'startFragmentId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endFragmentIdMeta = const VerificationMeta(
    'endFragmentId',
  );
  @override
  late final GeneratedColumn<String> endFragmentId = GeneratedColumn<String>(
    'endFragmentId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variableMeta = const VerificationMeta(
    'variable',
  );
  @override
  late final GeneratedColumn<String> variable = GeneratedColumn<String>(
    'variable',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    url,
    title,
    isVolume,
    baseUrl,
    bookUrl,
    index,
    isVip,
    isPay,
    resourceUrl,
    tag,
    wordCount,
    start,
    end,
    startFragmentId,
    endFragmentId,
    variable,
    content,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('isVolume')) {
      context.handle(
        _isVolumeMeta,
        isVolume.isAcceptableOrUnknown(data['isVolume']!, _isVolumeMeta),
      );
    }
    if (data.containsKey('baseUrl')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['baseUrl']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('bookUrl')) {
      context.handle(
        _bookUrlMeta,
        bookUrl.isAcceptableOrUnknown(data['bookUrl']!, _bookUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bookUrlMeta);
    }
    if (data.containsKey('index')) {
      context.handle(
        _indexMeta,
        index.isAcceptableOrUnknown(data['index']!, _indexMeta),
      );
    } else if (isInserting) {
      context.missing(_indexMeta);
    }
    if (data.containsKey('isVip')) {
      context.handle(
        _isVipMeta,
        isVip.isAcceptableOrUnknown(data['isVip']!, _isVipMeta),
      );
    }
    if (data.containsKey('isPay')) {
      context.handle(
        _isPayMeta,
        isPay.isAcceptableOrUnknown(data['isPay']!, _isPayMeta),
      );
    }
    if (data.containsKey('resourceUrl')) {
      context.handle(
        _resourceUrlMeta,
        resourceUrl.isAcceptableOrUnknown(
          data['resourceUrl']!,
          _resourceUrlMeta,
        ),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('wordCount')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['wordCount']!, _wordCountMeta),
      );
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    }
    if (data.containsKey('startFragmentId')) {
      context.handle(
        _startFragmentIdMeta,
        startFragmentId.isAcceptableOrUnknown(
          data['startFragmentId']!,
          _startFragmentIdMeta,
        ),
      );
    }
    if (data.containsKey('endFragmentId')) {
      context.handle(
        _endFragmentIdMeta,
        endFragmentId.isAcceptableOrUnknown(
          data['endFragmentId']!,
          _endFragmentIdMeta,
        ),
      );
    }
    if (data.containsKey('variable')) {
      context.handle(
        _variableMeta,
        variable.isAcceptableOrUnknown(data['variable']!, _variableMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  ChapterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterRow(
      url:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}url'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      isVolume:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}isVolume'],
          )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}baseUrl'],
      ),
      bookUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookUrl'],
          )!,
      index:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}index'],
          )!,
      isVip:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}isVip'],
          )!,
      isPay:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}isPay'],
          )!,
      resourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resourceUrl'],
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wordCount'],
      ),
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start'],
      ),
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end'],
      ),
      startFragmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}startFragmentId'],
      ),
      endFragmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endFragmentId'],
      ),
      variable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variable'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class ChapterRow extends DataClass implements Insertable<ChapterRow> {
  final String url;
  final String title;
  final int isVolume;
  final String? baseUrl;
  final String bookUrl;
  final int index;
  final int isVip;
  final int isPay;
  final String? resourceUrl;
  final String? tag;
  final String? wordCount;
  final int? start;
  final int? end;
  final String? startFragmentId;
  final String? endFragmentId;
  final String? variable;
  final String? content;
  const ChapterRow({
    required this.url,
    required this.title,
    required this.isVolume,
    this.baseUrl,
    required this.bookUrl,
    required this.index,
    required this.isVip,
    required this.isPay,
    this.resourceUrl,
    this.tag,
    this.wordCount,
    this.start,
    this.end,
    this.startFragmentId,
    this.endFragmentId,
    this.variable,
    this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    map['isVolume'] = Variable<int>(isVolume);
    if (!nullToAbsent || baseUrl != null) {
      map['baseUrl'] = Variable<String>(baseUrl);
    }
    map['bookUrl'] = Variable<String>(bookUrl);
    map['index'] = Variable<int>(index);
    map['isVip'] = Variable<int>(isVip);
    map['isPay'] = Variable<int>(isPay);
    if (!nullToAbsent || resourceUrl != null) {
      map['resourceUrl'] = Variable<String>(resourceUrl);
    }
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || wordCount != null) {
      map['wordCount'] = Variable<String>(wordCount);
    }
    if (!nullToAbsent || start != null) {
      map['start'] = Variable<int>(start);
    }
    if (!nullToAbsent || end != null) {
      map['end'] = Variable<int>(end);
    }
    if (!nullToAbsent || startFragmentId != null) {
      map['startFragmentId'] = Variable<String>(startFragmentId);
    }
    if (!nullToAbsent || endFragmentId != null) {
      map['endFragmentId'] = Variable<String>(endFragmentId);
    }
    if (!nullToAbsent || variable != null) {
      map['variable'] = Variable<String>(variable);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      url: Value(url),
      title: Value(title),
      isVolume: Value(isVolume),
      baseUrl:
          baseUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(baseUrl),
      bookUrl: Value(bookUrl),
      index: Value(index),
      isVip: Value(isVip),
      isPay: Value(isPay),
      resourceUrl:
          resourceUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(resourceUrl),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      wordCount:
          wordCount == null && nullToAbsent
              ? const Value.absent()
              : Value(wordCount),
      start:
          start == null && nullToAbsent ? const Value.absent() : Value(start),
      end: end == null && nullToAbsent ? const Value.absent() : Value(end),
      startFragmentId:
          startFragmentId == null && nullToAbsent
              ? const Value.absent()
              : Value(startFragmentId),
      endFragmentId:
          endFragmentId == null && nullToAbsent
              ? const Value.absent()
              : Value(endFragmentId),
      variable:
          variable == null && nullToAbsent
              ? const Value.absent()
              : Value(variable),
      content:
          content == null && nullToAbsent
              ? const Value.absent()
              : Value(content),
    );
  }

  factory ChapterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterRow(
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      isVolume: serializer.fromJson<int>(json['isVolume']),
      baseUrl: serializer.fromJson<String?>(json['baseUrl']),
      bookUrl: serializer.fromJson<String>(json['bookUrl']),
      index: serializer.fromJson<int>(json['index']),
      isVip: serializer.fromJson<int>(json['isVip']),
      isPay: serializer.fromJson<int>(json['isPay']),
      resourceUrl: serializer.fromJson<String?>(json['resourceUrl']),
      tag: serializer.fromJson<String?>(json['tag']),
      wordCount: serializer.fromJson<String?>(json['wordCount']),
      start: serializer.fromJson<int?>(json['start']),
      end: serializer.fromJson<int?>(json['end']),
      startFragmentId: serializer.fromJson<String?>(json['startFragmentId']),
      endFragmentId: serializer.fromJson<String?>(json['endFragmentId']),
      variable: serializer.fromJson<String?>(json['variable']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'isVolume': serializer.toJson<int>(isVolume),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'bookUrl': serializer.toJson<String>(bookUrl),
      'index': serializer.toJson<int>(index),
      'isVip': serializer.toJson<int>(isVip),
      'isPay': serializer.toJson<int>(isPay),
      'resourceUrl': serializer.toJson<String?>(resourceUrl),
      'tag': serializer.toJson<String?>(tag),
      'wordCount': serializer.toJson<String?>(wordCount),
      'start': serializer.toJson<int?>(start),
      'end': serializer.toJson<int?>(end),
      'startFragmentId': serializer.toJson<String?>(startFragmentId),
      'endFragmentId': serializer.toJson<String?>(endFragmentId),
      'variable': serializer.toJson<String?>(variable),
      'content': serializer.toJson<String?>(content),
    };
  }

  ChapterRow copyWith({
    String? url,
    String? title,
    int? isVolume,
    Value<String?> baseUrl = const Value.absent(),
    String? bookUrl,
    int? index,
    int? isVip,
    int? isPay,
    Value<String?> resourceUrl = const Value.absent(),
    Value<String?> tag = const Value.absent(),
    Value<String?> wordCount = const Value.absent(),
    Value<int?> start = const Value.absent(),
    Value<int?> end = const Value.absent(),
    Value<String?> startFragmentId = const Value.absent(),
    Value<String?> endFragmentId = const Value.absent(),
    Value<String?> variable = const Value.absent(),
    Value<String?> content = const Value.absent(),
  }) => ChapterRow(
    url: url ?? this.url,
    title: title ?? this.title,
    isVolume: isVolume ?? this.isVolume,
    baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
    bookUrl: bookUrl ?? this.bookUrl,
    index: index ?? this.index,
    isVip: isVip ?? this.isVip,
    isPay: isPay ?? this.isPay,
    resourceUrl: resourceUrl.present ? resourceUrl.value : this.resourceUrl,
    tag: tag.present ? tag.value : this.tag,
    wordCount: wordCount.present ? wordCount.value : this.wordCount,
    start: start.present ? start.value : this.start,
    end: end.present ? end.value : this.end,
    startFragmentId:
        startFragmentId.present ? startFragmentId.value : this.startFragmentId,
    endFragmentId:
        endFragmentId.present ? endFragmentId.value : this.endFragmentId,
    variable: variable.present ? variable.value : this.variable,
    content: content.present ? content.value : this.content,
  );
  ChapterRow copyWithCompanion(ChaptersCompanion data) {
    return ChapterRow(
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      isVolume: data.isVolume.present ? data.isVolume.value : this.isVolume,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      bookUrl: data.bookUrl.present ? data.bookUrl.value : this.bookUrl,
      index: data.index.present ? data.index.value : this.index,
      isVip: data.isVip.present ? data.isVip.value : this.isVip,
      isPay: data.isPay.present ? data.isPay.value : this.isPay,
      resourceUrl:
          data.resourceUrl.present ? data.resourceUrl.value : this.resourceUrl,
      tag: data.tag.present ? data.tag.value : this.tag,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      startFragmentId:
          data.startFragmentId.present
              ? data.startFragmentId.value
              : this.startFragmentId,
      endFragmentId:
          data.endFragmentId.present
              ? data.endFragmentId.value
              : this.endFragmentId,
      variable: data.variable.present ? data.variable.value : this.variable,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterRow(')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('isVolume: $isVolume, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('bookUrl: $bookUrl, ')
          ..write('index: $index, ')
          ..write('isVip: $isVip, ')
          ..write('isPay: $isPay, ')
          ..write('resourceUrl: $resourceUrl, ')
          ..write('tag: $tag, ')
          ..write('wordCount: $wordCount, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('startFragmentId: $startFragmentId, ')
          ..write('endFragmentId: $endFragmentId, ')
          ..write('variable: $variable, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    url,
    title,
    isVolume,
    baseUrl,
    bookUrl,
    index,
    isVip,
    isPay,
    resourceUrl,
    tag,
    wordCount,
    start,
    end,
    startFragmentId,
    endFragmentId,
    variable,
    content,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterRow &&
          other.url == this.url &&
          other.title == this.title &&
          other.isVolume == this.isVolume &&
          other.baseUrl == this.baseUrl &&
          other.bookUrl == this.bookUrl &&
          other.index == this.index &&
          other.isVip == this.isVip &&
          other.isPay == this.isPay &&
          other.resourceUrl == this.resourceUrl &&
          other.tag == this.tag &&
          other.wordCount == this.wordCount &&
          other.start == this.start &&
          other.end == this.end &&
          other.startFragmentId == this.startFragmentId &&
          other.endFragmentId == this.endFragmentId &&
          other.variable == this.variable &&
          other.content == this.content);
}

class ChaptersCompanion extends UpdateCompanion<ChapterRow> {
  final Value<String> url;
  final Value<String> title;
  final Value<int> isVolume;
  final Value<String?> baseUrl;
  final Value<String> bookUrl;
  final Value<int> index;
  final Value<int> isVip;
  final Value<int> isPay;
  final Value<String?> resourceUrl;
  final Value<String?> tag;
  final Value<String?> wordCount;
  final Value<int?> start;
  final Value<int?> end;
  final Value<String?> startFragmentId;
  final Value<String?> endFragmentId;
  final Value<String?> variable;
  final Value<String?> content;
  final Value<int> rowid;
  const ChaptersCompanion({
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.isVolume = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.bookUrl = const Value.absent(),
    this.index = const Value.absent(),
    this.isVip = const Value.absent(),
    this.isPay = const Value.absent(),
    this.resourceUrl = const Value.absent(),
    this.tag = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.startFragmentId = const Value.absent(),
    this.endFragmentId = const Value.absent(),
    this.variable = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String url,
    required String title,
    this.isVolume = const Value.absent(),
    this.baseUrl = const Value.absent(),
    required String bookUrl,
    required int index,
    this.isVip = const Value.absent(),
    this.isPay = const Value.absent(),
    this.resourceUrl = const Value.absent(),
    this.tag = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.startFragmentId = const Value.absent(),
    this.endFragmentId = const Value.absent(),
    this.variable = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       title = Value(title),
       bookUrl = Value(bookUrl),
       index = Value(index);
  static Insertable<ChapterRow> custom({
    Expression<String>? url,
    Expression<String>? title,
    Expression<int>? isVolume,
    Expression<String>? baseUrl,
    Expression<String>? bookUrl,
    Expression<int>? index,
    Expression<int>? isVip,
    Expression<int>? isPay,
    Expression<String>? resourceUrl,
    Expression<String>? tag,
    Expression<String>? wordCount,
    Expression<int>? start,
    Expression<int>? end,
    Expression<String>? startFragmentId,
    Expression<String>? endFragmentId,
    Expression<String>? variable,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (isVolume != null) 'isVolume': isVolume,
      if (baseUrl != null) 'baseUrl': baseUrl,
      if (bookUrl != null) 'bookUrl': bookUrl,
      if (index != null) 'index': index,
      if (isVip != null) 'isVip': isVip,
      if (isPay != null) 'isPay': isPay,
      if (resourceUrl != null) 'resourceUrl': resourceUrl,
      if (tag != null) 'tag': tag,
      if (wordCount != null) 'wordCount': wordCount,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (startFragmentId != null) 'startFragmentId': startFragmentId,
      if (endFragmentId != null) 'endFragmentId': endFragmentId,
      if (variable != null) 'variable': variable,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith({
    Value<String>? url,
    Value<String>? title,
    Value<int>? isVolume,
    Value<String?>? baseUrl,
    Value<String>? bookUrl,
    Value<int>? index,
    Value<int>? isVip,
    Value<int>? isPay,
    Value<String?>? resourceUrl,
    Value<String?>? tag,
    Value<String?>? wordCount,
    Value<int?>? start,
    Value<int?>? end,
    Value<String?>? startFragmentId,
    Value<String?>? endFragmentId,
    Value<String?>? variable,
    Value<String?>? content,
    Value<int>? rowid,
  }) {
    return ChaptersCompanion(
      url: url ?? this.url,
      title: title ?? this.title,
      isVolume: isVolume ?? this.isVolume,
      baseUrl: baseUrl ?? this.baseUrl,
      bookUrl: bookUrl ?? this.bookUrl,
      index: index ?? this.index,
      isVip: isVip ?? this.isVip,
      isPay: isPay ?? this.isPay,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      tag: tag ?? this.tag,
      wordCount: wordCount ?? this.wordCount,
      start: start ?? this.start,
      end: end ?? this.end,
      startFragmentId: startFragmentId ?? this.startFragmentId,
      endFragmentId: endFragmentId ?? this.endFragmentId,
      variable: variable ?? this.variable,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isVolume.present) {
      map['isVolume'] = Variable<int>(isVolume.value);
    }
    if (baseUrl.present) {
      map['baseUrl'] = Variable<String>(baseUrl.value);
    }
    if (bookUrl.present) {
      map['bookUrl'] = Variable<String>(bookUrl.value);
    }
    if (index.present) {
      map['index'] = Variable<int>(index.value);
    }
    if (isVip.present) {
      map['isVip'] = Variable<int>(isVip.value);
    }
    if (isPay.present) {
      map['isPay'] = Variable<int>(isPay.value);
    }
    if (resourceUrl.present) {
      map['resourceUrl'] = Variable<String>(resourceUrl.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (wordCount.present) {
      map['wordCount'] = Variable<String>(wordCount.value);
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (startFragmentId.present) {
      map['startFragmentId'] = Variable<String>(startFragmentId.value);
    }
    if (endFragmentId.present) {
      map['endFragmentId'] = Variable<String>(endFragmentId.value);
    }
    if (variable.present) {
      map['variable'] = Variable<String>(variable.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('isVolume: $isVolume, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('bookUrl: $bookUrl, ')
          ..write('index: $index, ')
          ..write('isVip: $isVip, ')
          ..write('isPay: $isPay, ')
          ..write('resourceUrl: $resourceUrl, ')
          ..write('tag: $tag, ')
          ..write('wordCount: $wordCount, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('startFragmentId: $startFragmentId, ')
          ..write('endFragmentId: $endFragmentId, ')
          ..write('variable: $variable, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookSourcesTable extends BookSources
    with TableInfo<$BookSourcesTable, BookSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookSourceUrlMeta = const VerificationMeta(
    'bookSourceUrl',
  );
  @override
  late final GeneratedColumn<String> bookSourceUrl = GeneratedColumn<String>(
    'bookSourceUrl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookSourceNameMeta = const VerificationMeta(
    'bookSourceName',
  );
  @override
  late final GeneratedColumn<String> bookSourceName = GeneratedColumn<String>(
    'bookSourceName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookSourceTypeMeta = const VerificationMeta(
    'bookSourceType',
  );
  @override
  late final GeneratedColumn<int> bookSourceType = GeneratedColumn<int>(
    'bookSourceType',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bookSourceGroupMeta = const VerificationMeta(
    'bookSourceGroup',
  );
  @override
  late final GeneratedColumn<String> bookSourceGroup = GeneratedColumn<String>(
    'bookSourceGroup',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookSourceCommentMeta = const VerificationMeta(
    'bookSourceComment',
  );
  @override
  late final GeneratedColumn<String> bookSourceComment =
      GeneratedColumn<String>(
        'bookSourceComment',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _loginUrlMeta = const VerificationMeta(
    'loginUrl',
  );
  @override
  late final GeneratedColumn<String> loginUrl = GeneratedColumn<String>(
    'loginUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginUiMeta = const VerificationMeta(
    'loginUi',
  );
  @override
  late final GeneratedColumn<String> loginUi = GeneratedColumn<String>(
    'loginUi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginCheckJsMeta = const VerificationMeta(
    'loginCheckJs',
  );
  @override
  late final GeneratedColumn<String> loginCheckJs = GeneratedColumn<String>(
    'loginCheckJs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverDecodeJsMeta = const VerificationMeta(
    'coverDecodeJs',
  );
  @override
  late final GeneratedColumn<String> coverDecodeJs = GeneratedColumn<String>(
    'coverDecodeJs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookUrlPatternMeta = const VerificationMeta(
    'bookUrlPattern',
  );
  @override
  late final GeneratedColumn<String> bookUrlPattern = GeneratedColumn<String>(
    'bookUrlPattern',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headerMeta = const VerificationMeta('header');
  @override
  late final GeneratedColumn<String> header = GeneratedColumn<String>(
    'header',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variableCommentMeta = const VerificationMeta(
    'variableComment',
  );
  @override
  late final GeneratedColumn<String> variableComment = GeneratedColumn<String>(
    'variableComment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customOrderMeta = const VerificationMeta(
    'customOrder',
  );
  @override
  late final GeneratedColumn<int> customOrder = GeneratedColumn<int>(
    'customOrder',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<int> weight = GeneratedColumn<int>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _enabledExploreMeta = const VerificationMeta(
    'enabledExplore',
  );
  @override
  late final GeneratedColumn<int> enabledExplore = GeneratedColumn<int>(
    'enabledExplore',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _enabledCookieJarMeta = const VerificationMeta(
    'enabledCookieJar',
  );
  @override
  late final GeneratedColumn<int> enabledCookieJar = GeneratedColumn<int>(
    'enabledCookieJar',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastUpdateTimeMeta = const VerificationMeta(
    'lastUpdateTime',
  );
  @override
  late final GeneratedColumn<int> lastUpdateTime = GeneratedColumn<int>(
    'lastUpdateTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _respondTimeMeta = const VerificationMeta(
    'respondTime',
  );
  @override
  late final GeneratedColumn<int> respondTime = GeneratedColumn<int>(
    'respondTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(180000),
  );
  static const VerificationMeta _jsLibMeta = const VerificationMeta('jsLib');
  @override
  late final GeneratedColumn<String> jsLib = GeneratedColumn<String>(
    'jsLib',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _concurrentRateMeta = const VerificationMeta(
    'concurrentRate',
  );
  @override
  late final GeneratedColumn<String> concurrentRate = GeneratedColumn<String>(
    'concurrentRate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exploreUrlMeta = const VerificationMeta(
    'exploreUrl',
  );
  @override
  late final GeneratedColumn<String> exploreUrl = GeneratedColumn<String>(
    'exploreUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exploreScreenMeta = const VerificationMeta(
    'exploreScreen',
  );
  @override
  late final GeneratedColumn<String> exploreScreen = GeneratedColumn<String>(
    'exploreScreen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchUrlMeta = const VerificationMeta(
    'searchUrl',
  );
  @override
  late final GeneratedColumn<String> searchUrl = GeneratedColumn<String>(
    'searchUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleSearchMeta = const VerificationMeta(
    'ruleSearch',
  );
  @override
  late final GeneratedColumn<String> ruleSearch = GeneratedColumn<String>(
    'ruleSearch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleExploreMeta = const VerificationMeta(
    'ruleExplore',
  );
  @override
  late final GeneratedColumn<String> ruleExplore = GeneratedColumn<String>(
    'ruleExplore',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleBookInfoMeta = const VerificationMeta(
    'ruleBookInfo',
  );
  @override
  late final GeneratedColumn<String> ruleBookInfo = GeneratedColumn<String>(
    'ruleBookInfo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleTocMeta = const VerificationMeta(
    'ruleToc',
  );
  @override
  late final GeneratedColumn<String> ruleToc = GeneratedColumn<String>(
    'ruleToc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleContentMeta = const VerificationMeta(
    'ruleContent',
  );
  @override
  late final GeneratedColumn<String> ruleContent = GeneratedColumn<String>(
    'ruleContent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleReviewMeta = const VerificationMeta(
    'ruleReview',
  );
  @override
  late final GeneratedColumn<String> ruleReview = GeneratedColumn<String>(
    'ruleReview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookSourceUrl,
    bookSourceName,
    bookSourceType,
    bookSourceGroup,
    bookSourceComment,
    loginUrl,
    loginUi,
    loginCheckJs,
    coverDecodeJs,
    bookUrlPattern,
    header,
    variableComment,
    customOrder,
    weight,
    enabled,
    enabledExplore,
    enabledCookieJar,
    lastUpdateTime,
    respondTime,
    jsLib,
    concurrentRate,
    exploreUrl,
    exploreScreen,
    searchUrl,
    ruleSearch,
    ruleExplore,
    ruleBookInfo,
    ruleToc,
    ruleContent,
    ruleReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookSourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bookSourceUrl')) {
      context.handle(
        _bookSourceUrlMeta,
        bookSourceUrl.isAcceptableOrUnknown(
          data['bookSourceUrl']!,
          _bookSourceUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookSourceUrlMeta);
    }
    if (data.containsKey('bookSourceName')) {
      context.handle(
        _bookSourceNameMeta,
        bookSourceName.isAcceptableOrUnknown(
          data['bookSourceName']!,
          _bookSourceNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookSourceNameMeta);
    }
    if (data.containsKey('bookSourceType')) {
      context.handle(
        _bookSourceTypeMeta,
        bookSourceType.isAcceptableOrUnknown(
          data['bookSourceType']!,
          _bookSourceTypeMeta,
        ),
      );
    }
    if (data.containsKey('bookSourceGroup')) {
      context.handle(
        _bookSourceGroupMeta,
        bookSourceGroup.isAcceptableOrUnknown(
          data['bookSourceGroup']!,
          _bookSourceGroupMeta,
        ),
      );
    }
    if (data.containsKey('bookSourceComment')) {
      context.handle(
        _bookSourceCommentMeta,
        bookSourceComment.isAcceptableOrUnknown(
          data['bookSourceComment']!,
          _bookSourceCommentMeta,
        ),
      );
    }
    if (data.containsKey('loginUrl')) {
      context.handle(
        _loginUrlMeta,
        loginUrl.isAcceptableOrUnknown(data['loginUrl']!, _loginUrlMeta),
      );
    }
    if (data.containsKey('loginUi')) {
      context.handle(
        _loginUiMeta,
        loginUi.isAcceptableOrUnknown(data['loginUi']!, _loginUiMeta),
      );
    }
    if (data.containsKey('loginCheckJs')) {
      context.handle(
        _loginCheckJsMeta,
        loginCheckJs.isAcceptableOrUnknown(
          data['loginCheckJs']!,
          _loginCheckJsMeta,
        ),
      );
    }
    if (data.containsKey('coverDecodeJs')) {
      context.handle(
        _coverDecodeJsMeta,
        coverDecodeJs.isAcceptableOrUnknown(
          data['coverDecodeJs']!,
          _coverDecodeJsMeta,
        ),
      );
    }
    if (data.containsKey('bookUrlPattern')) {
      context.handle(
        _bookUrlPatternMeta,
        bookUrlPattern.isAcceptableOrUnknown(
          data['bookUrlPattern']!,
          _bookUrlPatternMeta,
        ),
      );
    }
    if (data.containsKey('header')) {
      context.handle(
        _headerMeta,
        header.isAcceptableOrUnknown(data['header']!, _headerMeta),
      );
    }
    if (data.containsKey('variableComment')) {
      context.handle(
        _variableCommentMeta,
        variableComment.isAcceptableOrUnknown(
          data['variableComment']!,
          _variableCommentMeta,
        ),
      );
    }
    if (data.containsKey('customOrder')) {
      context.handle(
        _customOrderMeta,
        customOrder.isAcceptableOrUnknown(
          data['customOrder']!,
          _customOrderMeta,
        ),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('enabledExplore')) {
      context.handle(
        _enabledExploreMeta,
        enabledExplore.isAcceptableOrUnknown(
          data['enabledExplore']!,
          _enabledExploreMeta,
        ),
      );
    }
    if (data.containsKey('enabledCookieJar')) {
      context.handle(
        _enabledCookieJarMeta,
        enabledCookieJar.isAcceptableOrUnknown(
          data['enabledCookieJar']!,
          _enabledCookieJarMeta,
        ),
      );
    }
    if (data.containsKey('lastUpdateTime')) {
      context.handle(
        _lastUpdateTimeMeta,
        lastUpdateTime.isAcceptableOrUnknown(
          data['lastUpdateTime']!,
          _lastUpdateTimeMeta,
        ),
      );
    }
    if (data.containsKey('respondTime')) {
      context.handle(
        _respondTimeMeta,
        respondTime.isAcceptableOrUnknown(
          data['respondTime']!,
          _respondTimeMeta,
        ),
      );
    }
    if (data.containsKey('jsLib')) {
      context.handle(
        _jsLibMeta,
        jsLib.isAcceptableOrUnknown(data['jsLib']!, _jsLibMeta),
      );
    }
    if (data.containsKey('concurrentRate')) {
      context.handle(
        _concurrentRateMeta,
        concurrentRate.isAcceptableOrUnknown(
          data['concurrentRate']!,
          _concurrentRateMeta,
        ),
      );
    }
    if (data.containsKey('exploreUrl')) {
      context.handle(
        _exploreUrlMeta,
        exploreUrl.isAcceptableOrUnknown(data['exploreUrl']!, _exploreUrlMeta),
      );
    }
    if (data.containsKey('exploreScreen')) {
      context.handle(
        _exploreScreenMeta,
        exploreScreen.isAcceptableOrUnknown(
          data['exploreScreen']!,
          _exploreScreenMeta,
        ),
      );
    }
    if (data.containsKey('searchUrl')) {
      context.handle(
        _searchUrlMeta,
        searchUrl.isAcceptableOrUnknown(data['searchUrl']!, _searchUrlMeta),
      );
    }
    if (data.containsKey('ruleSearch')) {
      context.handle(
        _ruleSearchMeta,
        ruleSearch.isAcceptableOrUnknown(data['ruleSearch']!, _ruleSearchMeta),
      );
    }
    if (data.containsKey('ruleExplore')) {
      context.handle(
        _ruleExploreMeta,
        ruleExplore.isAcceptableOrUnknown(
          data['ruleExplore']!,
          _ruleExploreMeta,
        ),
      );
    }
    if (data.containsKey('ruleBookInfo')) {
      context.handle(
        _ruleBookInfoMeta,
        ruleBookInfo.isAcceptableOrUnknown(
          data['ruleBookInfo']!,
          _ruleBookInfoMeta,
        ),
      );
    }
    if (data.containsKey('ruleToc')) {
      context.handle(
        _ruleTocMeta,
        ruleToc.isAcceptableOrUnknown(data['ruleToc']!, _ruleTocMeta),
      );
    }
    if (data.containsKey('ruleContent')) {
      context.handle(
        _ruleContentMeta,
        ruleContent.isAcceptableOrUnknown(
          data['ruleContent']!,
          _ruleContentMeta,
        ),
      );
    }
    if (data.containsKey('ruleReview')) {
      context.handle(
        _ruleReviewMeta,
        ruleReview.isAcceptableOrUnknown(data['ruleReview']!, _ruleReviewMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookSourceUrl};
  @override
  BookSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookSourceRow(
      bookSourceUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookSourceUrl'],
          )!,
      bookSourceName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookSourceName'],
          )!,
      bookSourceType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}bookSourceType'],
          )!,
      bookSourceGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bookSourceGroup'],
      ),
      bookSourceComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bookSourceComment'],
      ),
      loginUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginUrl'],
      ),
      loginUi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginUi'],
      ),
      loginCheckJs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginCheckJs'],
      ),
      coverDecodeJs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverDecodeJs'],
      ),
      bookUrlPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bookUrlPattern'],
      ),
      header: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header'],
      ),
      variableComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variableComment'],
      ),
      customOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}customOrder'],
          )!,
      weight:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}weight'],
          )!,
      enabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabled'],
          )!,
      enabledExplore:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabledExplore'],
          )!,
      enabledCookieJar:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabledCookieJar'],
          )!,
      lastUpdateTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}lastUpdateTime'],
          )!,
      respondTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}respondTime'],
          )!,
      jsLib: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jsLib'],
      ),
      concurrentRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concurrentRate'],
      ),
      exploreUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exploreUrl'],
      ),
      exploreScreen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exploreScreen'],
      ),
      searchUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}searchUrl'],
      ),
      ruleSearch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleSearch'],
      ),
      ruleExplore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleExplore'],
      ),
      ruleBookInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleBookInfo'],
      ),
      ruleToc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleToc'],
      ),
      ruleContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleContent'],
      ),
      ruleReview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleReview'],
      ),
    );
  }

  @override
  $BookSourcesTable createAlias(String alias) {
    return $BookSourcesTable(attachedDatabase, alias);
  }
}

class BookSourceRow extends DataClass implements Insertable<BookSourceRow> {
  final String bookSourceUrl;
  final String bookSourceName;
  final int bookSourceType;
  final String? bookSourceGroup;
  final String? bookSourceComment;
  final String? loginUrl;
  final String? loginUi;
  final String? loginCheckJs;
  final String? coverDecodeJs;
  final String? bookUrlPattern;
  final String? header;
  final String? variableComment;
  final int customOrder;
  final int weight;
  final int enabled;
  final int enabledExplore;
  final int enabledCookieJar;
  final int lastUpdateTime;
  final int respondTime;
  final String? jsLib;
  final String? concurrentRate;
  final String? exploreUrl;
  final String? exploreScreen;
  final String? searchUrl;
  final String? ruleSearch;
  final String? ruleExplore;
  final String? ruleBookInfo;
  final String? ruleToc;
  final String? ruleContent;
  final String? ruleReview;
  const BookSourceRow({
    required this.bookSourceUrl,
    required this.bookSourceName,
    required this.bookSourceType,
    this.bookSourceGroup,
    this.bookSourceComment,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.bookUrlPattern,
    this.header,
    this.variableComment,
    required this.customOrder,
    required this.weight,
    required this.enabled,
    required this.enabledExplore,
    required this.enabledCookieJar,
    required this.lastUpdateTime,
    required this.respondTime,
    this.jsLib,
    this.concurrentRate,
    this.exploreUrl,
    this.exploreScreen,
    this.searchUrl,
    this.ruleSearch,
    this.ruleExplore,
    this.ruleBookInfo,
    this.ruleToc,
    this.ruleContent,
    this.ruleReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bookSourceUrl'] = Variable<String>(bookSourceUrl);
    map['bookSourceName'] = Variable<String>(bookSourceName);
    map['bookSourceType'] = Variable<int>(bookSourceType);
    if (!nullToAbsent || bookSourceGroup != null) {
      map['bookSourceGroup'] = Variable<String>(bookSourceGroup);
    }
    if (!nullToAbsent || bookSourceComment != null) {
      map['bookSourceComment'] = Variable<String>(bookSourceComment);
    }
    if (!nullToAbsent || loginUrl != null) {
      map['loginUrl'] = Variable<String>(loginUrl);
    }
    if (!nullToAbsent || loginUi != null) {
      map['loginUi'] = Variable<String>(loginUi);
    }
    if (!nullToAbsent || loginCheckJs != null) {
      map['loginCheckJs'] = Variable<String>(loginCheckJs);
    }
    if (!nullToAbsent || coverDecodeJs != null) {
      map['coverDecodeJs'] = Variable<String>(coverDecodeJs);
    }
    if (!nullToAbsent || bookUrlPattern != null) {
      map['bookUrlPattern'] = Variable<String>(bookUrlPattern);
    }
    if (!nullToAbsent || header != null) {
      map['header'] = Variable<String>(header);
    }
    if (!nullToAbsent || variableComment != null) {
      map['variableComment'] = Variable<String>(variableComment);
    }
    map['customOrder'] = Variable<int>(customOrder);
    map['weight'] = Variable<int>(weight);
    map['enabled'] = Variable<int>(enabled);
    map['enabledExplore'] = Variable<int>(enabledExplore);
    map['enabledCookieJar'] = Variable<int>(enabledCookieJar);
    map['lastUpdateTime'] = Variable<int>(lastUpdateTime);
    map['respondTime'] = Variable<int>(respondTime);
    if (!nullToAbsent || jsLib != null) {
      map['jsLib'] = Variable<String>(jsLib);
    }
    if (!nullToAbsent || concurrentRate != null) {
      map['concurrentRate'] = Variable<String>(concurrentRate);
    }
    if (!nullToAbsent || exploreUrl != null) {
      map['exploreUrl'] = Variable<String>(exploreUrl);
    }
    if (!nullToAbsent || exploreScreen != null) {
      map['exploreScreen'] = Variable<String>(exploreScreen);
    }
    if (!nullToAbsent || searchUrl != null) {
      map['searchUrl'] = Variable<String>(searchUrl);
    }
    if (!nullToAbsent || ruleSearch != null) {
      map['ruleSearch'] = Variable<String>(ruleSearch);
    }
    if (!nullToAbsent || ruleExplore != null) {
      map['ruleExplore'] = Variable<String>(ruleExplore);
    }
    if (!nullToAbsent || ruleBookInfo != null) {
      map['ruleBookInfo'] = Variable<String>(ruleBookInfo);
    }
    if (!nullToAbsent || ruleToc != null) {
      map['ruleToc'] = Variable<String>(ruleToc);
    }
    if (!nullToAbsent || ruleContent != null) {
      map['ruleContent'] = Variable<String>(ruleContent);
    }
    if (!nullToAbsent || ruleReview != null) {
      map['ruleReview'] = Variable<String>(ruleReview);
    }
    return map;
  }

  BookSourcesCompanion toCompanion(bool nullToAbsent) {
    return BookSourcesCompanion(
      bookSourceUrl: Value(bookSourceUrl),
      bookSourceName: Value(bookSourceName),
      bookSourceType: Value(bookSourceType),
      bookSourceGroup:
          bookSourceGroup == null && nullToAbsent
              ? const Value.absent()
              : Value(bookSourceGroup),
      bookSourceComment:
          bookSourceComment == null && nullToAbsent
              ? const Value.absent()
              : Value(bookSourceComment),
      loginUrl:
          loginUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(loginUrl),
      loginUi:
          loginUi == null && nullToAbsent
              ? const Value.absent()
              : Value(loginUi),
      loginCheckJs:
          loginCheckJs == null && nullToAbsent
              ? const Value.absent()
              : Value(loginCheckJs),
      coverDecodeJs:
          coverDecodeJs == null && nullToAbsent
              ? const Value.absent()
              : Value(coverDecodeJs),
      bookUrlPattern:
          bookUrlPattern == null && nullToAbsent
              ? const Value.absent()
              : Value(bookUrlPattern),
      header:
          header == null && nullToAbsent ? const Value.absent() : Value(header),
      variableComment:
          variableComment == null && nullToAbsent
              ? const Value.absent()
              : Value(variableComment),
      customOrder: Value(customOrder),
      weight: Value(weight),
      enabled: Value(enabled),
      enabledExplore: Value(enabledExplore),
      enabledCookieJar: Value(enabledCookieJar),
      lastUpdateTime: Value(lastUpdateTime),
      respondTime: Value(respondTime),
      jsLib:
          jsLib == null && nullToAbsent ? const Value.absent() : Value(jsLib),
      concurrentRate:
          concurrentRate == null && nullToAbsent
              ? const Value.absent()
              : Value(concurrentRate),
      exploreUrl:
          exploreUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(exploreUrl),
      exploreScreen:
          exploreScreen == null && nullToAbsent
              ? const Value.absent()
              : Value(exploreScreen),
      searchUrl:
          searchUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(searchUrl),
      ruleSearch:
          ruleSearch == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleSearch),
      ruleExplore:
          ruleExplore == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleExplore),
      ruleBookInfo:
          ruleBookInfo == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleBookInfo),
      ruleToc:
          ruleToc == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleToc),
      ruleContent:
          ruleContent == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleContent),
      ruleReview:
          ruleReview == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleReview),
    );
  }

  factory BookSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookSourceRow(
      bookSourceUrl: serializer.fromJson<String>(json['bookSourceUrl']),
      bookSourceName: serializer.fromJson<String>(json['bookSourceName']),
      bookSourceType: serializer.fromJson<int>(json['bookSourceType']),
      bookSourceGroup: serializer.fromJson<String?>(json['bookSourceGroup']),
      bookSourceComment: serializer.fromJson<String?>(
        json['bookSourceComment'],
      ),
      loginUrl: serializer.fromJson<String?>(json['loginUrl']),
      loginUi: serializer.fromJson<String?>(json['loginUi']),
      loginCheckJs: serializer.fromJson<String?>(json['loginCheckJs']),
      coverDecodeJs: serializer.fromJson<String?>(json['coverDecodeJs']),
      bookUrlPattern: serializer.fromJson<String?>(json['bookUrlPattern']),
      header: serializer.fromJson<String?>(json['header']),
      variableComment: serializer.fromJson<String?>(json['variableComment']),
      customOrder: serializer.fromJson<int>(json['customOrder']),
      weight: serializer.fromJson<int>(json['weight']),
      enabled: serializer.fromJson<int>(json['enabled']),
      enabledExplore: serializer.fromJson<int>(json['enabledExplore']),
      enabledCookieJar: serializer.fromJson<int>(json['enabledCookieJar']),
      lastUpdateTime: serializer.fromJson<int>(json['lastUpdateTime']),
      respondTime: serializer.fromJson<int>(json['respondTime']),
      jsLib: serializer.fromJson<String?>(json['jsLib']),
      concurrentRate: serializer.fromJson<String?>(json['concurrentRate']),
      exploreUrl: serializer.fromJson<String?>(json['exploreUrl']),
      exploreScreen: serializer.fromJson<String?>(json['exploreScreen']),
      searchUrl: serializer.fromJson<String?>(json['searchUrl']),
      ruleSearch: serializer.fromJson<String?>(json['ruleSearch']),
      ruleExplore: serializer.fromJson<String?>(json['ruleExplore']),
      ruleBookInfo: serializer.fromJson<String?>(json['ruleBookInfo']),
      ruleToc: serializer.fromJson<String?>(json['ruleToc']),
      ruleContent: serializer.fromJson<String?>(json['ruleContent']),
      ruleReview: serializer.fromJson<String?>(json['ruleReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookSourceUrl': serializer.toJson<String>(bookSourceUrl),
      'bookSourceName': serializer.toJson<String>(bookSourceName),
      'bookSourceType': serializer.toJson<int>(bookSourceType),
      'bookSourceGroup': serializer.toJson<String?>(bookSourceGroup),
      'bookSourceComment': serializer.toJson<String?>(bookSourceComment),
      'loginUrl': serializer.toJson<String?>(loginUrl),
      'loginUi': serializer.toJson<String?>(loginUi),
      'loginCheckJs': serializer.toJson<String?>(loginCheckJs),
      'coverDecodeJs': serializer.toJson<String?>(coverDecodeJs),
      'bookUrlPattern': serializer.toJson<String?>(bookUrlPattern),
      'header': serializer.toJson<String?>(header),
      'variableComment': serializer.toJson<String?>(variableComment),
      'customOrder': serializer.toJson<int>(customOrder),
      'weight': serializer.toJson<int>(weight),
      'enabled': serializer.toJson<int>(enabled),
      'enabledExplore': serializer.toJson<int>(enabledExplore),
      'enabledCookieJar': serializer.toJson<int>(enabledCookieJar),
      'lastUpdateTime': serializer.toJson<int>(lastUpdateTime),
      'respondTime': serializer.toJson<int>(respondTime),
      'jsLib': serializer.toJson<String?>(jsLib),
      'concurrentRate': serializer.toJson<String?>(concurrentRate),
      'exploreUrl': serializer.toJson<String?>(exploreUrl),
      'exploreScreen': serializer.toJson<String?>(exploreScreen),
      'searchUrl': serializer.toJson<String?>(searchUrl),
      'ruleSearch': serializer.toJson<String?>(ruleSearch),
      'ruleExplore': serializer.toJson<String?>(ruleExplore),
      'ruleBookInfo': serializer.toJson<String?>(ruleBookInfo),
      'ruleToc': serializer.toJson<String?>(ruleToc),
      'ruleContent': serializer.toJson<String?>(ruleContent),
      'ruleReview': serializer.toJson<String?>(ruleReview),
    };
  }

  BookSourceRow copyWith({
    String? bookSourceUrl,
    String? bookSourceName,
    int? bookSourceType,
    Value<String?> bookSourceGroup = const Value.absent(),
    Value<String?> bookSourceComment = const Value.absent(),
    Value<String?> loginUrl = const Value.absent(),
    Value<String?> loginUi = const Value.absent(),
    Value<String?> loginCheckJs = const Value.absent(),
    Value<String?> coverDecodeJs = const Value.absent(),
    Value<String?> bookUrlPattern = const Value.absent(),
    Value<String?> header = const Value.absent(),
    Value<String?> variableComment = const Value.absent(),
    int? customOrder,
    int? weight,
    int? enabled,
    int? enabledExplore,
    int? enabledCookieJar,
    int? lastUpdateTime,
    int? respondTime,
    Value<String?> jsLib = const Value.absent(),
    Value<String?> concurrentRate = const Value.absent(),
    Value<String?> exploreUrl = const Value.absent(),
    Value<String?> exploreScreen = const Value.absent(),
    Value<String?> searchUrl = const Value.absent(),
    Value<String?> ruleSearch = const Value.absent(),
    Value<String?> ruleExplore = const Value.absent(),
    Value<String?> ruleBookInfo = const Value.absent(),
    Value<String?> ruleToc = const Value.absent(),
    Value<String?> ruleContent = const Value.absent(),
    Value<String?> ruleReview = const Value.absent(),
  }) => BookSourceRow(
    bookSourceUrl: bookSourceUrl ?? this.bookSourceUrl,
    bookSourceName: bookSourceName ?? this.bookSourceName,
    bookSourceType: bookSourceType ?? this.bookSourceType,
    bookSourceGroup:
        bookSourceGroup.present ? bookSourceGroup.value : this.bookSourceGroup,
    bookSourceComment:
        bookSourceComment.present
            ? bookSourceComment.value
            : this.bookSourceComment,
    loginUrl: loginUrl.present ? loginUrl.value : this.loginUrl,
    loginUi: loginUi.present ? loginUi.value : this.loginUi,
    loginCheckJs: loginCheckJs.present ? loginCheckJs.value : this.loginCheckJs,
    coverDecodeJs:
        coverDecodeJs.present ? coverDecodeJs.value : this.coverDecodeJs,
    bookUrlPattern:
        bookUrlPattern.present ? bookUrlPattern.value : this.bookUrlPattern,
    header: header.present ? header.value : this.header,
    variableComment:
        variableComment.present ? variableComment.value : this.variableComment,
    customOrder: customOrder ?? this.customOrder,
    weight: weight ?? this.weight,
    enabled: enabled ?? this.enabled,
    enabledExplore: enabledExplore ?? this.enabledExplore,
    enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
    lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    respondTime: respondTime ?? this.respondTime,
    jsLib: jsLib.present ? jsLib.value : this.jsLib,
    concurrentRate:
        concurrentRate.present ? concurrentRate.value : this.concurrentRate,
    exploreUrl: exploreUrl.present ? exploreUrl.value : this.exploreUrl,
    exploreScreen:
        exploreScreen.present ? exploreScreen.value : this.exploreScreen,
    searchUrl: searchUrl.present ? searchUrl.value : this.searchUrl,
    ruleSearch: ruleSearch.present ? ruleSearch.value : this.ruleSearch,
    ruleExplore: ruleExplore.present ? ruleExplore.value : this.ruleExplore,
    ruleBookInfo: ruleBookInfo.present ? ruleBookInfo.value : this.ruleBookInfo,
    ruleToc: ruleToc.present ? ruleToc.value : this.ruleToc,
    ruleContent: ruleContent.present ? ruleContent.value : this.ruleContent,
    ruleReview: ruleReview.present ? ruleReview.value : this.ruleReview,
  );
  BookSourceRow copyWithCompanion(BookSourcesCompanion data) {
    return BookSourceRow(
      bookSourceUrl:
          data.bookSourceUrl.present
              ? data.bookSourceUrl.value
              : this.bookSourceUrl,
      bookSourceName:
          data.bookSourceName.present
              ? data.bookSourceName.value
              : this.bookSourceName,
      bookSourceType:
          data.bookSourceType.present
              ? data.bookSourceType.value
              : this.bookSourceType,
      bookSourceGroup:
          data.bookSourceGroup.present
              ? data.bookSourceGroup.value
              : this.bookSourceGroup,
      bookSourceComment:
          data.bookSourceComment.present
              ? data.bookSourceComment.value
              : this.bookSourceComment,
      loginUrl: data.loginUrl.present ? data.loginUrl.value : this.loginUrl,
      loginUi: data.loginUi.present ? data.loginUi.value : this.loginUi,
      loginCheckJs:
          data.loginCheckJs.present
              ? data.loginCheckJs.value
              : this.loginCheckJs,
      coverDecodeJs:
          data.coverDecodeJs.present
              ? data.coverDecodeJs.value
              : this.coverDecodeJs,
      bookUrlPattern:
          data.bookUrlPattern.present
              ? data.bookUrlPattern.value
              : this.bookUrlPattern,
      header: data.header.present ? data.header.value : this.header,
      variableComment:
          data.variableComment.present
              ? data.variableComment.value
              : this.variableComment,
      customOrder:
          data.customOrder.present ? data.customOrder.value : this.customOrder,
      weight: data.weight.present ? data.weight.value : this.weight,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      enabledExplore:
          data.enabledExplore.present
              ? data.enabledExplore.value
              : this.enabledExplore,
      enabledCookieJar:
          data.enabledCookieJar.present
              ? data.enabledCookieJar.value
              : this.enabledCookieJar,
      lastUpdateTime:
          data.lastUpdateTime.present
              ? data.lastUpdateTime.value
              : this.lastUpdateTime,
      respondTime:
          data.respondTime.present ? data.respondTime.value : this.respondTime,
      jsLib: data.jsLib.present ? data.jsLib.value : this.jsLib,
      concurrentRate:
          data.concurrentRate.present
              ? data.concurrentRate.value
              : this.concurrentRate,
      exploreUrl:
          data.exploreUrl.present ? data.exploreUrl.value : this.exploreUrl,
      exploreScreen:
          data.exploreScreen.present
              ? data.exploreScreen.value
              : this.exploreScreen,
      searchUrl: data.searchUrl.present ? data.searchUrl.value : this.searchUrl,
      ruleSearch:
          data.ruleSearch.present ? data.ruleSearch.value : this.ruleSearch,
      ruleExplore:
          data.ruleExplore.present ? data.ruleExplore.value : this.ruleExplore,
      ruleBookInfo:
          data.ruleBookInfo.present
              ? data.ruleBookInfo.value
              : this.ruleBookInfo,
      ruleToc: data.ruleToc.present ? data.ruleToc.value : this.ruleToc,
      ruleContent:
          data.ruleContent.present ? data.ruleContent.value : this.ruleContent,
      ruleReview:
          data.ruleReview.present ? data.ruleReview.value : this.ruleReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookSourceRow(')
          ..write('bookSourceUrl: $bookSourceUrl, ')
          ..write('bookSourceName: $bookSourceName, ')
          ..write('bookSourceType: $bookSourceType, ')
          ..write('bookSourceGroup: $bookSourceGroup, ')
          ..write('bookSourceComment: $bookSourceComment, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('loginUi: $loginUi, ')
          ..write('loginCheckJs: $loginCheckJs, ')
          ..write('coverDecodeJs: $coverDecodeJs, ')
          ..write('bookUrlPattern: $bookUrlPattern, ')
          ..write('header: $header, ')
          ..write('variableComment: $variableComment, ')
          ..write('customOrder: $customOrder, ')
          ..write('weight: $weight, ')
          ..write('enabled: $enabled, ')
          ..write('enabledExplore: $enabledExplore, ')
          ..write('enabledCookieJar: $enabledCookieJar, ')
          ..write('lastUpdateTime: $lastUpdateTime, ')
          ..write('respondTime: $respondTime, ')
          ..write('jsLib: $jsLib, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('exploreUrl: $exploreUrl, ')
          ..write('exploreScreen: $exploreScreen, ')
          ..write('searchUrl: $searchUrl, ')
          ..write('ruleSearch: $ruleSearch, ')
          ..write('ruleExplore: $ruleExplore, ')
          ..write('ruleBookInfo: $ruleBookInfo, ')
          ..write('ruleToc: $ruleToc, ')
          ..write('ruleContent: $ruleContent, ')
          ..write('ruleReview: $ruleReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    bookSourceUrl,
    bookSourceName,
    bookSourceType,
    bookSourceGroup,
    bookSourceComment,
    loginUrl,
    loginUi,
    loginCheckJs,
    coverDecodeJs,
    bookUrlPattern,
    header,
    variableComment,
    customOrder,
    weight,
    enabled,
    enabledExplore,
    enabledCookieJar,
    lastUpdateTime,
    respondTime,
    jsLib,
    concurrentRate,
    exploreUrl,
    exploreScreen,
    searchUrl,
    ruleSearch,
    ruleExplore,
    ruleBookInfo,
    ruleToc,
    ruleContent,
    ruleReview,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookSourceRow &&
          other.bookSourceUrl == this.bookSourceUrl &&
          other.bookSourceName == this.bookSourceName &&
          other.bookSourceType == this.bookSourceType &&
          other.bookSourceGroup == this.bookSourceGroup &&
          other.bookSourceComment == this.bookSourceComment &&
          other.loginUrl == this.loginUrl &&
          other.loginUi == this.loginUi &&
          other.loginCheckJs == this.loginCheckJs &&
          other.coverDecodeJs == this.coverDecodeJs &&
          other.bookUrlPattern == this.bookUrlPattern &&
          other.header == this.header &&
          other.variableComment == this.variableComment &&
          other.customOrder == this.customOrder &&
          other.weight == this.weight &&
          other.enabled == this.enabled &&
          other.enabledExplore == this.enabledExplore &&
          other.enabledCookieJar == this.enabledCookieJar &&
          other.lastUpdateTime == this.lastUpdateTime &&
          other.respondTime == this.respondTime &&
          other.jsLib == this.jsLib &&
          other.concurrentRate == this.concurrentRate &&
          other.exploreUrl == this.exploreUrl &&
          other.exploreScreen == this.exploreScreen &&
          other.searchUrl == this.searchUrl &&
          other.ruleSearch == this.ruleSearch &&
          other.ruleExplore == this.ruleExplore &&
          other.ruleBookInfo == this.ruleBookInfo &&
          other.ruleToc == this.ruleToc &&
          other.ruleContent == this.ruleContent &&
          other.ruleReview == this.ruleReview);
}

class BookSourcesCompanion extends UpdateCompanion<BookSourceRow> {
  final Value<String> bookSourceUrl;
  final Value<String> bookSourceName;
  final Value<int> bookSourceType;
  final Value<String?> bookSourceGroup;
  final Value<String?> bookSourceComment;
  final Value<String?> loginUrl;
  final Value<String?> loginUi;
  final Value<String?> loginCheckJs;
  final Value<String?> coverDecodeJs;
  final Value<String?> bookUrlPattern;
  final Value<String?> header;
  final Value<String?> variableComment;
  final Value<int> customOrder;
  final Value<int> weight;
  final Value<int> enabled;
  final Value<int> enabledExplore;
  final Value<int> enabledCookieJar;
  final Value<int> lastUpdateTime;
  final Value<int> respondTime;
  final Value<String?> jsLib;
  final Value<String?> concurrentRate;
  final Value<String?> exploreUrl;
  final Value<String?> exploreScreen;
  final Value<String?> searchUrl;
  final Value<String?> ruleSearch;
  final Value<String?> ruleExplore;
  final Value<String?> ruleBookInfo;
  final Value<String?> ruleToc;
  final Value<String?> ruleContent;
  final Value<String?> ruleReview;
  final Value<int> rowid;
  const BookSourcesCompanion({
    this.bookSourceUrl = const Value.absent(),
    this.bookSourceName = const Value.absent(),
    this.bookSourceType = const Value.absent(),
    this.bookSourceGroup = const Value.absent(),
    this.bookSourceComment = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.loginUi = const Value.absent(),
    this.loginCheckJs = const Value.absent(),
    this.coverDecodeJs = const Value.absent(),
    this.bookUrlPattern = const Value.absent(),
    this.header = const Value.absent(),
    this.variableComment = const Value.absent(),
    this.customOrder = const Value.absent(),
    this.weight = const Value.absent(),
    this.enabled = const Value.absent(),
    this.enabledExplore = const Value.absent(),
    this.enabledCookieJar = const Value.absent(),
    this.lastUpdateTime = const Value.absent(),
    this.respondTime = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.exploreUrl = const Value.absent(),
    this.exploreScreen = const Value.absent(),
    this.searchUrl = const Value.absent(),
    this.ruleSearch = const Value.absent(),
    this.ruleExplore = const Value.absent(),
    this.ruleBookInfo = const Value.absent(),
    this.ruleToc = const Value.absent(),
    this.ruleContent = const Value.absent(),
    this.ruleReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookSourcesCompanion.insert({
    required String bookSourceUrl,
    required String bookSourceName,
    this.bookSourceType = const Value.absent(),
    this.bookSourceGroup = const Value.absent(),
    this.bookSourceComment = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.loginUi = const Value.absent(),
    this.loginCheckJs = const Value.absent(),
    this.coverDecodeJs = const Value.absent(),
    this.bookUrlPattern = const Value.absent(),
    this.header = const Value.absent(),
    this.variableComment = const Value.absent(),
    this.customOrder = const Value.absent(),
    this.weight = const Value.absent(),
    this.enabled = const Value.absent(),
    this.enabledExplore = const Value.absent(),
    this.enabledCookieJar = const Value.absent(),
    this.lastUpdateTime = const Value.absent(),
    this.respondTime = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.exploreUrl = const Value.absent(),
    this.exploreScreen = const Value.absent(),
    this.searchUrl = const Value.absent(),
    this.ruleSearch = const Value.absent(),
    this.ruleExplore = const Value.absent(),
    this.ruleBookInfo = const Value.absent(),
    this.ruleToc = const Value.absent(),
    this.ruleContent = const Value.absent(),
    this.ruleReview = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookSourceUrl = Value(bookSourceUrl),
       bookSourceName = Value(bookSourceName);
  static Insertable<BookSourceRow> custom({
    Expression<String>? bookSourceUrl,
    Expression<String>? bookSourceName,
    Expression<int>? bookSourceType,
    Expression<String>? bookSourceGroup,
    Expression<String>? bookSourceComment,
    Expression<String>? loginUrl,
    Expression<String>? loginUi,
    Expression<String>? loginCheckJs,
    Expression<String>? coverDecodeJs,
    Expression<String>? bookUrlPattern,
    Expression<String>? header,
    Expression<String>? variableComment,
    Expression<int>? customOrder,
    Expression<int>? weight,
    Expression<int>? enabled,
    Expression<int>? enabledExplore,
    Expression<int>? enabledCookieJar,
    Expression<int>? lastUpdateTime,
    Expression<int>? respondTime,
    Expression<String>? jsLib,
    Expression<String>? concurrentRate,
    Expression<String>? exploreUrl,
    Expression<String>? exploreScreen,
    Expression<String>? searchUrl,
    Expression<String>? ruleSearch,
    Expression<String>? ruleExplore,
    Expression<String>? ruleBookInfo,
    Expression<String>? ruleToc,
    Expression<String>? ruleContent,
    Expression<String>? ruleReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookSourceUrl != null) 'bookSourceUrl': bookSourceUrl,
      if (bookSourceName != null) 'bookSourceName': bookSourceName,
      if (bookSourceType != null) 'bookSourceType': bookSourceType,
      if (bookSourceGroup != null) 'bookSourceGroup': bookSourceGroup,
      if (bookSourceComment != null) 'bookSourceComment': bookSourceComment,
      if (loginUrl != null) 'loginUrl': loginUrl,
      if (loginUi != null) 'loginUi': loginUi,
      if (loginCheckJs != null) 'loginCheckJs': loginCheckJs,
      if (coverDecodeJs != null) 'coverDecodeJs': coverDecodeJs,
      if (bookUrlPattern != null) 'bookUrlPattern': bookUrlPattern,
      if (header != null) 'header': header,
      if (variableComment != null) 'variableComment': variableComment,
      if (customOrder != null) 'customOrder': customOrder,
      if (weight != null) 'weight': weight,
      if (enabled != null) 'enabled': enabled,
      if (enabledExplore != null) 'enabledExplore': enabledExplore,
      if (enabledCookieJar != null) 'enabledCookieJar': enabledCookieJar,
      if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime,
      if (respondTime != null) 'respondTime': respondTime,
      if (jsLib != null) 'jsLib': jsLib,
      if (concurrentRate != null) 'concurrentRate': concurrentRate,
      if (exploreUrl != null) 'exploreUrl': exploreUrl,
      if (exploreScreen != null) 'exploreScreen': exploreScreen,
      if (searchUrl != null) 'searchUrl': searchUrl,
      if (ruleSearch != null) 'ruleSearch': ruleSearch,
      if (ruleExplore != null) 'ruleExplore': ruleExplore,
      if (ruleBookInfo != null) 'ruleBookInfo': ruleBookInfo,
      if (ruleToc != null) 'ruleToc': ruleToc,
      if (ruleContent != null) 'ruleContent': ruleContent,
      if (ruleReview != null) 'ruleReview': ruleReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookSourcesCompanion copyWith({
    Value<String>? bookSourceUrl,
    Value<String>? bookSourceName,
    Value<int>? bookSourceType,
    Value<String?>? bookSourceGroup,
    Value<String?>? bookSourceComment,
    Value<String?>? loginUrl,
    Value<String?>? loginUi,
    Value<String?>? loginCheckJs,
    Value<String?>? coverDecodeJs,
    Value<String?>? bookUrlPattern,
    Value<String?>? header,
    Value<String?>? variableComment,
    Value<int>? customOrder,
    Value<int>? weight,
    Value<int>? enabled,
    Value<int>? enabledExplore,
    Value<int>? enabledCookieJar,
    Value<int>? lastUpdateTime,
    Value<int>? respondTime,
    Value<String?>? jsLib,
    Value<String?>? concurrentRate,
    Value<String?>? exploreUrl,
    Value<String?>? exploreScreen,
    Value<String?>? searchUrl,
    Value<String?>? ruleSearch,
    Value<String?>? ruleExplore,
    Value<String?>? ruleBookInfo,
    Value<String?>? ruleToc,
    Value<String?>? ruleContent,
    Value<String?>? ruleReview,
    Value<int>? rowid,
  }) {
    return BookSourcesCompanion(
      bookSourceUrl: bookSourceUrl ?? this.bookSourceUrl,
      bookSourceName: bookSourceName ?? this.bookSourceName,
      bookSourceType: bookSourceType ?? this.bookSourceType,
      bookSourceGroup: bookSourceGroup ?? this.bookSourceGroup,
      bookSourceComment: bookSourceComment ?? this.bookSourceComment,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi ?? this.loginUi,
      loginCheckJs: loginCheckJs ?? this.loginCheckJs,
      coverDecodeJs: coverDecodeJs ?? this.coverDecodeJs,
      bookUrlPattern: bookUrlPattern ?? this.bookUrlPattern,
      header: header ?? this.header,
      variableComment: variableComment ?? this.variableComment,
      customOrder: customOrder ?? this.customOrder,
      weight: weight ?? this.weight,
      enabled: enabled ?? this.enabled,
      enabledExplore: enabledExplore ?? this.enabledExplore,
      enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      respondTime: respondTime ?? this.respondTime,
      jsLib: jsLib ?? this.jsLib,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      exploreUrl: exploreUrl ?? this.exploreUrl,
      exploreScreen: exploreScreen ?? this.exploreScreen,
      searchUrl: searchUrl ?? this.searchUrl,
      ruleSearch: ruleSearch ?? this.ruleSearch,
      ruleExplore: ruleExplore ?? this.ruleExplore,
      ruleBookInfo: ruleBookInfo ?? this.ruleBookInfo,
      ruleToc: ruleToc ?? this.ruleToc,
      ruleContent: ruleContent ?? this.ruleContent,
      ruleReview: ruleReview ?? this.ruleReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookSourceUrl.present) {
      map['bookSourceUrl'] = Variable<String>(bookSourceUrl.value);
    }
    if (bookSourceName.present) {
      map['bookSourceName'] = Variable<String>(bookSourceName.value);
    }
    if (bookSourceType.present) {
      map['bookSourceType'] = Variable<int>(bookSourceType.value);
    }
    if (bookSourceGroup.present) {
      map['bookSourceGroup'] = Variable<String>(bookSourceGroup.value);
    }
    if (bookSourceComment.present) {
      map['bookSourceComment'] = Variable<String>(bookSourceComment.value);
    }
    if (loginUrl.present) {
      map['loginUrl'] = Variable<String>(loginUrl.value);
    }
    if (loginUi.present) {
      map['loginUi'] = Variable<String>(loginUi.value);
    }
    if (loginCheckJs.present) {
      map['loginCheckJs'] = Variable<String>(loginCheckJs.value);
    }
    if (coverDecodeJs.present) {
      map['coverDecodeJs'] = Variable<String>(coverDecodeJs.value);
    }
    if (bookUrlPattern.present) {
      map['bookUrlPattern'] = Variable<String>(bookUrlPattern.value);
    }
    if (header.present) {
      map['header'] = Variable<String>(header.value);
    }
    if (variableComment.present) {
      map['variableComment'] = Variable<String>(variableComment.value);
    }
    if (customOrder.present) {
      map['customOrder'] = Variable<int>(customOrder.value);
    }
    if (weight.present) {
      map['weight'] = Variable<int>(weight.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<int>(enabled.value);
    }
    if (enabledExplore.present) {
      map['enabledExplore'] = Variable<int>(enabledExplore.value);
    }
    if (enabledCookieJar.present) {
      map['enabledCookieJar'] = Variable<int>(enabledCookieJar.value);
    }
    if (lastUpdateTime.present) {
      map['lastUpdateTime'] = Variable<int>(lastUpdateTime.value);
    }
    if (respondTime.present) {
      map['respondTime'] = Variable<int>(respondTime.value);
    }
    if (jsLib.present) {
      map['jsLib'] = Variable<String>(jsLib.value);
    }
    if (concurrentRate.present) {
      map['concurrentRate'] = Variable<String>(concurrentRate.value);
    }
    if (exploreUrl.present) {
      map['exploreUrl'] = Variable<String>(exploreUrl.value);
    }
    if (exploreScreen.present) {
      map['exploreScreen'] = Variable<String>(exploreScreen.value);
    }
    if (searchUrl.present) {
      map['searchUrl'] = Variable<String>(searchUrl.value);
    }
    if (ruleSearch.present) {
      map['ruleSearch'] = Variable<String>(ruleSearch.value);
    }
    if (ruleExplore.present) {
      map['ruleExplore'] = Variable<String>(ruleExplore.value);
    }
    if (ruleBookInfo.present) {
      map['ruleBookInfo'] = Variable<String>(ruleBookInfo.value);
    }
    if (ruleToc.present) {
      map['ruleToc'] = Variable<String>(ruleToc.value);
    }
    if (ruleContent.present) {
      map['ruleContent'] = Variable<String>(ruleContent.value);
    }
    if (ruleReview.present) {
      map['ruleReview'] = Variable<String>(ruleReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookSourcesCompanion(')
          ..write('bookSourceUrl: $bookSourceUrl, ')
          ..write('bookSourceName: $bookSourceName, ')
          ..write('bookSourceType: $bookSourceType, ')
          ..write('bookSourceGroup: $bookSourceGroup, ')
          ..write('bookSourceComment: $bookSourceComment, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('loginUi: $loginUi, ')
          ..write('loginCheckJs: $loginCheckJs, ')
          ..write('coverDecodeJs: $coverDecodeJs, ')
          ..write('bookUrlPattern: $bookUrlPattern, ')
          ..write('header: $header, ')
          ..write('variableComment: $variableComment, ')
          ..write('customOrder: $customOrder, ')
          ..write('weight: $weight, ')
          ..write('enabled: $enabled, ')
          ..write('enabledExplore: $enabledExplore, ')
          ..write('enabledCookieJar: $enabledCookieJar, ')
          ..write('lastUpdateTime: $lastUpdateTime, ')
          ..write('respondTime: $respondTime, ')
          ..write('jsLib: $jsLib, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('exploreUrl: $exploreUrl, ')
          ..write('exploreScreen: $exploreScreen, ')
          ..write('searchUrl: $searchUrl, ')
          ..write('ruleSearch: $ruleSearch, ')
          ..write('ruleExplore: $ruleExplore, ')
          ..write('ruleBookInfo: $ruleBookInfo, ')
          ..write('ruleToc: $ruleToc, ')
          ..write('ruleContent: $ruleContent, ')
          ..write('ruleReview: $ruleReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookGroupsTable extends BookGroups
    with TableInfo<$BookGroupsTable, BookGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'groupId',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'groupName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _showMeta = const VerificationMeta('show');
  @override
  late final GeneratedColumn<int> show = GeneratedColumn<int>(
    'show',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'coverPath',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enableRefreshMeta = const VerificationMeta(
    'enableRefresh',
  );
  @override
  late final GeneratedColumn<int> enableRefresh = GeneratedColumn<int>(
    'enableRefresh',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _bookSortMeta = const VerificationMeta(
    'bookSort',
  );
  @override
  late final GeneratedColumn<int> bookSort = GeneratedColumn<int>(
    'bookSort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    groupName,
    order,
    show,
    coverPath,
    enableRefresh,
    bookSort,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('groupId')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['groupId']!, _groupIdMeta),
      );
    }
    if (data.containsKey('groupName')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['groupName']!, _groupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_groupNameMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('show')) {
      context.handle(
        _showMeta,
        show.isAcceptableOrUnknown(data['show']!, _showMeta),
      );
    }
    if (data.containsKey('coverPath')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['coverPath']!, _coverPathMeta),
      );
    }
    if (data.containsKey('enableRefresh')) {
      context.handle(
        _enableRefreshMeta,
        enableRefresh.isAcceptableOrUnknown(
          data['enableRefresh']!,
          _enableRefreshMeta,
        ),
      );
    }
    if (data.containsKey('bookSort')) {
      context.handle(
        _bookSortMeta,
        bookSort.isAcceptableOrUnknown(data['bookSort']!, _bookSortMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  BookGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookGroupRow(
      groupId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}groupId'],
          )!,
      groupName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}groupName'],
          )!,
      order:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}order'],
          )!,
      show:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}show'],
          )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverPath'],
      ),
      enableRefresh:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enableRefresh'],
          )!,
      bookSort:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}bookSort'],
          )!,
    );
  }

  @override
  $BookGroupsTable createAlias(String alias) {
    return $BookGroupsTable(attachedDatabase, alias);
  }
}

class BookGroupRow extends DataClass implements Insertable<BookGroupRow> {
  final int groupId;
  final String groupName;
  final int order;
  final int show;
  final String? coverPath;
  final int enableRefresh;
  final int bookSort;
  const BookGroupRow({
    required this.groupId,
    required this.groupName,
    required this.order,
    required this.show,
    this.coverPath,
    required this.enableRefresh,
    required this.bookSort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['groupId'] = Variable<int>(groupId);
    map['groupName'] = Variable<String>(groupName);
    map['order'] = Variable<int>(order);
    map['show'] = Variable<int>(show);
    if (!nullToAbsent || coverPath != null) {
      map['coverPath'] = Variable<String>(coverPath);
    }
    map['enableRefresh'] = Variable<int>(enableRefresh);
    map['bookSort'] = Variable<int>(bookSort);
    return map;
  }

  BookGroupsCompanion toCompanion(bool nullToAbsent) {
    return BookGroupsCompanion(
      groupId: Value(groupId),
      groupName: Value(groupName),
      order: Value(order),
      show: Value(show),
      coverPath:
          coverPath == null && nullToAbsent
              ? const Value.absent()
              : Value(coverPath),
      enableRefresh: Value(enableRefresh),
      bookSort: Value(bookSort),
    );
  }

  factory BookGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookGroupRow(
      groupId: serializer.fromJson<int>(json['groupId']),
      groupName: serializer.fromJson<String>(json['groupName']),
      order: serializer.fromJson<int>(json['order']),
      show: serializer.fromJson<int>(json['show']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      enableRefresh: serializer.fromJson<int>(json['enableRefresh']),
      bookSort: serializer.fromJson<int>(json['bookSort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<int>(groupId),
      'groupName': serializer.toJson<String>(groupName),
      'order': serializer.toJson<int>(order),
      'show': serializer.toJson<int>(show),
      'coverPath': serializer.toJson<String?>(coverPath),
      'enableRefresh': serializer.toJson<int>(enableRefresh),
      'bookSort': serializer.toJson<int>(bookSort),
    };
  }

  BookGroupRow copyWith({
    int? groupId,
    String? groupName,
    int? order,
    int? show,
    Value<String?> coverPath = const Value.absent(),
    int? enableRefresh,
    int? bookSort,
  }) => BookGroupRow(
    groupId: groupId ?? this.groupId,
    groupName: groupName ?? this.groupName,
    order: order ?? this.order,
    show: show ?? this.show,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    enableRefresh: enableRefresh ?? this.enableRefresh,
    bookSort: bookSort ?? this.bookSort,
  );
  BookGroupRow copyWithCompanion(BookGroupsCompanion data) {
    return BookGroupRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      order: data.order.present ? data.order.value : this.order,
      show: data.show.present ? data.show.value : this.show,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      enableRefresh:
          data.enableRefresh.present
              ? data.enableRefresh.value
              : this.enableRefresh,
      bookSort: data.bookSort.present ? data.bookSort.value : this.bookSort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookGroupRow(')
          ..write('groupId: $groupId, ')
          ..write('groupName: $groupName, ')
          ..write('order: $order, ')
          ..write('show: $show, ')
          ..write('coverPath: $coverPath, ')
          ..write('enableRefresh: $enableRefresh, ')
          ..write('bookSort: $bookSort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    groupName,
    order,
    show,
    coverPath,
    enableRefresh,
    bookSort,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookGroupRow &&
          other.groupId == this.groupId &&
          other.groupName == this.groupName &&
          other.order == this.order &&
          other.show == this.show &&
          other.coverPath == this.coverPath &&
          other.enableRefresh == this.enableRefresh &&
          other.bookSort == this.bookSort);
}

class BookGroupsCompanion extends UpdateCompanion<BookGroupRow> {
  final Value<int> groupId;
  final Value<String> groupName;
  final Value<int> order;
  final Value<int> show;
  final Value<String?> coverPath;
  final Value<int> enableRefresh;
  final Value<int> bookSort;
  const BookGroupsCompanion({
    this.groupId = const Value.absent(),
    this.groupName = const Value.absent(),
    this.order = const Value.absent(),
    this.show = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.enableRefresh = const Value.absent(),
    this.bookSort = const Value.absent(),
  });
  BookGroupsCompanion.insert({
    this.groupId = const Value.absent(),
    required String groupName,
    this.order = const Value.absent(),
    this.show = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.enableRefresh = const Value.absent(),
    this.bookSort = const Value.absent(),
  }) : groupName = Value(groupName);
  static Insertable<BookGroupRow> custom({
    Expression<int>? groupId,
    Expression<String>? groupName,
    Expression<int>? order,
    Expression<int>? show,
    Expression<String>? coverPath,
    Expression<int>? enableRefresh,
    Expression<int>? bookSort,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'groupId': groupId,
      if (groupName != null) 'groupName': groupName,
      if (order != null) 'order': order,
      if (show != null) 'show': show,
      if (coverPath != null) 'coverPath': coverPath,
      if (enableRefresh != null) 'enableRefresh': enableRefresh,
      if (bookSort != null) 'bookSort': bookSort,
    });
  }

  BookGroupsCompanion copyWith({
    Value<int>? groupId,
    Value<String>? groupName,
    Value<int>? order,
    Value<int>? show,
    Value<String?>? coverPath,
    Value<int>? enableRefresh,
    Value<int>? bookSort,
  }) {
    return BookGroupsCompanion(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      order: order ?? this.order,
      show: show ?? this.show,
      coverPath: coverPath ?? this.coverPath,
      enableRefresh: enableRefresh ?? this.enableRefresh,
      bookSort: bookSort ?? this.bookSort,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['groupId'] = Variable<int>(groupId.value);
    }
    if (groupName.present) {
      map['groupName'] = Variable<String>(groupName.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (show.present) {
      map['show'] = Variable<int>(show.value);
    }
    if (coverPath.present) {
      map['coverPath'] = Variable<String>(coverPath.value);
    }
    if (enableRefresh.present) {
      map['enableRefresh'] = Variable<int>(enableRefresh.value);
    }
    if (bookSort.present) {
      map['bookSort'] = Variable<int>(bookSort.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookGroupsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('groupName: $groupName, ')
          ..write('order: $order, ')
          ..write('show: $show, ')
          ..write('coverPath: $coverPath, ')
          ..write('enableRefresh: $enableRefresh, ')
          ..write('bookSort: $bookSort')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory
    with TableInfo<$SearchHistoryTable, SearchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keywordMeta = const VerificationMeta(
    'keyword',
  );
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
    'keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchTimeMeta = const VerificationMeta(
    'searchTime',
  );
  @override
  late final GeneratedColumn<int> searchTime = GeneratedColumn<int>(
    'searchTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, keyword, searchTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('keyword')) {
      context.handle(
        _keywordMeta,
        keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('searchTime')) {
      context.handle(
        _searchTimeMeta,
        searchTime.isAcceptableOrUnknown(data['searchTime']!, _searchTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      keyword:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}keyword'],
          )!,
      searchTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}searchTime'],
          )!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryRow extends DataClass
    implements Insertable<SearchHistoryRow> {
  final int id;
  final String keyword;
  final int searchTime;
  const SearchHistoryRow({
    required this.id,
    required this.keyword,
    required this.searchTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['keyword'] = Variable<String>(keyword);
    map['searchTime'] = Variable<int>(searchTime);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(
      id: Value(id),
      keyword: Value(keyword),
      searchTime: Value(searchTime),
    );
  }

  factory SearchHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      keyword: serializer.fromJson<String>(json['keyword']),
      searchTime: serializer.fromJson<int>(json['searchTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyword': serializer.toJson<String>(keyword),
      'searchTime': serializer.toJson<int>(searchTime),
    };
  }

  SearchHistoryRow copyWith({int? id, String? keyword, int? searchTime}) =>
      SearchHistoryRow(
        id: id ?? this.id,
        keyword: keyword ?? this.keyword,
        searchTime: searchTime ?? this.searchTime,
      );
  SearchHistoryRow copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      searchTime:
          data.searchTime.present ? data.searchTime.value : this.searchTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRow(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('searchTime: $searchTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyword, searchTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryRow &&
          other.id == this.id &&
          other.keyword == this.keyword &&
          other.searchTime == this.searchTime);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryRow> {
  final Value<int> id;
  final Value<String> keyword;
  final Value<int> searchTime;
  const SearchHistoryCompanion({
    this.id = const Value.absent(),
    this.keyword = const Value.absent(),
    this.searchTime = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String keyword,
    required int searchTime,
  }) : keyword = Value(keyword),
       searchTime = Value(searchTime);
  static Insertable<SearchHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? keyword,
    Expression<int>? searchTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyword != null) 'keyword': keyword,
      if (searchTime != null) 'searchTime': searchTime,
    });
  }

  SearchHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? keyword,
    Value<int>? searchTime,
  }) {
    return SearchHistoryCompanion(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      searchTime: searchTime ?? this.searchTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (searchTime.present) {
      map['searchTime'] = Variable<int>(searchTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('searchTime: $searchTime')
          ..write(')'))
        .toString();
  }
}

class $ReplaceRulesTable extends ReplaceRules
    with TableInfo<$ReplaceRulesTable, ReplaceRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReplaceRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replacementMeta = const VerificationMeta(
    'replacement',
  );
  @override
  late final GeneratedColumn<String> replacement = GeneratedColumn<String>(
    'replacement',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scopeTitleMeta = const VerificationMeta(
    'scopeTitle',
  );
  @override
  late final GeneratedColumn<int> scopeTitle = GeneratedColumn<int>(
    'scopeTitle',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scopeContentMeta = const VerificationMeta(
    'scopeContent',
  );
  @override
  late final GeneratedColumn<int> scopeContent = GeneratedColumn<int>(
    'scopeContent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _excludeScopeMeta = const VerificationMeta(
    'excludeScope',
  );
  @override
  late final GeneratedColumn<String> excludeScope = GeneratedColumn<String>(
    'excludeScope',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<int> isEnabled = GeneratedColumn<int>(
    'isEnabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isRegexMeta = const VerificationMeta(
    'isRegex',
  );
  @override
  late final GeneratedColumn<int> isRegex = GeneratedColumn<int>(
    'isRegex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _timeoutMillisecondMeta =
      const VerificationMeta('timeoutMillisecond');
  @override
  late final GeneratedColumn<int> timeoutMillisecond = GeneratedColumn<int>(
    'timeoutMillisecond',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3000),
  );
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
    'group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    pattern,
    replacement,
    scope,
    scopeTitle,
    scopeContent,
    excludeScope,
    isEnabled,
    isRegex,
    timeoutMillisecond,
    group,
    order,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'replace_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplaceRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('replacement')) {
      context.handle(
        _replacementMeta,
        replacement.isAcceptableOrUnknown(
          data['replacement']!,
          _replacementMeta,
        ),
      );
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    }
    if (data.containsKey('scopeTitle')) {
      context.handle(
        _scopeTitleMeta,
        scopeTitle.isAcceptableOrUnknown(data['scopeTitle']!, _scopeTitleMeta),
      );
    }
    if (data.containsKey('scopeContent')) {
      context.handle(
        _scopeContentMeta,
        scopeContent.isAcceptableOrUnknown(
          data['scopeContent']!,
          _scopeContentMeta,
        ),
      );
    }
    if (data.containsKey('excludeScope')) {
      context.handle(
        _excludeScopeMeta,
        excludeScope.isAcceptableOrUnknown(
          data['excludeScope']!,
          _excludeScopeMeta,
        ),
      );
    }
    if (data.containsKey('isEnabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['isEnabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('isRegex')) {
      context.handle(
        _isRegexMeta,
        isRegex.isAcceptableOrUnknown(data['isRegex']!, _isRegexMeta),
      );
    }
    if (data.containsKey('timeoutMillisecond')) {
      context.handle(
        _timeoutMillisecondMeta,
        timeoutMillisecond.isAcceptableOrUnknown(
          data['timeoutMillisecond']!,
          _timeoutMillisecondMeta,
        ),
      );
    }
    if (data.containsKey('group')) {
      context.handle(
        _groupMeta,
        group.isAcceptableOrUnknown(data['group']!, _groupMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplaceRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplaceRuleRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      pattern:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}pattern'],
          )!,
      replacement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replacement'],
      ),
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      ),
      scopeTitle:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}scopeTitle'],
          )!,
      scopeContent:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}scopeContent'],
          )!,
      excludeScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excludeScope'],
      ),
      isEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}isEnabled'],
          )!,
      isRegex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}isRegex'],
          )!,
      timeoutMillisecond:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}timeoutMillisecond'],
          )!,
      group: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group'],
      ),
      order:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}order'],
          )!,
    );
  }

  @override
  $ReplaceRulesTable createAlias(String alias) {
    return $ReplaceRulesTable(attachedDatabase, alias);
  }
}

class ReplaceRuleRow extends DataClass implements Insertable<ReplaceRuleRow> {
  final int id;
  final String? name;
  final String pattern;
  final String? replacement;
  final String? scope;
  final int scopeTitle;
  final int scopeContent;
  final String? excludeScope;
  final int isEnabled;
  final int isRegex;
  final int timeoutMillisecond;
  final String? group;
  final int order;
  const ReplaceRuleRow({
    required this.id,
    this.name,
    required this.pattern,
    this.replacement,
    this.scope,
    required this.scopeTitle,
    required this.scopeContent,
    this.excludeScope,
    required this.isEnabled,
    required this.isRegex,
    required this.timeoutMillisecond,
    this.group,
    required this.order,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['pattern'] = Variable<String>(pattern);
    if (!nullToAbsent || replacement != null) {
      map['replacement'] = Variable<String>(replacement);
    }
    if (!nullToAbsent || scope != null) {
      map['scope'] = Variable<String>(scope);
    }
    map['scopeTitle'] = Variable<int>(scopeTitle);
    map['scopeContent'] = Variable<int>(scopeContent);
    if (!nullToAbsent || excludeScope != null) {
      map['excludeScope'] = Variable<String>(excludeScope);
    }
    map['isEnabled'] = Variable<int>(isEnabled);
    map['isRegex'] = Variable<int>(isRegex);
    map['timeoutMillisecond'] = Variable<int>(timeoutMillisecond);
    if (!nullToAbsent || group != null) {
      map['group'] = Variable<String>(group);
    }
    map['order'] = Variable<int>(order);
    return map;
  }

  ReplaceRulesCompanion toCompanion(bool nullToAbsent) {
    return ReplaceRulesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      pattern: Value(pattern),
      replacement:
          replacement == null && nullToAbsent
              ? const Value.absent()
              : Value(replacement),
      scope:
          scope == null && nullToAbsent ? const Value.absent() : Value(scope),
      scopeTitle: Value(scopeTitle),
      scopeContent: Value(scopeContent),
      excludeScope:
          excludeScope == null && nullToAbsent
              ? const Value.absent()
              : Value(excludeScope),
      isEnabled: Value(isEnabled),
      isRegex: Value(isRegex),
      timeoutMillisecond: Value(timeoutMillisecond),
      group:
          group == null && nullToAbsent ? const Value.absent() : Value(group),
      order: Value(order),
    );
  }

  factory ReplaceRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplaceRuleRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      pattern: serializer.fromJson<String>(json['pattern']),
      replacement: serializer.fromJson<String?>(json['replacement']),
      scope: serializer.fromJson<String?>(json['scope']),
      scopeTitle: serializer.fromJson<int>(json['scopeTitle']),
      scopeContent: serializer.fromJson<int>(json['scopeContent']),
      excludeScope: serializer.fromJson<String?>(json['excludeScope']),
      isEnabled: serializer.fromJson<int>(json['isEnabled']),
      isRegex: serializer.fromJson<int>(json['isRegex']),
      timeoutMillisecond: serializer.fromJson<int>(json['timeoutMillisecond']),
      group: serializer.fromJson<String?>(json['group']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'pattern': serializer.toJson<String>(pattern),
      'replacement': serializer.toJson<String?>(replacement),
      'scope': serializer.toJson<String?>(scope),
      'scopeTitle': serializer.toJson<int>(scopeTitle),
      'scopeContent': serializer.toJson<int>(scopeContent),
      'excludeScope': serializer.toJson<String?>(excludeScope),
      'isEnabled': serializer.toJson<int>(isEnabled),
      'isRegex': serializer.toJson<int>(isRegex),
      'timeoutMillisecond': serializer.toJson<int>(timeoutMillisecond),
      'group': serializer.toJson<String?>(group),
      'order': serializer.toJson<int>(order),
    };
  }

  ReplaceRuleRow copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    String? pattern,
    Value<String?> replacement = const Value.absent(),
    Value<String?> scope = const Value.absent(),
    int? scopeTitle,
    int? scopeContent,
    Value<String?> excludeScope = const Value.absent(),
    int? isEnabled,
    int? isRegex,
    int? timeoutMillisecond,
    Value<String?> group = const Value.absent(),
    int? order,
  }) => ReplaceRuleRow(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    pattern: pattern ?? this.pattern,
    replacement: replacement.present ? replacement.value : this.replacement,
    scope: scope.present ? scope.value : this.scope,
    scopeTitle: scopeTitle ?? this.scopeTitle,
    scopeContent: scopeContent ?? this.scopeContent,
    excludeScope: excludeScope.present ? excludeScope.value : this.excludeScope,
    isEnabled: isEnabled ?? this.isEnabled,
    isRegex: isRegex ?? this.isRegex,
    timeoutMillisecond: timeoutMillisecond ?? this.timeoutMillisecond,
    group: group.present ? group.value : this.group,
    order: order ?? this.order,
  );
  ReplaceRuleRow copyWithCompanion(ReplaceRulesCompanion data) {
    return ReplaceRuleRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      replacement:
          data.replacement.present ? data.replacement.value : this.replacement,
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeTitle:
          data.scopeTitle.present ? data.scopeTitle.value : this.scopeTitle,
      scopeContent:
          data.scopeContent.present
              ? data.scopeContent.value
              : this.scopeContent,
      excludeScope:
          data.excludeScope.present
              ? data.excludeScope.value
              : this.excludeScope,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      isRegex: data.isRegex.present ? data.isRegex.value : this.isRegex,
      timeoutMillisecond:
          data.timeoutMillisecond.present
              ? data.timeoutMillisecond.value
              : this.timeoutMillisecond,
      group: data.group.present ? data.group.value : this.group,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplaceRuleRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pattern: $pattern, ')
          ..write('replacement: $replacement, ')
          ..write('scope: $scope, ')
          ..write('scopeTitle: $scopeTitle, ')
          ..write('scopeContent: $scopeContent, ')
          ..write('excludeScope: $excludeScope, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isRegex: $isRegex, ')
          ..write('timeoutMillisecond: $timeoutMillisecond, ')
          ..write('group: $group, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    pattern,
    replacement,
    scope,
    scopeTitle,
    scopeContent,
    excludeScope,
    isEnabled,
    isRegex,
    timeoutMillisecond,
    group,
    order,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplaceRuleRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.pattern == this.pattern &&
          other.replacement == this.replacement &&
          other.scope == this.scope &&
          other.scopeTitle == this.scopeTitle &&
          other.scopeContent == this.scopeContent &&
          other.excludeScope == this.excludeScope &&
          other.isEnabled == this.isEnabled &&
          other.isRegex == this.isRegex &&
          other.timeoutMillisecond == this.timeoutMillisecond &&
          other.group == this.group &&
          other.order == this.order);
}

class ReplaceRulesCompanion extends UpdateCompanion<ReplaceRuleRow> {
  final Value<int> id;
  final Value<String?> name;
  final Value<String> pattern;
  final Value<String?> replacement;
  final Value<String?> scope;
  final Value<int> scopeTitle;
  final Value<int> scopeContent;
  final Value<String?> excludeScope;
  final Value<int> isEnabled;
  final Value<int> isRegex;
  final Value<int> timeoutMillisecond;
  final Value<String?> group;
  final Value<int> order;
  const ReplaceRulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.pattern = const Value.absent(),
    this.replacement = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeTitle = const Value.absent(),
    this.scopeContent = const Value.absent(),
    this.excludeScope = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isRegex = const Value.absent(),
    this.timeoutMillisecond = const Value.absent(),
    this.group = const Value.absent(),
    this.order = const Value.absent(),
  });
  ReplaceRulesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    required String pattern,
    this.replacement = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeTitle = const Value.absent(),
    this.scopeContent = const Value.absent(),
    this.excludeScope = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isRegex = const Value.absent(),
    this.timeoutMillisecond = const Value.absent(),
    this.group = const Value.absent(),
    this.order = const Value.absent(),
  }) : pattern = Value(pattern);
  static Insertable<ReplaceRuleRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? pattern,
    Expression<String>? replacement,
    Expression<String>? scope,
    Expression<int>? scopeTitle,
    Expression<int>? scopeContent,
    Expression<String>? excludeScope,
    Expression<int>? isEnabled,
    Expression<int>? isRegex,
    Expression<int>? timeoutMillisecond,
    Expression<String>? group,
    Expression<int>? order,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (pattern != null) 'pattern': pattern,
      if (replacement != null) 'replacement': replacement,
      if (scope != null) 'scope': scope,
      if (scopeTitle != null) 'scopeTitle': scopeTitle,
      if (scopeContent != null) 'scopeContent': scopeContent,
      if (excludeScope != null) 'excludeScope': excludeScope,
      if (isEnabled != null) 'isEnabled': isEnabled,
      if (isRegex != null) 'isRegex': isRegex,
      if (timeoutMillisecond != null) 'timeoutMillisecond': timeoutMillisecond,
      if (group != null) 'group': group,
      if (order != null) 'order': order,
    });
  }

  ReplaceRulesCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<String>? pattern,
    Value<String?>? replacement,
    Value<String?>? scope,
    Value<int>? scopeTitle,
    Value<int>? scopeContent,
    Value<String?>? excludeScope,
    Value<int>? isEnabled,
    Value<int>? isRegex,
    Value<int>? timeoutMillisecond,
    Value<String?>? group,
    Value<int>? order,
  }) {
    return ReplaceRulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      replacement: replacement ?? this.replacement,
      scope: scope ?? this.scope,
      scopeTitle: scopeTitle ?? this.scopeTitle,
      scopeContent: scopeContent ?? this.scopeContent,
      excludeScope: excludeScope ?? this.excludeScope,
      isEnabled: isEnabled ?? this.isEnabled,
      isRegex: isRegex ?? this.isRegex,
      timeoutMillisecond: timeoutMillisecond ?? this.timeoutMillisecond,
      group: group ?? this.group,
      order: order ?? this.order,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (replacement.present) {
      map['replacement'] = Variable<String>(replacement.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (scopeTitle.present) {
      map['scopeTitle'] = Variable<int>(scopeTitle.value);
    }
    if (scopeContent.present) {
      map['scopeContent'] = Variable<int>(scopeContent.value);
    }
    if (excludeScope.present) {
      map['excludeScope'] = Variable<String>(excludeScope.value);
    }
    if (isEnabled.present) {
      map['isEnabled'] = Variable<int>(isEnabled.value);
    }
    if (isRegex.present) {
      map['isRegex'] = Variable<int>(isRegex.value);
    }
    if (timeoutMillisecond.present) {
      map['timeoutMillisecond'] = Variable<int>(timeoutMillisecond.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(group.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReplaceRulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pattern: $pattern, ')
          ..write('replacement: $replacement, ')
          ..write('scope: $scope, ')
          ..write('scopeTitle: $scopeTitle, ')
          ..write('scopeContent: $scopeContent, ')
          ..write('excludeScope: $excludeScope, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isRegex: $isRegex, ')
          ..write('timeoutMillisecond: $timeoutMillisecond, ')
          ..write('group: $group, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'bookName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookAuthorMeta = const VerificationMeta(
    'bookAuthor',
  );
  @override
  late final GeneratedColumn<String> bookAuthor = GeneratedColumn<String>(
    'bookAuthor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapterIndex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _chapterPosMeta = const VerificationMeta(
    'chapterPos',
  );
  @override
  late final GeneratedColumn<int> chapterPos = GeneratedColumn<int>(
    'chapterPos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _chapterNameMeta = const VerificationMeta(
    'chapterName',
  );
  @override
  late final GeneratedColumn<String> chapterName = GeneratedColumn<String>(
    'chapterName',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookUrlMeta = const VerificationMeta(
    'bookUrl',
  );
  @override
  late final GeneratedColumn<String> bookUrl = GeneratedColumn<String>(
    'bookUrl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookTextMeta = const VerificationMeta(
    'bookText',
  );
  @override
  late final GeneratedColumn<String> bookText = GeneratedColumn<String>(
    'bookText',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    time,
    bookName,
    bookAuthor,
    chapterIndex,
    chapterPos,
    chapterName,
    bookUrl,
    bookText,
    content,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('bookName')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['bookName']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('bookAuthor')) {
      context.handle(
        _bookAuthorMeta,
        bookAuthor.isAcceptableOrUnknown(data['bookAuthor']!, _bookAuthorMeta),
      );
    }
    if (data.containsKey('chapterIndex')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapterIndex']!,
          _chapterIndexMeta,
        ),
      );
    }
    if (data.containsKey('chapterPos')) {
      context.handle(
        _chapterPosMeta,
        chapterPos.isAcceptableOrUnknown(data['chapterPos']!, _chapterPosMeta),
      );
    }
    if (data.containsKey('chapterName')) {
      context.handle(
        _chapterNameMeta,
        chapterName.isAcceptableOrUnknown(
          data['chapterName']!,
          _chapterNameMeta,
        ),
      );
    }
    if (data.containsKey('bookUrl')) {
      context.handle(
        _bookUrlMeta,
        bookUrl.isAcceptableOrUnknown(data['bookUrl']!, _bookUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bookUrlMeta);
    }
    if (data.containsKey('bookText')) {
      context.handle(
        _bookTextMeta,
        bookText.isAcceptableOrUnknown(data['bookText']!, _bookTextMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      time:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}time'],
          )!,
      bookName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookName'],
          )!,
      bookAuthor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bookAuthor'],
      ),
      chapterIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}chapterIndex'],
          )!,
      chapterPos:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}chapterPos'],
          )!,
      chapterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapterName'],
      ),
      bookUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookUrl'],
          )!,
      bookText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bookText'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final int id;
  final int time;
  final String bookName;
  final String? bookAuthor;
  final int chapterIndex;
  final int chapterPos;
  final String? chapterName;
  final String bookUrl;
  final String? bookText;
  final String? content;
  const BookmarkRow({
    required this.id,
    required this.time,
    required this.bookName,
    this.bookAuthor,
    required this.chapterIndex,
    required this.chapterPos,
    this.chapterName,
    required this.bookUrl,
    this.bookText,
    this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time'] = Variable<int>(time);
    map['bookName'] = Variable<String>(bookName);
    if (!nullToAbsent || bookAuthor != null) {
      map['bookAuthor'] = Variable<String>(bookAuthor);
    }
    map['chapterIndex'] = Variable<int>(chapterIndex);
    map['chapterPos'] = Variable<int>(chapterPos);
    if (!nullToAbsent || chapterName != null) {
      map['chapterName'] = Variable<String>(chapterName);
    }
    map['bookUrl'] = Variable<String>(bookUrl);
    if (!nullToAbsent || bookText != null) {
      map['bookText'] = Variable<String>(bookText);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      time: Value(time),
      bookName: Value(bookName),
      bookAuthor:
          bookAuthor == null && nullToAbsent
              ? const Value.absent()
              : Value(bookAuthor),
      chapterIndex: Value(chapterIndex),
      chapterPos: Value(chapterPos),
      chapterName:
          chapterName == null && nullToAbsent
              ? const Value.absent()
              : Value(chapterName),
      bookUrl: Value(bookUrl),
      bookText:
          bookText == null && nullToAbsent
              ? const Value.absent()
              : Value(bookText),
      content:
          content == null && nullToAbsent
              ? const Value.absent()
              : Value(content),
    );
  }

  factory BookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      id: serializer.fromJson<int>(json['id']),
      time: serializer.fromJson<int>(json['time']),
      bookName: serializer.fromJson<String>(json['bookName']),
      bookAuthor: serializer.fromJson<String?>(json['bookAuthor']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      chapterPos: serializer.fromJson<int>(json['chapterPos']),
      chapterName: serializer.fromJson<String?>(json['chapterName']),
      bookUrl: serializer.fromJson<String>(json['bookUrl']),
      bookText: serializer.fromJson<String?>(json['bookText']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'time': serializer.toJson<int>(time),
      'bookName': serializer.toJson<String>(bookName),
      'bookAuthor': serializer.toJson<String?>(bookAuthor),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'chapterPos': serializer.toJson<int>(chapterPos),
      'chapterName': serializer.toJson<String?>(chapterName),
      'bookUrl': serializer.toJson<String>(bookUrl),
      'bookText': serializer.toJson<String?>(bookText),
      'content': serializer.toJson<String?>(content),
    };
  }

  BookmarkRow copyWith({
    int? id,
    int? time,
    String? bookName,
    Value<String?> bookAuthor = const Value.absent(),
    int? chapterIndex,
    int? chapterPos,
    Value<String?> chapterName = const Value.absent(),
    String? bookUrl,
    Value<String?> bookText = const Value.absent(),
    Value<String?> content = const Value.absent(),
  }) => BookmarkRow(
    id: id ?? this.id,
    time: time ?? this.time,
    bookName: bookName ?? this.bookName,
    bookAuthor: bookAuthor.present ? bookAuthor.value : this.bookAuthor,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    chapterPos: chapterPos ?? this.chapterPos,
    chapterName: chapterName.present ? chapterName.value : this.chapterName,
    bookUrl: bookUrl ?? this.bookUrl,
    bookText: bookText.present ? bookText.value : this.bookText,
    content: content.present ? content.value : this.content,
  );
  BookmarkRow copyWithCompanion(BookmarksCompanion data) {
    return BookmarkRow(
      id: data.id.present ? data.id.value : this.id,
      time: data.time.present ? data.time.value : this.time,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      bookAuthor:
          data.bookAuthor.present ? data.bookAuthor.value : this.bookAuthor,
      chapterIndex:
          data.chapterIndex.present
              ? data.chapterIndex.value
              : this.chapterIndex,
      chapterPos:
          data.chapterPos.present ? data.chapterPos.value : this.chapterPos,
      chapterName:
          data.chapterName.present ? data.chapterName.value : this.chapterName,
      bookUrl: data.bookUrl.present ? data.bookUrl.value : this.bookUrl,
      bookText: data.bookText.present ? data.bookText.value : this.bookText,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('id: $id, ')
          ..write('time: $time, ')
          ..write('bookName: $bookName, ')
          ..write('bookAuthor: $bookAuthor, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('chapterPos: $chapterPos, ')
          ..write('chapterName: $chapterName, ')
          ..write('bookUrl: $bookUrl, ')
          ..write('bookText: $bookText, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    time,
    bookName,
    bookAuthor,
    chapterIndex,
    chapterPos,
    chapterName,
    bookUrl,
    bookText,
    content,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.id == this.id &&
          other.time == this.time &&
          other.bookName == this.bookName &&
          other.bookAuthor == this.bookAuthor &&
          other.chapterIndex == this.chapterIndex &&
          other.chapterPos == this.chapterPos &&
          other.chapterName == this.chapterName &&
          other.bookUrl == this.bookUrl &&
          other.bookText == this.bookText &&
          other.content == this.content);
}

class BookmarksCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<int> id;
  final Value<int> time;
  final Value<String> bookName;
  final Value<String?> bookAuthor;
  final Value<int> chapterIndex;
  final Value<int> chapterPos;
  final Value<String?> chapterName;
  final Value<String> bookUrl;
  final Value<String?> bookText;
  final Value<String?> content;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.time = const Value.absent(),
    this.bookName = const Value.absent(),
    this.bookAuthor = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.chapterPos = const Value.absent(),
    this.chapterName = const Value.absent(),
    this.bookUrl = const Value.absent(),
    this.bookText = const Value.absent(),
    this.content = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int time,
    required String bookName,
    this.bookAuthor = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.chapterPos = const Value.absent(),
    this.chapterName = const Value.absent(),
    required String bookUrl,
    this.bookText = const Value.absent(),
    this.content = const Value.absent(),
  }) : time = Value(time),
       bookName = Value(bookName),
       bookUrl = Value(bookUrl);
  static Insertable<BookmarkRow> custom({
    Expression<int>? id,
    Expression<int>? time,
    Expression<String>? bookName,
    Expression<String>? bookAuthor,
    Expression<int>? chapterIndex,
    Expression<int>? chapterPos,
    Expression<String>? chapterName,
    Expression<String>? bookUrl,
    Expression<String>? bookText,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (time != null) 'time': time,
      if (bookName != null) 'bookName': bookName,
      if (bookAuthor != null) 'bookAuthor': bookAuthor,
      if (chapterIndex != null) 'chapterIndex': chapterIndex,
      if (chapterPos != null) 'chapterPos': chapterPos,
      if (chapterName != null) 'chapterName': chapterName,
      if (bookUrl != null) 'bookUrl': bookUrl,
      if (bookText != null) 'bookText': bookText,
      if (content != null) 'content': content,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int>? time,
    Value<String>? bookName,
    Value<String?>? bookAuthor,
    Value<int>? chapterIndex,
    Value<int>? chapterPos,
    Value<String?>? chapterName,
    Value<String>? bookUrl,
    Value<String?>? bookText,
    Value<String?>? content,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      time: time ?? this.time,
      bookName: bookName ?? this.bookName,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterPos: chapterPos ?? this.chapterPos,
      chapterName: chapterName ?? this.chapterName,
      bookUrl: bookUrl ?? this.bookUrl,
      bookText: bookText ?? this.bookText,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (bookName.present) {
      map['bookName'] = Variable<String>(bookName.value);
    }
    if (bookAuthor.present) {
      map['bookAuthor'] = Variable<String>(bookAuthor.value);
    }
    if (chapterIndex.present) {
      map['chapterIndex'] = Variable<int>(chapterIndex.value);
    }
    if (chapterPos.present) {
      map['chapterPos'] = Variable<int>(chapterPos.value);
    }
    if (chapterName.present) {
      map['chapterName'] = Variable<String>(chapterName.value);
    }
    if (bookUrl.present) {
      map['bookUrl'] = Variable<String>(bookUrl.value);
    }
    if (bookText.present) {
      map['bookText'] = Variable<String>(bookText.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('time: $time, ')
          ..write('bookName: $bookName, ')
          ..write('bookAuthor: $bookAuthor, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('chapterPos: $chapterPos, ')
          ..write('chapterName: $chapterName, ')
          ..write('bookUrl: $bookUrl, ')
          ..write('bookText: $bookText, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $CookiesTable extends Cookies with TableInfo<$CookiesTable, CookieRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CookiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cookieMeta = const VerificationMeta('cookie');
  @override
  late final GeneratedColumn<String> cookie = GeneratedColumn<String>(
    'cookie',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [url, cookie];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cookies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CookieRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('cookie')) {
      context.handle(
        _cookieMeta,
        cookie.isAcceptableOrUnknown(data['cookie']!, _cookieMeta),
      );
    } else if (isInserting) {
      context.missing(_cookieMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  CookieRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CookieRow(
      url:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}url'],
          )!,
      cookie:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}cookie'],
          )!,
    );
  }

  @override
  $CookiesTable createAlias(String alias) {
    return $CookiesTable(attachedDatabase, alias);
  }
}

class CookieRow extends DataClass implements Insertable<CookieRow> {
  final String url;
  final String cookie;
  const CookieRow({required this.url, required this.cookie});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['cookie'] = Variable<String>(cookie);
    return map;
  }

  CookiesCompanion toCompanion(bool nullToAbsent) {
    return CookiesCompanion(url: Value(url), cookie: Value(cookie));
  }

  factory CookieRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CookieRow(
      url: serializer.fromJson<String>(json['url']),
      cookie: serializer.fromJson<String>(json['cookie']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'cookie': serializer.toJson<String>(cookie),
    };
  }

  CookieRow copyWith({String? url, String? cookie}) =>
      CookieRow(url: url ?? this.url, cookie: cookie ?? this.cookie);
  CookieRow copyWithCompanion(CookiesCompanion data) {
    return CookieRow(
      url: data.url.present ? data.url.value : this.url,
      cookie: data.cookie.present ? data.cookie.value : this.cookie,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CookieRow(')
          ..write('url: $url, ')
          ..write('cookie: $cookie')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(url, cookie);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CookieRow &&
          other.url == this.url &&
          other.cookie == this.cookie);
}

class CookiesCompanion extends UpdateCompanion<CookieRow> {
  final Value<String> url;
  final Value<String> cookie;
  final Value<int> rowid;
  const CookiesCompanion({
    this.url = const Value.absent(),
    this.cookie = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CookiesCompanion.insert({
    required String url,
    required String cookie,
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       cookie = Value(cookie);
  static Insertable<CookieRow> custom({
    Expression<String>? url,
    Expression<String>? cookie,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (cookie != null) 'cookie': cookie,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CookiesCompanion copyWith({
    Value<String>? url,
    Value<String>? cookie,
    Value<int>? rowid,
  }) {
    return CookiesCompanion(
      url: url ?? this.url,
      cookie: cookie ?? this.cookie,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (cookie.present) {
      map['cookie'] = Variable<String>(cookie.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CookiesCompanion(')
          ..write('url: $url, ')
          ..write('cookie: $cookie, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictRulesTable extends DictRules
    with TableInfo<$DictRulesTable, DictRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlRuleMeta = const VerificationMeta(
    'urlRule',
  );
  @override
  late final GeneratedColumn<String> urlRule = GeneratedColumn<String>(
    'urlRule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showRuleMeta = const VerificationMeta(
    'showRule',
  );
  @override
  late final GeneratedColumn<String> showRule = GeneratedColumn<String>(
    'showRule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sortNumberMeta = const VerificationMeta(
    'sortNumber',
  );
  @override
  late final GeneratedColumn<int> sortNumber = GeneratedColumn<int>(
    'sortNumber',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    urlRule,
    showRule,
    enabled,
    sortNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dict_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('urlRule')) {
      context.handle(
        _urlRuleMeta,
        urlRule.isAcceptableOrUnknown(data['urlRule']!, _urlRuleMeta),
      );
    }
    if (data.containsKey('showRule')) {
      context.handle(
        _showRuleMeta,
        showRule.isAcceptableOrUnknown(data['showRule']!, _showRuleMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('sortNumber')) {
      context.handle(
        _sortNumberMeta,
        sortNumber.isAcceptableOrUnknown(data['sortNumber']!, _sortNumberMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictRuleRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      urlRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urlRule'],
      ),
      showRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}showRule'],
      ),
      enabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabled'],
          )!,
      sortNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sortNumber'],
          )!,
    );
  }

  @override
  $DictRulesTable createAlias(String alias) {
    return $DictRulesTable(attachedDatabase, alias);
  }
}

class DictRuleRow extends DataClass implements Insertable<DictRuleRow> {
  final int id;
  final String name;
  final String? urlRule;
  final String? showRule;
  final int enabled;
  final int sortNumber;
  const DictRuleRow({
    required this.id,
    required this.name,
    this.urlRule,
    this.showRule,
    required this.enabled,
    required this.sortNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || urlRule != null) {
      map['urlRule'] = Variable<String>(urlRule);
    }
    if (!nullToAbsent || showRule != null) {
      map['showRule'] = Variable<String>(showRule);
    }
    map['enabled'] = Variable<int>(enabled);
    map['sortNumber'] = Variable<int>(sortNumber);
    return map;
  }

  DictRulesCompanion toCompanion(bool nullToAbsent) {
    return DictRulesCompanion(
      id: Value(id),
      name: Value(name),
      urlRule:
          urlRule == null && nullToAbsent
              ? const Value.absent()
              : Value(urlRule),
      showRule:
          showRule == null && nullToAbsent
              ? const Value.absent()
              : Value(showRule),
      enabled: Value(enabled),
      sortNumber: Value(sortNumber),
    );
  }

  factory DictRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictRuleRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      urlRule: serializer.fromJson<String?>(json['urlRule']),
      showRule: serializer.fromJson<String?>(json['showRule']),
      enabled: serializer.fromJson<int>(json['enabled']),
      sortNumber: serializer.fromJson<int>(json['sortNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'urlRule': serializer.toJson<String?>(urlRule),
      'showRule': serializer.toJson<String?>(showRule),
      'enabled': serializer.toJson<int>(enabled),
      'sortNumber': serializer.toJson<int>(sortNumber),
    };
  }

  DictRuleRow copyWith({
    int? id,
    String? name,
    Value<String?> urlRule = const Value.absent(),
    Value<String?> showRule = const Value.absent(),
    int? enabled,
    int? sortNumber,
  }) => DictRuleRow(
    id: id ?? this.id,
    name: name ?? this.name,
    urlRule: urlRule.present ? urlRule.value : this.urlRule,
    showRule: showRule.present ? showRule.value : this.showRule,
    enabled: enabled ?? this.enabled,
    sortNumber: sortNumber ?? this.sortNumber,
  );
  DictRuleRow copyWithCompanion(DictRulesCompanion data) {
    return DictRuleRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      urlRule: data.urlRule.present ? data.urlRule.value : this.urlRule,
      showRule: data.showRule.present ? data.showRule.value : this.showRule,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sortNumber:
          data.sortNumber.present ? data.sortNumber.value : this.sortNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictRuleRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('urlRule: $urlRule, ')
          ..write('showRule: $showRule, ')
          ..write('enabled: $enabled, ')
          ..write('sortNumber: $sortNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, urlRule, showRule, enabled, sortNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictRuleRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.urlRule == this.urlRule &&
          other.showRule == this.showRule &&
          other.enabled == this.enabled &&
          other.sortNumber == this.sortNumber);
}

class DictRulesCompanion extends UpdateCompanion<DictRuleRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> urlRule;
  final Value<String?> showRule;
  final Value<int> enabled;
  final Value<int> sortNumber;
  const DictRulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.urlRule = const Value.absent(),
    this.showRule = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortNumber = const Value.absent(),
  });
  DictRulesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.urlRule = const Value.absent(),
    this.showRule = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortNumber = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DictRuleRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? urlRule,
    Expression<String>? showRule,
    Expression<int>? enabled,
    Expression<int>? sortNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (urlRule != null) 'urlRule': urlRule,
      if (showRule != null) 'showRule': showRule,
      if (enabled != null) 'enabled': enabled,
      if (sortNumber != null) 'sortNumber': sortNumber,
    });
  }

  DictRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? urlRule,
    Value<String?>? showRule,
    Value<int>? enabled,
    Value<int>? sortNumber,
  }) {
    return DictRulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      urlRule: urlRule ?? this.urlRule,
      showRule: showRule ?? this.showRule,
      enabled: enabled ?? this.enabled,
      sortNumber: sortNumber ?? this.sortNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (urlRule.present) {
      map['urlRule'] = Variable<String>(urlRule.value);
    }
    if (showRule.present) {
      map['showRule'] = Variable<String>(showRule.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<int>(enabled.value);
    }
    if (sortNumber.present) {
      map['sortNumber'] = Variable<int>(sortNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictRulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('urlRule: $urlRule, ')
          ..write('showRule: $showRule, ')
          ..write('enabled: $enabled, ')
          ..write('sortNumber: $sortNumber')
          ..write(')'))
        .toString();
  }
}

class $HttpTtsTable extends HttpTts with TableInfo<$HttpTtsTable, HttpTtsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HttpTtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'contentType',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _concurrentRateMeta = const VerificationMeta(
    'concurrentRate',
  );
  @override
  late final GeneratedColumn<String> concurrentRate = GeneratedColumn<String>(
    'concurrentRate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginUrlMeta = const VerificationMeta(
    'loginUrl',
  );
  @override
  late final GeneratedColumn<String> loginUrl = GeneratedColumn<String>(
    'loginUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginUiMeta = const VerificationMeta(
    'loginUi',
  );
  @override
  late final GeneratedColumn<String> loginUi = GeneratedColumn<String>(
    'loginUi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headerMeta = const VerificationMeta('header');
  @override
  late final GeneratedColumn<String> header = GeneratedColumn<String>(
    'header',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsLibMeta = const VerificationMeta('jsLib');
  @override
  late final GeneratedColumn<String> jsLib = GeneratedColumn<String>(
    'jsLib',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledCookieJarMeta = const VerificationMeta(
    'enabledCookieJar',
  );
  @override
  late final GeneratedColumn<int> enabledCookieJar = GeneratedColumn<int>(
    'enabledCookieJar',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _loginCheckJsMeta = const VerificationMeta(
    'loginCheckJs',
  );
  @override
  late final GeneratedColumn<String> loginCheckJs = GeneratedColumn<String>(
    'loginCheckJs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdateTimeMeta = const VerificationMeta(
    'lastUpdateTime',
  );
  @override
  late final GeneratedColumn<int> lastUpdateTime = GeneratedColumn<int>(
    'lastUpdateTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    url,
    contentType,
    concurrentRate,
    loginUrl,
    loginUi,
    header,
    jsLib,
    enabledCookieJar,
    loginCheckJs,
    lastUpdateTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'http_tts';
  @override
  VerificationContext validateIntegrity(
    Insertable<HttpTtsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('contentType')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['contentType']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('concurrentRate')) {
      context.handle(
        _concurrentRateMeta,
        concurrentRate.isAcceptableOrUnknown(
          data['concurrentRate']!,
          _concurrentRateMeta,
        ),
      );
    }
    if (data.containsKey('loginUrl')) {
      context.handle(
        _loginUrlMeta,
        loginUrl.isAcceptableOrUnknown(data['loginUrl']!, _loginUrlMeta),
      );
    }
    if (data.containsKey('loginUi')) {
      context.handle(
        _loginUiMeta,
        loginUi.isAcceptableOrUnknown(data['loginUi']!, _loginUiMeta),
      );
    }
    if (data.containsKey('header')) {
      context.handle(
        _headerMeta,
        header.isAcceptableOrUnknown(data['header']!, _headerMeta),
      );
    }
    if (data.containsKey('jsLib')) {
      context.handle(
        _jsLibMeta,
        jsLib.isAcceptableOrUnknown(data['jsLib']!, _jsLibMeta),
      );
    }
    if (data.containsKey('enabledCookieJar')) {
      context.handle(
        _enabledCookieJarMeta,
        enabledCookieJar.isAcceptableOrUnknown(
          data['enabledCookieJar']!,
          _enabledCookieJarMeta,
        ),
      );
    }
    if (data.containsKey('loginCheckJs')) {
      context.handle(
        _loginCheckJsMeta,
        loginCheckJs.isAcceptableOrUnknown(
          data['loginCheckJs']!,
          _loginCheckJsMeta,
        ),
      );
    }
    if (data.containsKey('lastUpdateTime')) {
      context.handle(
        _lastUpdateTimeMeta,
        lastUpdateTime.isAcceptableOrUnknown(
          data['lastUpdateTime']!,
          _lastUpdateTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HttpTtsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HttpTtsRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      url:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}url'],
          )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contentType'],
      ),
      concurrentRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concurrentRate'],
      ),
      loginUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginUrl'],
      ),
      loginUi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginUi'],
      ),
      header: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header'],
      ),
      jsLib: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jsLib'],
      ),
      enabledCookieJar:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabledCookieJar'],
          )!,
      loginCheckJs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginCheckJs'],
      ),
      lastUpdateTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}lastUpdateTime'],
          )!,
    );
  }

  @override
  $HttpTtsTable createAlias(String alias) {
    return $HttpTtsTable(attachedDatabase, alias);
  }
}

class HttpTtsRow extends DataClass implements Insertable<HttpTtsRow> {
  final int id;
  final String name;
  final String url;
  final String? contentType;
  final String? concurrentRate;
  final String? loginUrl;
  final String? loginUi;
  final String? header;
  final String? jsLib;
  final int enabledCookieJar;
  final String? loginCheckJs;
  final int lastUpdateTime;
  const HttpTtsRow({
    required this.id,
    required this.name,
    required this.url,
    this.contentType,
    this.concurrentRate,
    this.loginUrl,
    this.loginUi,
    this.header,
    this.jsLib,
    required this.enabledCookieJar,
    this.loginCheckJs,
    required this.lastUpdateTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || contentType != null) {
      map['contentType'] = Variable<String>(contentType);
    }
    if (!nullToAbsent || concurrentRate != null) {
      map['concurrentRate'] = Variable<String>(concurrentRate);
    }
    if (!nullToAbsent || loginUrl != null) {
      map['loginUrl'] = Variable<String>(loginUrl);
    }
    if (!nullToAbsent || loginUi != null) {
      map['loginUi'] = Variable<String>(loginUi);
    }
    if (!nullToAbsent || header != null) {
      map['header'] = Variable<String>(header);
    }
    if (!nullToAbsent || jsLib != null) {
      map['jsLib'] = Variable<String>(jsLib);
    }
    map['enabledCookieJar'] = Variable<int>(enabledCookieJar);
    if (!nullToAbsent || loginCheckJs != null) {
      map['loginCheckJs'] = Variable<String>(loginCheckJs);
    }
    map['lastUpdateTime'] = Variable<int>(lastUpdateTime);
    return map;
  }

  HttpTtsCompanion toCompanion(bool nullToAbsent) {
    return HttpTtsCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      contentType:
          contentType == null && nullToAbsent
              ? const Value.absent()
              : Value(contentType),
      concurrentRate:
          concurrentRate == null && nullToAbsent
              ? const Value.absent()
              : Value(concurrentRate),
      loginUrl:
          loginUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(loginUrl),
      loginUi:
          loginUi == null && nullToAbsent
              ? const Value.absent()
              : Value(loginUi),
      header:
          header == null && nullToAbsent ? const Value.absent() : Value(header),
      jsLib:
          jsLib == null && nullToAbsent ? const Value.absent() : Value(jsLib),
      enabledCookieJar: Value(enabledCookieJar),
      loginCheckJs:
          loginCheckJs == null && nullToAbsent
              ? const Value.absent()
              : Value(loginCheckJs),
      lastUpdateTime: Value(lastUpdateTime),
    );
  }

  factory HttpTtsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HttpTtsRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      contentType: serializer.fromJson<String?>(json['contentType']),
      concurrentRate: serializer.fromJson<String?>(json['concurrentRate']),
      loginUrl: serializer.fromJson<String?>(json['loginUrl']),
      loginUi: serializer.fromJson<String?>(json['loginUi']),
      header: serializer.fromJson<String?>(json['header']),
      jsLib: serializer.fromJson<String?>(json['jsLib']),
      enabledCookieJar: serializer.fromJson<int>(json['enabledCookieJar']),
      loginCheckJs: serializer.fromJson<String?>(json['loginCheckJs']),
      lastUpdateTime: serializer.fromJson<int>(json['lastUpdateTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'contentType': serializer.toJson<String?>(contentType),
      'concurrentRate': serializer.toJson<String?>(concurrentRate),
      'loginUrl': serializer.toJson<String?>(loginUrl),
      'loginUi': serializer.toJson<String?>(loginUi),
      'header': serializer.toJson<String?>(header),
      'jsLib': serializer.toJson<String?>(jsLib),
      'enabledCookieJar': serializer.toJson<int>(enabledCookieJar),
      'loginCheckJs': serializer.toJson<String?>(loginCheckJs),
      'lastUpdateTime': serializer.toJson<int>(lastUpdateTime),
    };
  }

  HttpTtsRow copyWith({
    int? id,
    String? name,
    String? url,
    Value<String?> contentType = const Value.absent(),
    Value<String?> concurrentRate = const Value.absent(),
    Value<String?> loginUrl = const Value.absent(),
    Value<String?> loginUi = const Value.absent(),
    Value<String?> header = const Value.absent(),
    Value<String?> jsLib = const Value.absent(),
    int? enabledCookieJar,
    Value<String?> loginCheckJs = const Value.absent(),
    int? lastUpdateTime,
  }) => HttpTtsRow(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    contentType: contentType.present ? contentType.value : this.contentType,
    concurrentRate:
        concurrentRate.present ? concurrentRate.value : this.concurrentRate,
    loginUrl: loginUrl.present ? loginUrl.value : this.loginUrl,
    loginUi: loginUi.present ? loginUi.value : this.loginUi,
    header: header.present ? header.value : this.header,
    jsLib: jsLib.present ? jsLib.value : this.jsLib,
    enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
    loginCheckJs: loginCheckJs.present ? loginCheckJs.value : this.loginCheckJs,
    lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
  );
  HttpTtsRow copyWithCompanion(HttpTtsCompanion data) {
    return HttpTtsRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      concurrentRate:
          data.concurrentRate.present
              ? data.concurrentRate.value
              : this.concurrentRate,
      loginUrl: data.loginUrl.present ? data.loginUrl.value : this.loginUrl,
      loginUi: data.loginUi.present ? data.loginUi.value : this.loginUi,
      header: data.header.present ? data.header.value : this.header,
      jsLib: data.jsLib.present ? data.jsLib.value : this.jsLib,
      enabledCookieJar:
          data.enabledCookieJar.present
              ? data.enabledCookieJar.value
              : this.enabledCookieJar,
      loginCheckJs:
          data.loginCheckJs.present
              ? data.loginCheckJs.value
              : this.loginCheckJs,
      lastUpdateTime:
          data.lastUpdateTime.present
              ? data.lastUpdateTime.value
              : this.lastUpdateTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HttpTtsRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('contentType: $contentType, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('loginUi: $loginUi, ')
          ..write('header: $header, ')
          ..write('jsLib: $jsLib, ')
          ..write('enabledCookieJar: $enabledCookieJar, ')
          ..write('loginCheckJs: $loginCheckJs, ')
          ..write('lastUpdateTime: $lastUpdateTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    url,
    contentType,
    concurrentRate,
    loginUrl,
    loginUi,
    header,
    jsLib,
    enabledCookieJar,
    loginCheckJs,
    lastUpdateTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HttpTtsRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.contentType == this.contentType &&
          other.concurrentRate == this.concurrentRate &&
          other.loginUrl == this.loginUrl &&
          other.loginUi == this.loginUi &&
          other.header == this.header &&
          other.jsLib == this.jsLib &&
          other.enabledCookieJar == this.enabledCookieJar &&
          other.loginCheckJs == this.loginCheckJs &&
          other.lastUpdateTime == this.lastUpdateTime);
}

class HttpTtsCompanion extends UpdateCompanion<HttpTtsRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> contentType;
  final Value<String?> concurrentRate;
  final Value<String?> loginUrl;
  final Value<String?> loginUi;
  final Value<String?> header;
  final Value<String?> jsLib;
  final Value<int> enabledCookieJar;
  final Value<String?> loginCheckJs;
  final Value<int> lastUpdateTime;
  const HttpTtsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.contentType = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.loginUi = const Value.absent(),
    this.header = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.enabledCookieJar = const Value.absent(),
    this.loginCheckJs = const Value.absent(),
    this.lastUpdateTime = const Value.absent(),
  });
  HttpTtsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String url,
    this.contentType = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.loginUi = const Value.absent(),
    this.header = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.enabledCookieJar = const Value.absent(),
    this.loginCheckJs = const Value.absent(),
    this.lastUpdateTime = const Value.absent(),
  }) : name = Value(name),
       url = Value(url);
  static Insertable<HttpTtsRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? contentType,
    Expression<String>? concurrentRate,
    Expression<String>? loginUrl,
    Expression<String>? loginUi,
    Expression<String>? header,
    Expression<String>? jsLib,
    Expression<int>? enabledCookieJar,
    Expression<String>? loginCheckJs,
    Expression<int>? lastUpdateTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (contentType != null) 'contentType': contentType,
      if (concurrentRate != null) 'concurrentRate': concurrentRate,
      if (loginUrl != null) 'loginUrl': loginUrl,
      if (loginUi != null) 'loginUi': loginUi,
      if (header != null) 'header': header,
      if (jsLib != null) 'jsLib': jsLib,
      if (enabledCookieJar != null) 'enabledCookieJar': enabledCookieJar,
      if (loginCheckJs != null) 'loginCheckJs': loginCheckJs,
      if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime,
    });
  }

  HttpTtsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? url,
    Value<String?>? contentType,
    Value<String?>? concurrentRate,
    Value<String?>? loginUrl,
    Value<String?>? loginUi,
    Value<String?>? header,
    Value<String?>? jsLib,
    Value<int>? enabledCookieJar,
    Value<String?>? loginCheckJs,
    Value<int>? lastUpdateTime,
  }) {
    return HttpTtsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      contentType: contentType ?? this.contentType,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi ?? this.loginUi,
      header: header ?? this.header,
      jsLib: jsLib ?? this.jsLib,
      enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
      loginCheckJs: loginCheckJs ?? this.loginCheckJs,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (contentType.present) {
      map['contentType'] = Variable<String>(contentType.value);
    }
    if (concurrentRate.present) {
      map['concurrentRate'] = Variable<String>(concurrentRate.value);
    }
    if (loginUrl.present) {
      map['loginUrl'] = Variable<String>(loginUrl.value);
    }
    if (loginUi.present) {
      map['loginUi'] = Variable<String>(loginUi.value);
    }
    if (header.present) {
      map['header'] = Variable<String>(header.value);
    }
    if (jsLib.present) {
      map['jsLib'] = Variable<String>(jsLib.value);
    }
    if (enabledCookieJar.present) {
      map['enabledCookieJar'] = Variable<int>(enabledCookieJar.value);
    }
    if (loginCheckJs.present) {
      map['loginCheckJs'] = Variable<String>(loginCheckJs.value);
    }
    if (lastUpdateTime.present) {
      map['lastUpdateTime'] = Variable<int>(lastUpdateTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HttpTtsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('contentType: $contentType, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('loginUi: $loginUi, ')
          ..write('header: $header, ')
          ..write('jsLib: $jsLib, ')
          ..write('enabledCookieJar: $enabledCookieJar, ')
          ..write('loginCheckJs: $loginCheckJs, ')
          ..write('lastUpdateTime: $lastUpdateTime')
          ..write(')'))
        .toString();
  }
}

class $ReadRecordsTable extends ReadRecords
    with TableInfo<$ReadRecordsTable, ReadRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'bookName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'deviceId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readTimeMeta = const VerificationMeta(
    'readTime',
  );
  @override
  late final GeneratedColumn<int> readTime = GeneratedColumn<int>(
    'readTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReadMeta = const VerificationMeta(
    'lastRead',
  );
  @override
  late final GeneratedColumn<int> lastRead = GeneratedColumn<int>(
    'lastRead',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookName,
    deviceId,
    readTime,
    lastRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bookName')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['bookName']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('deviceId')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['deviceId']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('readTime')) {
      context.handle(
        _readTimeMeta,
        readTime.isAcceptableOrUnknown(data['readTime']!, _readTimeMeta),
      );
    }
    if (data.containsKey('lastRead')) {
      context.handle(
        _lastReadMeta,
        lastRead.isAcceptableOrUnknown(data['lastRead']!, _lastReadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadRecordRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      bookName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookName'],
          )!,
      deviceId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}deviceId'],
          )!,
      readTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}readTime'],
          )!,
      lastRead:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}lastRead'],
          )!,
    );
  }

  @override
  $ReadRecordsTable createAlias(String alias) {
    return $ReadRecordsTable(attachedDatabase, alias);
  }
}

class ReadRecordRow extends DataClass implements Insertable<ReadRecordRow> {
  final int id;
  final String bookName;
  final String deviceId;
  final int readTime;
  final int lastRead;
  const ReadRecordRow({
    required this.id,
    required this.bookName,
    required this.deviceId,
    required this.readTime,
    required this.lastRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bookName'] = Variable<String>(bookName);
    map['deviceId'] = Variable<String>(deviceId);
    map['readTime'] = Variable<int>(readTime);
    map['lastRead'] = Variable<int>(lastRead);
    return map;
  }

  ReadRecordsCompanion toCompanion(bool nullToAbsent) {
    return ReadRecordsCompanion(
      id: Value(id),
      bookName: Value(bookName),
      deviceId: Value(deviceId),
      readTime: Value(readTime),
      lastRead: Value(lastRead),
    );
  }

  factory ReadRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadRecordRow(
      id: serializer.fromJson<int>(json['id']),
      bookName: serializer.fromJson<String>(json['bookName']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      readTime: serializer.fromJson<int>(json['readTime']),
      lastRead: serializer.fromJson<int>(json['lastRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookName': serializer.toJson<String>(bookName),
      'deviceId': serializer.toJson<String>(deviceId),
      'readTime': serializer.toJson<int>(readTime),
      'lastRead': serializer.toJson<int>(lastRead),
    };
  }

  ReadRecordRow copyWith({
    int? id,
    String? bookName,
    String? deviceId,
    int? readTime,
    int? lastRead,
  }) => ReadRecordRow(
    id: id ?? this.id,
    bookName: bookName ?? this.bookName,
    deviceId: deviceId ?? this.deviceId,
    readTime: readTime ?? this.readTime,
    lastRead: lastRead ?? this.lastRead,
  );
  ReadRecordRow copyWithCompanion(ReadRecordsCompanion data) {
    return ReadRecordRow(
      id: data.id.present ? data.id.value : this.id,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      readTime: data.readTime.present ? data.readTime.value : this.readTime,
      lastRead: data.lastRead.present ? data.lastRead.value : this.lastRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadRecordRow(')
          ..write('id: $id, ')
          ..write('bookName: $bookName, ')
          ..write('deviceId: $deviceId, ')
          ..write('readTime: $readTime, ')
          ..write('lastRead: $lastRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookName, deviceId, readTime, lastRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadRecordRow &&
          other.id == this.id &&
          other.bookName == this.bookName &&
          other.deviceId == this.deviceId &&
          other.readTime == this.readTime &&
          other.lastRead == this.lastRead);
}

class ReadRecordsCompanion extends UpdateCompanion<ReadRecordRow> {
  final Value<int> id;
  final Value<String> bookName;
  final Value<String> deviceId;
  final Value<int> readTime;
  final Value<int> lastRead;
  const ReadRecordsCompanion({
    this.id = const Value.absent(),
    this.bookName = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.readTime = const Value.absent(),
    this.lastRead = const Value.absent(),
  });
  ReadRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String bookName,
    required String deviceId,
    this.readTime = const Value.absent(),
    this.lastRead = const Value.absent(),
  }) : bookName = Value(bookName),
       deviceId = Value(deviceId);
  static Insertable<ReadRecordRow> custom({
    Expression<int>? id,
    Expression<String>? bookName,
    Expression<String>? deviceId,
    Expression<int>? readTime,
    Expression<int>? lastRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookName != null) 'bookName': bookName,
      if (deviceId != null) 'deviceId': deviceId,
      if (readTime != null) 'readTime': readTime,
      if (lastRead != null) 'lastRead': lastRead,
    });
  }

  ReadRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? bookName,
    Value<String>? deviceId,
    Value<int>? readTime,
    Value<int>? lastRead,
  }) {
    return ReadRecordsCompanion(
      id: id ?? this.id,
      bookName: bookName ?? this.bookName,
      deviceId: deviceId ?? this.deviceId,
      readTime: readTime ?? this.readTime,
      lastRead: lastRead ?? this.lastRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookName.present) {
      map['bookName'] = Variable<String>(bookName.value);
    }
    if (deviceId.present) {
      map['deviceId'] = Variable<String>(deviceId.value);
    }
    if (readTime.present) {
      map['readTime'] = Variable<int>(readTime.value);
    }
    if (lastRead.present) {
      map['lastRead'] = Variable<int>(lastRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadRecordsCompanion(')
          ..write('id: $id, ')
          ..write('bookName: $bookName, ')
          ..write('deviceId: $deviceId, ')
          ..write('readTime: $readTime, ')
          ..write('lastRead: $lastRead')
          ..write(')'))
        .toString();
  }
}

class $RssArticlesTable extends RssArticles
    with TableInfo<$RssArticlesTable, RssArticleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<String> sort = GeneratedColumn<String>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pubDateMeta = const VerificationMeta(
    'pubDate',
  );
  @override
  late final GeneratedColumn<String> pubDate = GeneratedColumn<String>(
    'pubDate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
    'image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
    'group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readMeta = const VerificationMeta('read');
  @override
  late final GeneratedColumn<int> read = GeneratedColumn<int>(
    'read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _variableMeta = const VerificationMeta(
    'variable',
  );
  @override
  late final GeneratedColumn<String> variable = GeneratedColumn<String>(
    'variable',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    link,
    origin,
    sort,
    title,
    order,
    pubDate,
    description,
    content,
    image,
    group,
    read,
    variable,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssArticleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    } else if (isInserting) {
      context.missing(_linkMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    } else if (isInserting) {
      context.missing(_sortMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('pubDate')) {
      context.handle(
        _pubDateMeta,
        pubDate.isAcceptableOrUnknown(data['pubDate']!, _pubDateMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('image')) {
      context.handle(
        _imageMeta,
        image.isAcceptableOrUnknown(data['image']!, _imageMeta),
      );
    }
    if (data.containsKey('group')) {
      context.handle(
        _groupMeta,
        group.isAcceptableOrUnknown(data['group']!, _groupMeta),
      );
    }
    if (data.containsKey('read')) {
      context.handle(
        _readMeta,
        read.isAcceptableOrUnknown(data['read']!, _readMeta),
      );
    }
    if (data.containsKey('variable')) {
      context.handle(
        _variableMeta,
        variable.isAcceptableOrUnknown(data['variable']!, _variableMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {link};
  @override
  RssArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssArticleRow(
      link:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}link'],
          )!,
      origin:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}origin'],
          )!,
      sort:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sort'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      order:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}order'],
          )!,
      pubDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubDate'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      image: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image'],
      ),
      group: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group'],
      ),
      read:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}read'],
          )!,
      variable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variable'],
      ),
    );
  }

  @override
  $RssArticlesTable createAlias(String alias) {
    return $RssArticlesTable(attachedDatabase, alias);
  }
}

class RssArticleRow extends DataClass implements Insertable<RssArticleRow> {
  final String link;
  final String origin;
  final String sort;
  final String title;
  final int order;
  final String? pubDate;
  final String? description;
  final String? content;
  final String? image;
  final String? group;
  final int read;
  final String? variable;
  const RssArticleRow({
    required this.link,
    required this.origin,
    required this.sort,
    required this.title,
    required this.order,
    this.pubDate,
    this.description,
    this.content,
    this.image,
    this.group,
    required this.read,
    this.variable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['link'] = Variable<String>(link);
    map['origin'] = Variable<String>(origin);
    map['sort'] = Variable<String>(sort);
    map['title'] = Variable<String>(title);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || pubDate != null) {
      map['pubDate'] = Variable<String>(pubDate);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    if (!nullToAbsent || group != null) {
      map['group'] = Variable<String>(group);
    }
    map['read'] = Variable<int>(read);
    if (!nullToAbsent || variable != null) {
      map['variable'] = Variable<String>(variable);
    }
    return map;
  }

  RssArticlesCompanion toCompanion(bool nullToAbsent) {
    return RssArticlesCompanion(
      link: Value(link),
      origin: Value(origin),
      sort: Value(sort),
      title: Value(title),
      order: Value(order),
      pubDate:
          pubDate == null && nullToAbsent
              ? const Value.absent()
              : Value(pubDate),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      content:
          content == null && nullToAbsent
              ? const Value.absent()
              : Value(content),
      image:
          image == null && nullToAbsent ? const Value.absent() : Value(image),
      group:
          group == null && nullToAbsent ? const Value.absent() : Value(group),
      read: Value(read),
      variable:
          variable == null && nullToAbsent
              ? const Value.absent()
              : Value(variable),
    );
  }

  factory RssArticleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssArticleRow(
      link: serializer.fromJson<String>(json['link']),
      origin: serializer.fromJson<String>(json['origin']),
      sort: serializer.fromJson<String>(json['sort']),
      title: serializer.fromJson<String>(json['title']),
      order: serializer.fromJson<int>(json['order']),
      pubDate: serializer.fromJson<String?>(json['pubDate']),
      description: serializer.fromJson<String?>(json['description']),
      content: serializer.fromJson<String?>(json['content']),
      image: serializer.fromJson<String?>(json['image']),
      group: serializer.fromJson<String?>(json['group']),
      read: serializer.fromJson<int>(json['read']),
      variable: serializer.fromJson<String?>(json['variable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'link': serializer.toJson<String>(link),
      'origin': serializer.toJson<String>(origin),
      'sort': serializer.toJson<String>(sort),
      'title': serializer.toJson<String>(title),
      'order': serializer.toJson<int>(order),
      'pubDate': serializer.toJson<String?>(pubDate),
      'description': serializer.toJson<String?>(description),
      'content': serializer.toJson<String?>(content),
      'image': serializer.toJson<String?>(image),
      'group': serializer.toJson<String?>(group),
      'read': serializer.toJson<int>(read),
      'variable': serializer.toJson<String?>(variable),
    };
  }

  RssArticleRow copyWith({
    String? link,
    String? origin,
    String? sort,
    String? title,
    int? order,
    Value<String?> pubDate = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> content = const Value.absent(),
    Value<String?> image = const Value.absent(),
    Value<String?> group = const Value.absent(),
    int? read,
    Value<String?> variable = const Value.absent(),
  }) => RssArticleRow(
    link: link ?? this.link,
    origin: origin ?? this.origin,
    sort: sort ?? this.sort,
    title: title ?? this.title,
    order: order ?? this.order,
    pubDate: pubDate.present ? pubDate.value : this.pubDate,
    description: description.present ? description.value : this.description,
    content: content.present ? content.value : this.content,
    image: image.present ? image.value : this.image,
    group: group.present ? group.value : this.group,
    read: read ?? this.read,
    variable: variable.present ? variable.value : this.variable,
  );
  RssArticleRow copyWithCompanion(RssArticlesCompanion data) {
    return RssArticleRow(
      link: data.link.present ? data.link.value : this.link,
      origin: data.origin.present ? data.origin.value : this.origin,
      sort: data.sort.present ? data.sort.value : this.sort,
      title: data.title.present ? data.title.value : this.title,
      order: data.order.present ? data.order.value : this.order,
      pubDate: data.pubDate.present ? data.pubDate.value : this.pubDate,
      description:
          data.description.present ? data.description.value : this.description,
      content: data.content.present ? data.content.value : this.content,
      image: data.image.present ? data.image.value : this.image,
      group: data.group.present ? data.group.value : this.group,
      read: data.read.present ? data.read.value : this.read,
      variable: data.variable.present ? data.variable.value : this.variable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssArticleRow(')
          ..write('link: $link, ')
          ..write('origin: $origin, ')
          ..write('sort: $sort, ')
          ..write('title: $title, ')
          ..write('order: $order, ')
          ..write('pubDate: $pubDate, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('image: $image, ')
          ..write('group: $group, ')
          ..write('read: $read, ')
          ..write('variable: $variable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    link,
    origin,
    sort,
    title,
    order,
    pubDate,
    description,
    content,
    image,
    group,
    read,
    variable,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssArticleRow &&
          other.link == this.link &&
          other.origin == this.origin &&
          other.sort == this.sort &&
          other.title == this.title &&
          other.order == this.order &&
          other.pubDate == this.pubDate &&
          other.description == this.description &&
          other.content == this.content &&
          other.image == this.image &&
          other.group == this.group &&
          other.read == this.read &&
          other.variable == this.variable);
}

class RssArticlesCompanion extends UpdateCompanion<RssArticleRow> {
  final Value<String> link;
  final Value<String> origin;
  final Value<String> sort;
  final Value<String> title;
  final Value<int> order;
  final Value<String?> pubDate;
  final Value<String?> description;
  final Value<String?> content;
  final Value<String?> image;
  final Value<String?> group;
  final Value<int> read;
  final Value<String?> variable;
  final Value<int> rowid;
  const RssArticlesCompanion({
    this.link = const Value.absent(),
    this.origin = const Value.absent(),
    this.sort = const Value.absent(),
    this.title = const Value.absent(),
    this.order = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.image = const Value.absent(),
    this.group = const Value.absent(),
    this.read = const Value.absent(),
    this.variable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssArticlesCompanion.insert({
    required String link,
    required String origin,
    required String sort,
    required String title,
    this.order = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.image = const Value.absent(),
    this.group = const Value.absent(),
    this.read = const Value.absent(),
    this.variable = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : link = Value(link),
       origin = Value(origin),
       sort = Value(sort),
       title = Value(title);
  static Insertable<RssArticleRow> custom({
    Expression<String>? link,
    Expression<String>? origin,
    Expression<String>? sort,
    Expression<String>? title,
    Expression<int>? order,
    Expression<String>? pubDate,
    Expression<String>? description,
    Expression<String>? content,
    Expression<String>? image,
    Expression<String>? group,
    Expression<int>? read,
    Expression<String>? variable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (link != null) 'link': link,
      if (origin != null) 'origin': origin,
      if (sort != null) 'sort': sort,
      if (title != null) 'title': title,
      if (order != null) 'order': order,
      if (pubDate != null) 'pubDate': pubDate,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (image != null) 'image': image,
      if (group != null) 'group': group,
      if (read != null) 'read': read,
      if (variable != null) 'variable': variable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssArticlesCompanion copyWith({
    Value<String>? link,
    Value<String>? origin,
    Value<String>? sort,
    Value<String>? title,
    Value<int>? order,
    Value<String?>? pubDate,
    Value<String?>? description,
    Value<String?>? content,
    Value<String?>? image,
    Value<String?>? group,
    Value<int>? read,
    Value<String?>? variable,
    Value<int>? rowid,
  }) {
    return RssArticlesCompanion(
      link: link ?? this.link,
      origin: origin ?? this.origin,
      sort: sort ?? this.sort,
      title: title ?? this.title,
      order: order ?? this.order,
      pubDate: pubDate ?? this.pubDate,
      description: description ?? this.description,
      content: content ?? this.content,
      image: image ?? this.image,
      group: group ?? this.group,
      read: read ?? this.read,
      variable: variable ?? this.variable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (sort.present) {
      map['sort'] = Variable<String>(sort.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (pubDate.present) {
      map['pubDate'] = Variable<String>(pubDate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(group.value);
    }
    if (read.present) {
      map['read'] = Variable<int>(read.value);
    }
    if (variable.present) {
      map['variable'] = Variable<String>(variable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssArticlesCompanion(')
          ..write('link: $link, ')
          ..write('origin: $origin, ')
          ..write('sort: $sort, ')
          ..write('title: $title, ')
          ..write('order: $order, ')
          ..write('pubDate: $pubDate, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('image: $image, ')
          ..write('group: $group, ')
          ..write('read: $read, ')
          ..write('variable: $variable, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssSourcesTable extends RssSources
    with TableInfo<$RssSourcesTable, RssSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'sourceUrl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'sourceName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIconMeta = const VerificationMeta(
    'sourceIcon',
  );
  @override
  late final GeneratedColumn<String> sourceIcon = GeneratedColumn<String>(
    'sourceIcon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceGroupMeta = const VerificationMeta(
    'sourceGroup',
  );
  @override
  late final GeneratedColumn<String> sourceGroup = GeneratedColumn<String>(
    'sourceGroup',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceCommentMeta = const VerificationMeta(
    'sourceComment',
  );
  @override
  late final GeneratedColumn<String> sourceComment = GeneratedColumn<String>(
    'sourceComment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _variableCommentMeta = const VerificationMeta(
    'variableComment',
  );
  @override
  late final GeneratedColumn<String> variableComment = GeneratedColumn<String>(
    'variableComment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsLibMeta = const VerificationMeta('jsLib');
  @override
  late final GeneratedColumn<String> jsLib = GeneratedColumn<String>(
    'jsLib',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledCookieJarMeta = const VerificationMeta(
    'enabledCookieJar',
  );
  @override
  late final GeneratedColumn<int> enabledCookieJar = GeneratedColumn<int>(
    'enabledCookieJar',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _concurrentRateMeta = const VerificationMeta(
    'concurrentRate',
  );
  @override
  late final GeneratedColumn<String> concurrentRate = GeneratedColumn<String>(
    'concurrentRate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headerMeta = const VerificationMeta('header');
  @override
  late final GeneratedColumn<String> header = GeneratedColumn<String>(
    'header',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginUrlMeta = const VerificationMeta(
    'loginUrl',
  );
  @override
  late final GeneratedColumn<String> loginUrl = GeneratedColumn<String>(
    'loginUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginUiMeta = const VerificationMeta(
    'loginUi',
  );
  @override
  late final GeneratedColumn<String> loginUi = GeneratedColumn<String>(
    'loginUi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginCheckJsMeta = const VerificationMeta(
    'loginCheckJs',
  );
  @override
  late final GeneratedColumn<String> loginCheckJs = GeneratedColumn<String>(
    'loginCheckJs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverDecodeJsMeta = const VerificationMeta(
    'coverDecodeJs',
  );
  @override
  late final GeneratedColumn<String> coverDecodeJs = GeneratedColumn<String>(
    'coverDecodeJs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortUrlMeta = const VerificationMeta(
    'sortUrl',
  );
  @override
  late final GeneratedColumn<String> sortUrl = GeneratedColumn<String>(
    'sortUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _singleUrlMeta = const VerificationMeta(
    'singleUrl',
  );
  @override
  late final GeneratedColumn<int> singleUrl = GeneratedColumn<int>(
    'singleUrl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _articleStyleMeta = const VerificationMeta(
    'articleStyle',
  );
  @override
  late final GeneratedColumn<int> articleStyle = GeneratedColumn<int>(
    'articleStyle',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ruleArticlesMeta = const VerificationMeta(
    'ruleArticles',
  );
  @override
  late final GeneratedColumn<String> ruleArticles = GeneratedColumn<String>(
    'ruleArticles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleNextPageMeta = const VerificationMeta(
    'ruleNextPage',
  );
  @override
  late final GeneratedColumn<String> ruleNextPage = GeneratedColumn<String>(
    'ruleNextPage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleTitleMeta = const VerificationMeta(
    'ruleTitle',
  );
  @override
  late final GeneratedColumn<String> ruleTitle = GeneratedColumn<String>(
    'ruleTitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rulePubDateMeta = const VerificationMeta(
    'rulePubDate',
  );
  @override
  late final GeneratedColumn<String> rulePubDate = GeneratedColumn<String>(
    'rulePubDate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleDescriptionMeta = const VerificationMeta(
    'ruleDescription',
  );
  @override
  late final GeneratedColumn<String> ruleDescription = GeneratedColumn<String>(
    'ruleDescription',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleImageMeta = const VerificationMeta(
    'ruleImage',
  );
  @override
  late final GeneratedColumn<String> ruleImage = GeneratedColumn<String>(
    'ruleImage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleLinkMeta = const VerificationMeta(
    'ruleLink',
  );
  @override
  late final GeneratedColumn<String> ruleLink = GeneratedColumn<String>(
    'ruleLink',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ruleContentMeta = const VerificationMeta(
    'ruleContent',
  );
  @override
  late final GeneratedColumn<String> ruleContent = GeneratedColumn<String>(
    'ruleContent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentWhitelistMeta = const VerificationMeta(
    'contentWhitelist',
  );
  @override
  late final GeneratedColumn<String> contentWhitelist = GeneratedColumn<String>(
    'contentWhitelist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentBlacklistMeta = const VerificationMeta(
    'contentBlacklist',
  );
  @override
  late final GeneratedColumn<String> contentBlacklist = GeneratedColumn<String>(
    'contentBlacklist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shouldOverrideUrlLoadingMeta =
      const VerificationMeta('shouldOverrideUrlLoading');
  @override
  late final GeneratedColumn<String> shouldOverrideUrlLoading =
      GeneratedColumn<String>(
        'shouldOverrideUrlLoading',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enableJsMeta = const VerificationMeta(
    'enableJs',
  );
  @override
  late final GeneratedColumn<int> enableJs = GeneratedColumn<int>(
    'enableJs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _loadWithBaseUrlMeta = const VerificationMeta(
    'loadWithBaseUrl',
  );
  @override
  late final GeneratedColumn<int> loadWithBaseUrl = GeneratedColumn<int>(
    'loadWithBaseUrl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _injectJsMeta = const VerificationMeta(
    'injectJs',
  );
  @override
  late final GeneratedColumn<String> injectJs = GeneratedColumn<String>(
    'injectJs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdateTimeMeta = const VerificationMeta(
    'lastUpdateTime',
  );
  @override
  late final GeneratedColumn<int> lastUpdateTime = GeneratedColumn<int>(
    'lastUpdateTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customOrderMeta = const VerificationMeta(
    'customOrder',
  );
  @override
  late final GeneratedColumn<int> customOrder = GeneratedColumn<int>(
    'customOrder',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceUrl,
    sourceName,
    sourceIcon,
    sourceGroup,
    sourceComment,
    enabled,
    variableComment,
    jsLib,
    enabledCookieJar,
    concurrentRate,
    header,
    loginUrl,
    loginUi,
    loginCheckJs,
    coverDecodeJs,
    sortUrl,
    singleUrl,
    articleStyle,
    ruleArticles,
    ruleNextPage,
    ruleTitle,
    rulePubDate,
    ruleDescription,
    ruleImage,
    ruleLink,
    ruleContent,
    contentWhitelist,
    contentBlacklist,
    shouldOverrideUrlLoading,
    style,
    enableJs,
    loadWithBaseUrl,
    injectJs,
    lastUpdateTime,
    customOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssSourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sourceUrl')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['sourceUrl']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('sourceName')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['sourceName']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('sourceIcon')) {
      context.handle(
        _sourceIconMeta,
        sourceIcon.isAcceptableOrUnknown(data['sourceIcon']!, _sourceIconMeta),
      );
    }
    if (data.containsKey('sourceGroup')) {
      context.handle(
        _sourceGroupMeta,
        sourceGroup.isAcceptableOrUnknown(
          data['sourceGroup']!,
          _sourceGroupMeta,
        ),
      );
    }
    if (data.containsKey('sourceComment')) {
      context.handle(
        _sourceCommentMeta,
        sourceComment.isAcceptableOrUnknown(
          data['sourceComment']!,
          _sourceCommentMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('variableComment')) {
      context.handle(
        _variableCommentMeta,
        variableComment.isAcceptableOrUnknown(
          data['variableComment']!,
          _variableCommentMeta,
        ),
      );
    }
    if (data.containsKey('jsLib')) {
      context.handle(
        _jsLibMeta,
        jsLib.isAcceptableOrUnknown(data['jsLib']!, _jsLibMeta),
      );
    }
    if (data.containsKey('enabledCookieJar')) {
      context.handle(
        _enabledCookieJarMeta,
        enabledCookieJar.isAcceptableOrUnknown(
          data['enabledCookieJar']!,
          _enabledCookieJarMeta,
        ),
      );
    }
    if (data.containsKey('concurrentRate')) {
      context.handle(
        _concurrentRateMeta,
        concurrentRate.isAcceptableOrUnknown(
          data['concurrentRate']!,
          _concurrentRateMeta,
        ),
      );
    }
    if (data.containsKey('header')) {
      context.handle(
        _headerMeta,
        header.isAcceptableOrUnknown(data['header']!, _headerMeta),
      );
    }
    if (data.containsKey('loginUrl')) {
      context.handle(
        _loginUrlMeta,
        loginUrl.isAcceptableOrUnknown(data['loginUrl']!, _loginUrlMeta),
      );
    }
    if (data.containsKey('loginUi')) {
      context.handle(
        _loginUiMeta,
        loginUi.isAcceptableOrUnknown(data['loginUi']!, _loginUiMeta),
      );
    }
    if (data.containsKey('loginCheckJs')) {
      context.handle(
        _loginCheckJsMeta,
        loginCheckJs.isAcceptableOrUnknown(
          data['loginCheckJs']!,
          _loginCheckJsMeta,
        ),
      );
    }
    if (data.containsKey('coverDecodeJs')) {
      context.handle(
        _coverDecodeJsMeta,
        coverDecodeJs.isAcceptableOrUnknown(
          data['coverDecodeJs']!,
          _coverDecodeJsMeta,
        ),
      );
    }
    if (data.containsKey('sortUrl')) {
      context.handle(
        _sortUrlMeta,
        sortUrl.isAcceptableOrUnknown(data['sortUrl']!, _sortUrlMeta),
      );
    }
    if (data.containsKey('singleUrl')) {
      context.handle(
        _singleUrlMeta,
        singleUrl.isAcceptableOrUnknown(data['singleUrl']!, _singleUrlMeta),
      );
    }
    if (data.containsKey('articleStyle')) {
      context.handle(
        _articleStyleMeta,
        articleStyle.isAcceptableOrUnknown(
          data['articleStyle']!,
          _articleStyleMeta,
        ),
      );
    }
    if (data.containsKey('ruleArticles')) {
      context.handle(
        _ruleArticlesMeta,
        ruleArticles.isAcceptableOrUnknown(
          data['ruleArticles']!,
          _ruleArticlesMeta,
        ),
      );
    }
    if (data.containsKey('ruleNextPage')) {
      context.handle(
        _ruleNextPageMeta,
        ruleNextPage.isAcceptableOrUnknown(
          data['ruleNextPage']!,
          _ruleNextPageMeta,
        ),
      );
    }
    if (data.containsKey('ruleTitle')) {
      context.handle(
        _ruleTitleMeta,
        ruleTitle.isAcceptableOrUnknown(data['ruleTitle']!, _ruleTitleMeta),
      );
    }
    if (data.containsKey('rulePubDate')) {
      context.handle(
        _rulePubDateMeta,
        rulePubDate.isAcceptableOrUnknown(
          data['rulePubDate']!,
          _rulePubDateMeta,
        ),
      );
    }
    if (data.containsKey('ruleDescription')) {
      context.handle(
        _ruleDescriptionMeta,
        ruleDescription.isAcceptableOrUnknown(
          data['ruleDescription']!,
          _ruleDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('ruleImage')) {
      context.handle(
        _ruleImageMeta,
        ruleImage.isAcceptableOrUnknown(data['ruleImage']!, _ruleImageMeta),
      );
    }
    if (data.containsKey('ruleLink')) {
      context.handle(
        _ruleLinkMeta,
        ruleLink.isAcceptableOrUnknown(data['ruleLink']!, _ruleLinkMeta),
      );
    }
    if (data.containsKey('ruleContent')) {
      context.handle(
        _ruleContentMeta,
        ruleContent.isAcceptableOrUnknown(
          data['ruleContent']!,
          _ruleContentMeta,
        ),
      );
    }
    if (data.containsKey('contentWhitelist')) {
      context.handle(
        _contentWhitelistMeta,
        contentWhitelist.isAcceptableOrUnknown(
          data['contentWhitelist']!,
          _contentWhitelistMeta,
        ),
      );
    }
    if (data.containsKey('contentBlacklist')) {
      context.handle(
        _contentBlacklistMeta,
        contentBlacklist.isAcceptableOrUnknown(
          data['contentBlacklist']!,
          _contentBlacklistMeta,
        ),
      );
    }
    if (data.containsKey('shouldOverrideUrlLoading')) {
      context.handle(
        _shouldOverrideUrlLoadingMeta,
        shouldOverrideUrlLoading.isAcceptableOrUnknown(
          data['shouldOverrideUrlLoading']!,
          _shouldOverrideUrlLoadingMeta,
        ),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('enableJs')) {
      context.handle(
        _enableJsMeta,
        enableJs.isAcceptableOrUnknown(data['enableJs']!, _enableJsMeta),
      );
    }
    if (data.containsKey('loadWithBaseUrl')) {
      context.handle(
        _loadWithBaseUrlMeta,
        loadWithBaseUrl.isAcceptableOrUnknown(
          data['loadWithBaseUrl']!,
          _loadWithBaseUrlMeta,
        ),
      );
    }
    if (data.containsKey('injectJs')) {
      context.handle(
        _injectJsMeta,
        injectJs.isAcceptableOrUnknown(data['injectJs']!, _injectJsMeta),
      );
    }
    if (data.containsKey('lastUpdateTime')) {
      context.handle(
        _lastUpdateTimeMeta,
        lastUpdateTime.isAcceptableOrUnknown(
          data['lastUpdateTime']!,
          _lastUpdateTimeMeta,
        ),
      );
    }
    if (data.containsKey('customOrder')) {
      context.handle(
        _customOrderMeta,
        customOrder.isAcceptableOrUnknown(
          data['customOrder']!,
          _customOrderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceUrl};
  @override
  RssSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssSourceRow(
      sourceUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sourceUrl'],
          )!,
      sourceName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sourceName'],
          )!,
      sourceIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sourceIcon'],
      ),
      sourceGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sourceGroup'],
      ),
      sourceComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sourceComment'],
      ),
      enabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabled'],
          )!,
      variableComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variableComment'],
      ),
      jsLib: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jsLib'],
      ),
      enabledCookieJar:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabledCookieJar'],
          )!,
      concurrentRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concurrentRate'],
      ),
      header: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header'],
      ),
      loginUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginUrl'],
      ),
      loginUi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginUi'],
      ),
      loginCheckJs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loginCheckJs'],
      ),
      coverDecodeJs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverDecodeJs'],
      ),
      sortUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sortUrl'],
      ),
      singleUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}singleUrl'],
          )!,
      articleStyle:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}articleStyle'],
          )!,
      ruleArticles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleArticles'],
      ),
      ruleNextPage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleNextPage'],
      ),
      ruleTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleTitle'],
      ),
      rulePubDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rulePubDate'],
      ),
      ruleDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleDescription'],
      ),
      ruleImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleImage'],
      ),
      ruleLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleLink'],
      ),
      ruleContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruleContent'],
      ),
      contentWhitelist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contentWhitelist'],
      ),
      contentBlacklist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contentBlacklist'],
      ),
      shouldOverrideUrlLoading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shouldOverrideUrlLoading'],
      ),
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      ),
      enableJs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enableJs'],
          )!,
      loadWithBaseUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}loadWithBaseUrl'],
          )!,
      injectJs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}injectJs'],
      ),
      lastUpdateTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}lastUpdateTime'],
          )!,
      customOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}customOrder'],
          )!,
    );
  }

  @override
  $RssSourcesTable createAlias(String alias) {
    return $RssSourcesTable(attachedDatabase, alias);
  }
}

class RssSourceRow extends DataClass implements Insertable<RssSourceRow> {
  final String sourceUrl;
  final String sourceName;
  final String? sourceIcon;
  final String? sourceGroup;
  final String? sourceComment;
  final int enabled;
  final String? variableComment;
  final String? jsLib;
  final int enabledCookieJar;
  final String? concurrentRate;
  final String? header;
  final String? loginUrl;
  final String? loginUi;
  final String? loginCheckJs;
  final String? coverDecodeJs;
  final String? sortUrl;
  final int singleUrl;
  final int articleStyle;
  final String? ruleArticles;
  final String? ruleNextPage;
  final String? ruleTitle;
  final String? rulePubDate;
  final String? ruleDescription;
  final String? ruleImage;
  final String? ruleLink;
  final String? ruleContent;
  final String? contentWhitelist;
  final String? contentBlacklist;
  final String? shouldOverrideUrlLoading;
  final String? style;
  final int enableJs;
  final int loadWithBaseUrl;
  final String? injectJs;
  final int lastUpdateTime;
  final int customOrder;
  const RssSourceRow({
    required this.sourceUrl,
    required this.sourceName,
    this.sourceIcon,
    this.sourceGroup,
    this.sourceComment,
    required this.enabled,
    this.variableComment,
    this.jsLib,
    required this.enabledCookieJar,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.sortUrl,
    required this.singleUrl,
    required this.articleStyle,
    this.ruleArticles,
    this.ruleNextPage,
    this.ruleTitle,
    this.rulePubDate,
    this.ruleDescription,
    this.ruleImage,
    this.ruleLink,
    this.ruleContent,
    this.contentWhitelist,
    this.contentBlacklist,
    this.shouldOverrideUrlLoading,
    this.style,
    required this.enableJs,
    required this.loadWithBaseUrl,
    this.injectJs,
    required this.lastUpdateTime,
    required this.customOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sourceUrl'] = Variable<String>(sourceUrl);
    map['sourceName'] = Variable<String>(sourceName);
    if (!nullToAbsent || sourceIcon != null) {
      map['sourceIcon'] = Variable<String>(sourceIcon);
    }
    if (!nullToAbsent || sourceGroup != null) {
      map['sourceGroup'] = Variable<String>(sourceGroup);
    }
    if (!nullToAbsent || sourceComment != null) {
      map['sourceComment'] = Variable<String>(sourceComment);
    }
    map['enabled'] = Variable<int>(enabled);
    if (!nullToAbsent || variableComment != null) {
      map['variableComment'] = Variable<String>(variableComment);
    }
    if (!nullToAbsent || jsLib != null) {
      map['jsLib'] = Variable<String>(jsLib);
    }
    map['enabledCookieJar'] = Variable<int>(enabledCookieJar);
    if (!nullToAbsent || concurrentRate != null) {
      map['concurrentRate'] = Variable<String>(concurrentRate);
    }
    if (!nullToAbsent || header != null) {
      map['header'] = Variable<String>(header);
    }
    if (!nullToAbsent || loginUrl != null) {
      map['loginUrl'] = Variable<String>(loginUrl);
    }
    if (!nullToAbsent || loginUi != null) {
      map['loginUi'] = Variable<String>(loginUi);
    }
    if (!nullToAbsent || loginCheckJs != null) {
      map['loginCheckJs'] = Variable<String>(loginCheckJs);
    }
    if (!nullToAbsent || coverDecodeJs != null) {
      map['coverDecodeJs'] = Variable<String>(coverDecodeJs);
    }
    if (!nullToAbsent || sortUrl != null) {
      map['sortUrl'] = Variable<String>(sortUrl);
    }
    map['singleUrl'] = Variable<int>(singleUrl);
    map['articleStyle'] = Variable<int>(articleStyle);
    if (!nullToAbsent || ruleArticles != null) {
      map['ruleArticles'] = Variable<String>(ruleArticles);
    }
    if (!nullToAbsent || ruleNextPage != null) {
      map['ruleNextPage'] = Variable<String>(ruleNextPage);
    }
    if (!nullToAbsent || ruleTitle != null) {
      map['ruleTitle'] = Variable<String>(ruleTitle);
    }
    if (!nullToAbsent || rulePubDate != null) {
      map['rulePubDate'] = Variable<String>(rulePubDate);
    }
    if (!nullToAbsent || ruleDescription != null) {
      map['ruleDescription'] = Variable<String>(ruleDescription);
    }
    if (!nullToAbsent || ruleImage != null) {
      map['ruleImage'] = Variable<String>(ruleImage);
    }
    if (!nullToAbsent || ruleLink != null) {
      map['ruleLink'] = Variable<String>(ruleLink);
    }
    if (!nullToAbsent || ruleContent != null) {
      map['ruleContent'] = Variable<String>(ruleContent);
    }
    if (!nullToAbsent || contentWhitelist != null) {
      map['contentWhitelist'] = Variable<String>(contentWhitelist);
    }
    if (!nullToAbsent || contentBlacklist != null) {
      map['contentBlacklist'] = Variable<String>(contentBlacklist);
    }
    if (!nullToAbsent || shouldOverrideUrlLoading != null) {
      map['shouldOverrideUrlLoading'] = Variable<String>(
        shouldOverrideUrlLoading,
      );
    }
    if (!nullToAbsent || style != null) {
      map['style'] = Variable<String>(style);
    }
    map['enableJs'] = Variable<int>(enableJs);
    map['loadWithBaseUrl'] = Variable<int>(loadWithBaseUrl);
    if (!nullToAbsent || injectJs != null) {
      map['injectJs'] = Variable<String>(injectJs);
    }
    map['lastUpdateTime'] = Variable<int>(lastUpdateTime);
    map['customOrder'] = Variable<int>(customOrder);
    return map;
  }

  RssSourcesCompanion toCompanion(bool nullToAbsent) {
    return RssSourcesCompanion(
      sourceUrl: Value(sourceUrl),
      sourceName: Value(sourceName),
      sourceIcon:
          sourceIcon == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceIcon),
      sourceGroup:
          sourceGroup == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceGroup),
      sourceComment:
          sourceComment == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceComment),
      enabled: Value(enabled),
      variableComment:
          variableComment == null && nullToAbsent
              ? const Value.absent()
              : Value(variableComment),
      jsLib:
          jsLib == null && nullToAbsent ? const Value.absent() : Value(jsLib),
      enabledCookieJar: Value(enabledCookieJar),
      concurrentRate:
          concurrentRate == null && nullToAbsent
              ? const Value.absent()
              : Value(concurrentRate),
      header:
          header == null && nullToAbsent ? const Value.absent() : Value(header),
      loginUrl:
          loginUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(loginUrl),
      loginUi:
          loginUi == null && nullToAbsent
              ? const Value.absent()
              : Value(loginUi),
      loginCheckJs:
          loginCheckJs == null && nullToAbsent
              ? const Value.absent()
              : Value(loginCheckJs),
      coverDecodeJs:
          coverDecodeJs == null && nullToAbsent
              ? const Value.absent()
              : Value(coverDecodeJs),
      sortUrl:
          sortUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(sortUrl),
      singleUrl: Value(singleUrl),
      articleStyle: Value(articleStyle),
      ruleArticles:
          ruleArticles == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleArticles),
      ruleNextPage:
          ruleNextPage == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleNextPage),
      ruleTitle:
          ruleTitle == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleTitle),
      rulePubDate:
          rulePubDate == null && nullToAbsent
              ? const Value.absent()
              : Value(rulePubDate),
      ruleDescription:
          ruleDescription == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleDescription),
      ruleImage:
          ruleImage == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleImage),
      ruleLink:
          ruleLink == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleLink),
      ruleContent:
          ruleContent == null && nullToAbsent
              ? const Value.absent()
              : Value(ruleContent),
      contentWhitelist:
          contentWhitelist == null && nullToAbsent
              ? const Value.absent()
              : Value(contentWhitelist),
      contentBlacklist:
          contentBlacklist == null && nullToAbsent
              ? const Value.absent()
              : Value(contentBlacklist),
      shouldOverrideUrlLoading:
          shouldOverrideUrlLoading == null && nullToAbsent
              ? const Value.absent()
              : Value(shouldOverrideUrlLoading),
      style:
          style == null && nullToAbsent ? const Value.absent() : Value(style),
      enableJs: Value(enableJs),
      loadWithBaseUrl: Value(loadWithBaseUrl),
      injectJs:
          injectJs == null && nullToAbsent
              ? const Value.absent()
              : Value(injectJs),
      lastUpdateTime: Value(lastUpdateTime),
      customOrder: Value(customOrder),
    );
  }

  factory RssSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssSourceRow(
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      sourceIcon: serializer.fromJson<String?>(json['sourceIcon']),
      sourceGroup: serializer.fromJson<String?>(json['sourceGroup']),
      sourceComment: serializer.fromJson<String?>(json['sourceComment']),
      enabled: serializer.fromJson<int>(json['enabled']),
      variableComment: serializer.fromJson<String?>(json['variableComment']),
      jsLib: serializer.fromJson<String?>(json['jsLib']),
      enabledCookieJar: serializer.fromJson<int>(json['enabledCookieJar']),
      concurrentRate: serializer.fromJson<String?>(json['concurrentRate']),
      header: serializer.fromJson<String?>(json['header']),
      loginUrl: serializer.fromJson<String?>(json['loginUrl']),
      loginUi: serializer.fromJson<String?>(json['loginUi']),
      loginCheckJs: serializer.fromJson<String?>(json['loginCheckJs']),
      coverDecodeJs: serializer.fromJson<String?>(json['coverDecodeJs']),
      sortUrl: serializer.fromJson<String?>(json['sortUrl']),
      singleUrl: serializer.fromJson<int>(json['singleUrl']),
      articleStyle: serializer.fromJson<int>(json['articleStyle']),
      ruleArticles: serializer.fromJson<String?>(json['ruleArticles']),
      ruleNextPage: serializer.fromJson<String?>(json['ruleNextPage']),
      ruleTitle: serializer.fromJson<String?>(json['ruleTitle']),
      rulePubDate: serializer.fromJson<String?>(json['rulePubDate']),
      ruleDescription: serializer.fromJson<String?>(json['ruleDescription']),
      ruleImage: serializer.fromJson<String?>(json['ruleImage']),
      ruleLink: serializer.fromJson<String?>(json['ruleLink']),
      ruleContent: serializer.fromJson<String?>(json['ruleContent']),
      contentWhitelist: serializer.fromJson<String?>(json['contentWhitelist']),
      contentBlacklist: serializer.fromJson<String?>(json['contentBlacklist']),
      shouldOverrideUrlLoading: serializer.fromJson<String?>(
        json['shouldOverrideUrlLoading'],
      ),
      style: serializer.fromJson<String?>(json['style']),
      enableJs: serializer.fromJson<int>(json['enableJs']),
      loadWithBaseUrl: serializer.fromJson<int>(json['loadWithBaseUrl']),
      injectJs: serializer.fromJson<String?>(json['injectJs']),
      lastUpdateTime: serializer.fromJson<int>(json['lastUpdateTime']),
      customOrder: serializer.fromJson<int>(json['customOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'sourceName': serializer.toJson<String>(sourceName),
      'sourceIcon': serializer.toJson<String?>(sourceIcon),
      'sourceGroup': serializer.toJson<String?>(sourceGroup),
      'sourceComment': serializer.toJson<String?>(sourceComment),
      'enabled': serializer.toJson<int>(enabled),
      'variableComment': serializer.toJson<String?>(variableComment),
      'jsLib': serializer.toJson<String?>(jsLib),
      'enabledCookieJar': serializer.toJson<int>(enabledCookieJar),
      'concurrentRate': serializer.toJson<String?>(concurrentRate),
      'header': serializer.toJson<String?>(header),
      'loginUrl': serializer.toJson<String?>(loginUrl),
      'loginUi': serializer.toJson<String?>(loginUi),
      'loginCheckJs': serializer.toJson<String?>(loginCheckJs),
      'coverDecodeJs': serializer.toJson<String?>(coverDecodeJs),
      'sortUrl': serializer.toJson<String?>(sortUrl),
      'singleUrl': serializer.toJson<int>(singleUrl),
      'articleStyle': serializer.toJson<int>(articleStyle),
      'ruleArticles': serializer.toJson<String?>(ruleArticles),
      'ruleNextPage': serializer.toJson<String?>(ruleNextPage),
      'ruleTitle': serializer.toJson<String?>(ruleTitle),
      'rulePubDate': serializer.toJson<String?>(rulePubDate),
      'ruleDescription': serializer.toJson<String?>(ruleDescription),
      'ruleImage': serializer.toJson<String?>(ruleImage),
      'ruleLink': serializer.toJson<String?>(ruleLink),
      'ruleContent': serializer.toJson<String?>(ruleContent),
      'contentWhitelist': serializer.toJson<String?>(contentWhitelist),
      'contentBlacklist': serializer.toJson<String?>(contentBlacklist),
      'shouldOverrideUrlLoading': serializer.toJson<String?>(
        shouldOverrideUrlLoading,
      ),
      'style': serializer.toJson<String?>(style),
      'enableJs': serializer.toJson<int>(enableJs),
      'loadWithBaseUrl': serializer.toJson<int>(loadWithBaseUrl),
      'injectJs': serializer.toJson<String?>(injectJs),
      'lastUpdateTime': serializer.toJson<int>(lastUpdateTime),
      'customOrder': serializer.toJson<int>(customOrder),
    };
  }

  RssSourceRow copyWith({
    String? sourceUrl,
    String? sourceName,
    Value<String?> sourceIcon = const Value.absent(),
    Value<String?> sourceGroup = const Value.absent(),
    Value<String?> sourceComment = const Value.absent(),
    int? enabled,
    Value<String?> variableComment = const Value.absent(),
    Value<String?> jsLib = const Value.absent(),
    int? enabledCookieJar,
    Value<String?> concurrentRate = const Value.absent(),
    Value<String?> header = const Value.absent(),
    Value<String?> loginUrl = const Value.absent(),
    Value<String?> loginUi = const Value.absent(),
    Value<String?> loginCheckJs = const Value.absent(),
    Value<String?> coverDecodeJs = const Value.absent(),
    Value<String?> sortUrl = const Value.absent(),
    int? singleUrl,
    int? articleStyle,
    Value<String?> ruleArticles = const Value.absent(),
    Value<String?> ruleNextPage = const Value.absent(),
    Value<String?> ruleTitle = const Value.absent(),
    Value<String?> rulePubDate = const Value.absent(),
    Value<String?> ruleDescription = const Value.absent(),
    Value<String?> ruleImage = const Value.absent(),
    Value<String?> ruleLink = const Value.absent(),
    Value<String?> ruleContent = const Value.absent(),
    Value<String?> contentWhitelist = const Value.absent(),
    Value<String?> contentBlacklist = const Value.absent(),
    Value<String?> shouldOverrideUrlLoading = const Value.absent(),
    Value<String?> style = const Value.absent(),
    int? enableJs,
    int? loadWithBaseUrl,
    Value<String?> injectJs = const Value.absent(),
    int? lastUpdateTime,
    int? customOrder,
  }) => RssSourceRow(
    sourceUrl: sourceUrl ?? this.sourceUrl,
    sourceName: sourceName ?? this.sourceName,
    sourceIcon: sourceIcon.present ? sourceIcon.value : this.sourceIcon,
    sourceGroup: sourceGroup.present ? sourceGroup.value : this.sourceGroup,
    sourceComment:
        sourceComment.present ? sourceComment.value : this.sourceComment,
    enabled: enabled ?? this.enabled,
    variableComment:
        variableComment.present ? variableComment.value : this.variableComment,
    jsLib: jsLib.present ? jsLib.value : this.jsLib,
    enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
    concurrentRate:
        concurrentRate.present ? concurrentRate.value : this.concurrentRate,
    header: header.present ? header.value : this.header,
    loginUrl: loginUrl.present ? loginUrl.value : this.loginUrl,
    loginUi: loginUi.present ? loginUi.value : this.loginUi,
    loginCheckJs: loginCheckJs.present ? loginCheckJs.value : this.loginCheckJs,
    coverDecodeJs:
        coverDecodeJs.present ? coverDecodeJs.value : this.coverDecodeJs,
    sortUrl: sortUrl.present ? sortUrl.value : this.sortUrl,
    singleUrl: singleUrl ?? this.singleUrl,
    articleStyle: articleStyle ?? this.articleStyle,
    ruleArticles: ruleArticles.present ? ruleArticles.value : this.ruleArticles,
    ruleNextPage: ruleNextPage.present ? ruleNextPage.value : this.ruleNextPage,
    ruleTitle: ruleTitle.present ? ruleTitle.value : this.ruleTitle,
    rulePubDate: rulePubDate.present ? rulePubDate.value : this.rulePubDate,
    ruleDescription:
        ruleDescription.present ? ruleDescription.value : this.ruleDescription,
    ruleImage: ruleImage.present ? ruleImage.value : this.ruleImage,
    ruleLink: ruleLink.present ? ruleLink.value : this.ruleLink,
    ruleContent: ruleContent.present ? ruleContent.value : this.ruleContent,
    contentWhitelist:
        contentWhitelist.present
            ? contentWhitelist.value
            : this.contentWhitelist,
    contentBlacklist:
        contentBlacklist.present
            ? contentBlacklist.value
            : this.contentBlacklist,
    shouldOverrideUrlLoading:
        shouldOverrideUrlLoading.present
            ? shouldOverrideUrlLoading.value
            : this.shouldOverrideUrlLoading,
    style: style.present ? style.value : this.style,
    enableJs: enableJs ?? this.enableJs,
    loadWithBaseUrl: loadWithBaseUrl ?? this.loadWithBaseUrl,
    injectJs: injectJs.present ? injectJs.value : this.injectJs,
    lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    customOrder: customOrder ?? this.customOrder,
  );
  RssSourceRow copyWithCompanion(RssSourcesCompanion data) {
    return RssSourceRow(
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceName:
          data.sourceName.present ? data.sourceName.value : this.sourceName,
      sourceIcon:
          data.sourceIcon.present ? data.sourceIcon.value : this.sourceIcon,
      sourceGroup:
          data.sourceGroup.present ? data.sourceGroup.value : this.sourceGroup,
      sourceComment:
          data.sourceComment.present
              ? data.sourceComment.value
              : this.sourceComment,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      variableComment:
          data.variableComment.present
              ? data.variableComment.value
              : this.variableComment,
      jsLib: data.jsLib.present ? data.jsLib.value : this.jsLib,
      enabledCookieJar:
          data.enabledCookieJar.present
              ? data.enabledCookieJar.value
              : this.enabledCookieJar,
      concurrentRate:
          data.concurrentRate.present
              ? data.concurrentRate.value
              : this.concurrentRate,
      header: data.header.present ? data.header.value : this.header,
      loginUrl: data.loginUrl.present ? data.loginUrl.value : this.loginUrl,
      loginUi: data.loginUi.present ? data.loginUi.value : this.loginUi,
      loginCheckJs:
          data.loginCheckJs.present
              ? data.loginCheckJs.value
              : this.loginCheckJs,
      coverDecodeJs:
          data.coverDecodeJs.present
              ? data.coverDecodeJs.value
              : this.coverDecodeJs,
      sortUrl: data.sortUrl.present ? data.sortUrl.value : this.sortUrl,
      singleUrl: data.singleUrl.present ? data.singleUrl.value : this.singleUrl,
      articleStyle:
          data.articleStyle.present
              ? data.articleStyle.value
              : this.articleStyle,
      ruleArticles:
          data.ruleArticles.present
              ? data.ruleArticles.value
              : this.ruleArticles,
      ruleNextPage:
          data.ruleNextPage.present
              ? data.ruleNextPage.value
              : this.ruleNextPage,
      ruleTitle: data.ruleTitle.present ? data.ruleTitle.value : this.ruleTitle,
      rulePubDate:
          data.rulePubDate.present ? data.rulePubDate.value : this.rulePubDate,
      ruleDescription:
          data.ruleDescription.present
              ? data.ruleDescription.value
              : this.ruleDescription,
      ruleImage: data.ruleImage.present ? data.ruleImage.value : this.ruleImage,
      ruleLink: data.ruleLink.present ? data.ruleLink.value : this.ruleLink,
      ruleContent:
          data.ruleContent.present ? data.ruleContent.value : this.ruleContent,
      contentWhitelist:
          data.contentWhitelist.present
              ? data.contentWhitelist.value
              : this.contentWhitelist,
      contentBlacklist:
          data.contentBlacklist.present
              ? data.contentBlacklist.value
              : this.contentBlacklist,
      shouldOverrideUrlLoading:
          data.shouldOverrideUrlLoading.present
              ? data.shouldOverrideUrlLoading.value
              : this.shouldOverrideUrlLoading,
      style: data.style.present ? data.style.value : this.style,
      enableJs: data.enableJs.present ? data.enableJs.value : this.enableJs,
      loadWithBaseUrl:
          data.loadWithBaseUrl.present
              ? data.loadWithBaseUrl.value
              : this.loadWithBaseUrl,
      injectJs: data.injectJs.present ? data.injectJs.value : this.injectJs,
      lastUpdateTime:
          data.lastUpdateTime.present
              ? data.lastUpdateTime.value
              : this.lastUpdateTime,
      customOrder:
          data.customOrder.present ? data.customOrder.value : this.customOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssSourceRow(')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceIcon: $sourceIcon, ')
          ..write('sourceGroup: $sourceGroup, ')
          ..write('sourceComment: $sourceComment, ')
          ..write('enabled: $enabled, ')
          ..write('variableComment: $variableComment, ')
          ..write('jsLib: $jsLib, ')
          ..write('enabledCookieJar: $enabledCookieJar, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('header: $header, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('loginUi: $loginUi, ')
          ..write('loginCheckJs: $loginCheckJs, ')
          ..write('coverDecodeJs: $coverDecodeJs, ')
          ..write('sortUrl: $sortUrl, ')
          ..write('singleUrl: $singleUrl, ')
          ..write('articleStyle: $articleStyle, ')
          ..write('ruleArticles: $ruleArticles, ')
          ..write('ruleNextPage: $ruleNextPage, ')
          ..write('ruleTitle: $ruleTitle, ')
          ..write('rulePubDate: $rulePubDate, ')
          ..write('ruleDescription: $ruleDescription, ')
          ..write('ruleImage: $ruleImage, ')
          ..write('ruleLink: $ruleLink, ')
          ..write('ruleContent: $ruleContent, ')
          ..write('contentWhitelist: $contentWhitelist, ')
          ..write('contentBlacklist: $contentBlacklist, ')
          ..write('shouldOverrideUrlLoading: $shouldOverrideUrlLoading, ')
          ..write('style: $style, ')
          ..write('enableJs: $enableJs, ')
          ..write('loadWithBaseUrl: $loadWithBaseUrl, ')
          ..write('injectJs: $injectJs, ')
          ..write('lastUpdateTime: $lastUpdateTime, ')
          ..write('customOrder: $customOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    sourceUrl,
    sourceName,
    sourceIcon,
    sourceGroup,
    sourceComment,
    enabled,
    variableComment,
    jsLib,
    enabledCookieJar,
    concurrentRate,
    header,
    loginUrl,
    loginUi,
    loginCheckJs,
    coverDecodeJs,
    sortUrl,
    singleUrl,
    articleStyle,
    ruleArticles,
    ruleNextPage,
    ruleTitle,
    rulePubDate,
    ruleDescription,
    ruleImage,
    ruleLink,
    ruleContent,
    contentWhitelist,
    contentBlacklist,
    shouldOverrideUrlLoading,
    style,
    enableJs,
    loadWithBaseUrl,
    injectJs,
    lastUpdateTime,
    customOrder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssSourceRow &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceName == this.sourceName &&
          other.sourceIcon == this.sourceIcon &&
          other.sourceGroup == this.sourceGroup &&
          other.sourceComment == this.sourceComment &&
          other.enabled == this.enabled &&
          other.variableComment == this.variableComment &&
          other.jsLib == this.jsLib &&
          other.enabledCookieJar == this.enabledCookieJar &&
          other.concurrentRate == this.concurrentRate &&
          other.header == this.header &&
          other.loginUrl == this.loginUrl &&
          other.loginUi == this.loginUi &&
          other.loginCheckJs == this.loginCheckJs &&
          other.coverDecodeJs == this.coverDecodeJs &&
          other.sortUrl == this.sortUrl &&
          other.singleUrl == this.singleUrl &&
          other.articleStyle == this.articleStyle &&
          other.ruleArticles == this.ruleArticles &&
          other.ruleNextPage == this.ruleNextPage &&
          other.ruleTitle == this.ruleTitle &&
          other.rulePubDate == this.rulePubDate &&
          other.ruleDescription == this.ruleDescription &&
          other.ruleImage == this.ruleImage &&
          other.ruleLink == this.ruleLink &&
          other.ruleContent == this.ruleContent &&
          other.contentWhitelist == this.contentWhitelist &&
          other.contentBlacklist == this.contentBlacklist &&
          other.shouldOverrideUrlLoading == this.shouldOverrideUrlLoading &&
          other.style == this.style &&
          other.enableJs == this.enableJs &&
          other.loadWithBaseUrl == this.loadWithBaseUrl &&
          other.injectJs == this.injectJs &&
          other.lastUpdateTime == this.lastUpdateTime &&
          other.customOrder == this.customOrder);
}

class RssSourcesCompanion extends UpdateCompanion<RssSourceRow> {
  final Value<String> sourceUrl;
  final Value<String> sourceName;
  final Value<String?> sourceIcon;
  final Value<String?> sourceGroup;
  final Value<String?> sourceComment;
  final Value<int> enabled;
  final Value<String?> variableComment;
  final Value<String?> jsLib;
  final Value<int> enabledCookieJar;
  final Value<String?> concurrentRate;
  final Value<String?> header;
  final Value<String?> loginUrl;
  final Value<String?> loginUi;
  final Value<String?> loginCheckJs;
  final Value<String?> coverDecodeJs;
  final Value<String?> sortUrl;
  final Value<int> singleUrl;
  final Value<int> articleStyle;
  final Value<String?> ruleArticles;
  final Value<String?> ruleNextPage;
  final Value<String?> ruleTitle;
  final Value<String?> rulePubDate;
  final Value<String?> ruleDescription;
  final Value<String?> ruleImage;
  final Value<String?> ruleLink;
  final Value<String?> ruleContent;
  final Value<String?> contentWhitelist;
  final Value<String?> contentBlacklist;
  final Value<String?> shouldOverrideUrlLoading;
  final Value<String?> style;
  final Value<int> enableJs;
  final Value<int> loadWithBaseUrl;
  final Value<String?> injectJs;
  final Value<int> lastUpdateTime;
  final Value<int> customOrder;
  final Value<int> rowid;
  const RssSourcesCompanion({
    this.sourceUrl = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.sourceIcon = const Value.absent(),
    this.sourceGroup = const Value.absent(),
    this.sourceComment = const Value.absent(),
    this.enabled = const Value.absent(),
    this.variableComment = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.enabledCookieJar = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.header = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.loginUi = const Value.absent(),
    this.loginCheckJs = const Value.absent(),
    this.coverDecodeJs = const Value.absent(),
    this.sortUrl = const Value.absent(),
    this.singleUrl = const Value.absent(),
    this.articleStyle = const Value.absent(),
    this.ruleArticles = const Value.absent(),
    this.ruleNextPage = const Value.absent(),
    this.ruleTitle = const Value.absent(),
    this.rulePubDate = const Value.absent(),
    this.ruleDescription = const Value.absent(),
    this.ruleImage = const Value.absent(),
    this.ruleLink = const Value.absent(),
    this.ruleContent = const Value.absent(),
    this.contentWhitelist = const Value.absent(),
    this.contentBlacklist = const Value.absent(),
    this.shouldOverrideUrlLoading = const Value.absent(),
    this.style = const Value.absent(),
    this.enableJs = const Value.absent(),
    this.loadWithBaseUrl = const Value.absent(),
    this.injectJs = const Value.absent(),
    this.lastUpdateTime = const Value.absent(),
    this.customOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssSourcesCompanion.insert({
    required String sourceUrl,
    required String sourceName,
    this.sourceIcon = const Value.absent(),
    this.sourceGroup = const Value.absent(),
    this.sourceComment = const Value.absent(),
    this.enabled = const Value.absent(),
    this.variableComment = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.enabledCookieJar = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.header = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.loginUi = const Value.absent(),
    this.loginCheckJs = const Value.absent(),
    this.coverDecodeJs = const Value.absent(),
    this.sortUrl = const Value.absent(),
    this.singleUrl = const Value.absent(),
    this.articleStyle = const Value.absent(),
    this.ruleArticles = const Value.absent(),
    this.ruleNextPage = const Value.absent(),
    this.ruleTitle = const Value.absent(),
    this.rulePubDate = const Value.absent(),
    this.ruleDescription = const Value.absent(),
    this.ruleImage = const Value.absent(),
    this.ruleLink = const Value.absent(),
    this.ruleContent = const Value.absent(),
    this.contentWhitelist = const Value.absent(),
    this.contentBlacklist = const Value.absent(),
    this.shouldOverrideUrlLoading = const Value.absent(),
    this.style = const Value.absent(),
    this.enableJs = const Value.absent(),
    this.loadWithBaseUrl = const Value.absent(),
    this.injectJs = const Value.absent(),
    this.lastUpdateTime = const Value.absent(),
    this.customOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceUrl = Value(sourceUrl),
       sourceName = Value(sourceName);
  static Insertable<RssSourceRow> custom({
    Expression<String>? sourceUrl,
    Expression<String>? sourceName,
    Expression<String>? sourceIcon,
    Expression<String>? sourceGroup,
    Expression<String>? sourceComment,
    Expression<int>? enabled,
    Expression<String>? variableComment,
    Expression<String>? jsLib,
    Expression<int>? enabledCookieJar,
    Expression<String>? concurrentRate,
    Expression<String>? header,
    Expression<String>? loginUrl,
    Expression<String>? loginUi,
    Expression<String>? loginCheckJs,
    Expression<String>? coverDecodeJs,
    Expression<String>? sortUrl,
    Expression<int>? singleUrl,
    Expression<int>? articleStyle,
    Expression<String>? ruleArticles,
    Expression<String>? ruleNextPage,
    Expression<String>? ruleTitle,
    Expression<String>? rulePubDate,
    Expression<String>? ruleDescription,
    Expression<String>? ruleImage,
    Expression<String>? ruleLink,
    Expression<String>? ruleContent,
    Expression<String>? contentWhitelist,
    Expression<String>? contentBlacklist,
    Expression<String>? shouldOverrideUrlLoading,
    Expression<String>? style,
    Expression<int>? enableJs,
    Expression<int>? loadWithBaseUrl,
    Expression<String>? injectJs,
    Expression<int>? lastUpdateTime,
    Expression<int>? customOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (sourceName != null) 'sourceName': sourceName,
      if (sourceIcon != null) 'sourceIcon': sourceIcon,
      if (sourceGroup != null) 'sourceGroup': sourceGroup,
      if (sourceComment != null) 'sourceComment': sourceComment,
      if (enabled != null) 'enabled': enabled,
      if (variableComment != null) 'variableComment': variableComment,
      if (jsLib != null) 'jsLib': jsLib,
      if (enabledCookieJar != null) 'enabledCookieJar': enabledCookieJar,
      if (concurrentRate != null) 'concurrentRate': concurrentRate,
      if (header != null) 'header': header,
      if (loginUrl != null) 'loginUrl': loginUrl,
      if (loginUi != null) 'loginUi': loginUi,
      if (loginCheckJs != null) 'loginCheckJs': loginCheckJs,
      if (coverDecodeJs != null) 'coverDecodeJs': coverDecodeJs,
      if (sortUrl != null) 'sortUrl': sortUrl,
      if (singleUrl != null) 'singleUrl': singleUrl,
      if (articleStyle != null) 'articleStyle': articleStyle,
      if (ruleArticles != null) 'ruleArticles': ruleArticles,
      if (ruleNextPage != null) 'ruleNextPage': ruleNextPage,
      if (ruleTitle != null) 'ruleTitle': ruleTitle,
      if (rulePubDate != null) 'rulePubDate': rulePubDate,
      if (ruleDescription != null) 'ruleDescription': ruleDescription,
      if (ruleImage != null) 'ruleImage': ruleImage,
      if (ruleLink != null) 'ruleLink': ruleLink,
      if (ruleContent != null) 'ruleContent': ruleContent,
      if (contentWhitelist != null) 'contentWhitelist': contentWhitelist,
      if (contentBlacklist != null) 'contentBlacklist': contentBlacklist,
      if (shouldOverrideUrlLoading != null)
        'shouldOverrideUrlLoading': shouldOverrideUrlLoading,
      if (style != null) 'style': style,
      if (enableJs != null) 'enableJs': enableJs,
      if (loadWithBaseUrl != null) 'loadWithBaseUrl': loadWithBaseUrl,
      if (injectJs != null) 'injectJs': injectJs,
      if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime,
      if (customOrder != null) 'customOrder': customOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssSourcesCompanion copyWith({
    Value<String>? sourceUrl,
    Value<String>? sourceName,
    Value<String?>? sourceIcon,
    Value<String?>? sourceGroup,
    Value<String?>? sourceComment,
    Value<int>? enabled,
    Value<String?>? variableComment,
    Value<String?>? jsLib,
    Value<int>? enabledCookieJar,
    Value<String?>? concurrentRate,
    Value<String?>? header,
    Value<String?>? loginUrl,
    Value<String?>? loginUi,
    Value<String?>? loginCheckJs,
    Value<String?>? coverDecodeJs,
    Value<String?>? sortUrl,
    Value<int>? singleUrl,
    Value<int>? articleStyle,
    Value<String?>? ruleArticles,
    Value<String?>? ruleNextPage,
    Value<String?>? ruleTitle,
    Value<String?>? rulePubDate,
    Value<String?>? ruleDescription,
    Value<String?>? ruleImage,
    Value<String?>? ruleLink,
    Value<String?>? ruleContent,
    Value<String?>? contentWhitelist,
    Value<String?>? contentBlacklist,
    Value<String?>? shouldOverrideUrlLoading,
    Value<String?>? style,
    Value<int>? enableJs,
    Value<int>? loadWithBaseUrl,
    Value<String?>? injectJs,
    Value<int>? lastUpdateTime,
    Value<int>? customOrder,
    Value<int>? rowid,
  }) {
    return RssSourcesCompanion(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceIcon: sourceIcon ?? this.sourceIcon,
      sourceGroup: sourceGroup ?? this.sourceGroup,
      sourceComment: sourceComment ?? this.sourceComment,
      enabled: enabled ?? this.enabled,
      variableComment: variableComment ?? this.variableComment,
      jsLib: jsLib ?? this.jsLib,
      enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      header: header ?? this.header,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi ?? this.loginUi,
      loginCheckJs: loginCheckJs ?? this.loginCheckJs,
      coverDecodeJs: coverDecodeJs ?? this.coverDecodeJs,
      sortUrl: sortUrl ?? this.sortUrl,
      singleUrl: singleUrl ?? this.singleUrl,
      articleStyle: articleStyle ?? this.articleStyle,
      ruleArticles: ruleArticles ?? this.ruleArticles,
      ruleNextPage: ruleNextPage ?? this.ruleNextPage,
      ruleTitle: ruleTitle ?? this.ruleTitle,
      rulePubDate: rulePubDate ?? this.rulePubDate,
      ruleDescription: ruleDescription ?? this.ruleDescription,
      ruleImage: ruleImage ?? this.ruleImage,
      ruleLink: ruleLink ?? this.ruleLink,
      ruleContent: ruleContent ?? this.ruleContent,
      contentWhitelist: contentWhitelist ?? this.contentWhitelist,
      contentBlacklist: contentBlacklist ?? this.contentBlacklist,
      shouldOverrideUrlLoading:
          shouldOverrideUrlLoading ?? this.shouldOverrideUrlLoading,
      style: style ?? this.style,
      enableJs: enableJs ?? this.enableJs,
      loadWithBaseUrl: loadWithBaseUrl ?? this.loadWithBaseUrl,
      injectJs: injectJs ?? this.injectJs,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      customOrder: customOrder ?? this.customOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceUrl.present) {
      map['sourceUrl'] = Variable<String>(sourceUrl.value);
    }
    if (sourceName.present) {
      map['sourceName'] = Variable<String>(sourceName.value);
    }
    if (sourceIcon.present) {
      map['sourceIcon'] = Variable<String>(sourceIcon.value);
    }
    if (sourceGroup.present) {
      map['sourceGroup'] = Variable<String>(sourceGroup.value);
    }
    if (sourceComment.present) {
      map['sourceComment'] = Variable<String>(sourceComment.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<int>(enabled.value);
    }
    if (variableComment.present) {
      map['variableComment'] = Variable<String>(variableComment.value);
    }
    if (jsLib.present) {
      map['jsLib'] = Variable<String>(jsLib.value);
    }
    if (enabledCookieJar.present) {
      map['enabledCookieJar'] = Variable<int>(enabledCookieJar.value);
    }
    if (concurrentRate.present) {
      map['concurrentRate'] = Variable<String>(concurrentRate.value);
    }
    if (header.present) {
      map['header'] = Variable<String>(header.value);
    }
    if (loginUrl.present) {
      map['loginUrl'] = Variable<String>(loginUrl.value);
    }
    if (loginUi.present) {
      map['loginUi'] = Variable<String>(loginUi.value);
    }
    if (loginCheckJs.present) {
      map['loginCheckJs'] = Variable<String>(loginCheckJs.value);
    }
    if (coverDecodeJs.present) {
      map['coverDecodeJs'] = Variable<String>(coverDecodeJs.value);
    }
    if (sortUrl.present) {
      map['sortUrl'] = Variable<String>(sortUrl.value);
    }
    if (singleUrl.present) {
      map['singleUrl'] = Variable<int>(singleUrl.value);
    }
    if (articleStyle.present) {
      map['articleStyle'] = Variable<int>(articleStyle.value);
    }
    if (ruleArticles.present) {
      map['ruleArticles'] = Variable<String>(ruleArticles.value);
    }
    if (ruleNextPage.present) {
      map['ruleNextPage'] = Variable<String>(ruleNextPage.value);
    }
    if (ruleTitle.present) {
      map['ruleTitle'] = Variable<String>(ruleTitle.value);
    }
    if (rulePubDate.present) {
      map['rulePubDate'] = Variable<String>(rulePubDate.value);
    }
    if (ruleDescription.present) {
      map['ruleDescription'] = Variable<String>(ruleDescription.value);
    }
    if (ruleImage.present) {
      map['ruleImage'] = Variable<String>(ruleImage.value);
    }
    if (ruleLink.present) {
      map['ruleLink'] = Variable<String>(ruleLink.value);
    }
    if (ruleContent.present) {
      map['ruleContent'] = Variable<String>(ruleContent.value);
    }
    if (contentWhitelist.present) {
      map['contentWhitelist'] = Variable<String>(contentWhitelist.value);
    }
    if (contentBlacklist.present) {
      map['contentBlacklist'] = Variable<String>(contentBlacklist.value);
    }
    if (shouldOverrideUrlLoading.present) {
      map['shouldOverrideUrlLoading'] = Variable<String>(
        shouldOverrideUrlLoading.value,
      );
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (enableJs.present) {
      map['enableJs'] = Variable<int>(enableJs.value);
    }
    if (loadWithBaseUrl.present) {
      map['loadWithBaseUrl'] = Variable<int>(loadWithBaseUrl.value);
    }
    if (injectJs.present) {
      map['injectJs'] = Variable<String>(injectJs.value);
    }
    if (lastUpdateTime.present) {
      map['lastUpdateTime'] = Variable<int>(lastUpdateTime.value);
    }
    if (customOrder.present) {
      map['customOrder'] = Variable<int>(customOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssSourcesCompanion(')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceIcon: $sourceIcon, ')
          ..write('sourceGroup: $sourceGroup, ')
          ..write('sourceComment: $sourceComment, ')
          ..write('enabled: $enabled, ')
          ..write('variableComment: $variableComment, ')
          ..write('jsLib: $jsLib, ')
          ..write('enabledCookieJar: $enabledCookieJar, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('header: $header, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('loginUi: $loginUi, ')
          ..write('loginCheckJs: $loginCheckJs, ')
          ..write('coverDecodeJs: $coverDecodeJs, ')
          ..write('sortUrl: $sortUrl, ')
          ..write('singleUrl: $singleUrl, ')
          ..write('articleStyle: $articleStyle, ')
          ..write('ruleArticles: $ruleArticles, ')
          ..write('ruleNextPage: $ruleNextPage, ')
          ..write('ruleTitle: $ruleTitle, ')
          ..write('rulePubDate: $rulePubDate, ')
          ..write('ruleDescription: $ruleDescription, ')
          ..write('ruleImage: $ruleImage, ')
          ..write('ruleLink: $ruleLink, ')
          ..write('ruleContent: $ruleContent, ')
          ..write('contentWhitelist: $contentWhitelist, ')
          ..write('contentBlacklist: $contentBlacklist, ')
          ..write('shouldOverrideUrlLoading: $shouldOverrideUrlLoading, ')
          ..write('style: $style, ')
          ..write('enableJs: $enableJs, ')
          ..write('loadWithBaseUrl: $loadWithBaseUrl, ')
          ..write('injectJs: $injectJs, ')
          ..write('lastUpdateTime: $lastUpdateTime, ')
          ..write('customOrder: $customOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssStarsTable extends RssStars
    with TableInfo<$RssStarsTable, RssStarRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssStarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<String> sort = GeneratedColumn<String>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _starTimeMeta = const VerificationMeta(
    'starTime',
  );
  @override
  late final GeneratedColumn<int> starTime = GeneratedColumn<int>(
    'starTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pubDateMeta = const VerificationMeta(
    'pubDate',
  );
  @override
  late final GeneratedColumn<String> pubDate = GeneratedColumn<String>(
    'pubDate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
    'image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
    'group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variableMeta = const VerificationMeta(
    'variable',
  );
  @override
  late final GeneratedColumn<String> variable = GeneratedColumn<String>(
    'variable',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    link,
    origin,
    sort,
    title,
    starTime,
    pubDate,
    description,
    content,
    image,
    group,
    variable,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_stars';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssStarRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    } else if (isInserting) {
      context.missing(_linkMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    } else if (isInserting) {
      context.missing(_sortMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('starTime')) {
      context.handle(
        _starTimeMeta,
        starTime.isAcceptableOrUnknown(data['starTime']!, _starTimeMeta),
      );
    }
    if (data.containsKey('pubDate')) {
      context.handle(
        _pubDateMeta,
        pubDate.isAcceptableOrUnknown(data['pubDate']!, _pubDateMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('image')) {
      context.handle(
        _imageMeta,
        image.isAcceptableOrUnknown(data['image']!, _imageMeta),
      );
    }
    if (data.containsKey('group')) {
      context.handle(
        _groupMeta,
        group.isAcceptableOrUnknown(data['group']!, _groupMeta),
      );
    }
    if (data.containsKey('variable')) {
      context.handle(
        _variableMeta,
        variable.isAcceptableOrUnknown(data['variable']!, _variableMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {link, origin};
  @override
  RssStarRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssStarRow(
      link:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}link'],
          )!,
      origin:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}origin'],
          )!,
      sort:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sort'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      starTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}starTime'],
          )!,
      pubDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubDate'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      image: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image'],
      ),
      group: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group'],
      ),
      variable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variable'],
      ),
    );
  }

  @override
  $RssStarsTable createAlias(String alias) {
    return $RssStarsTable(attachedDatabase, alias);
  }
}

class RssStarRow extends DataClass implements Insertable<RssStarRow> {
  final String link;
  final String origin;
  final String sort;
  final String title;
  final int starTime;
  final String? pubDate;
  final String? description;
  final String? content;
  final String? image;
  final String? group;
  final String? variable;
  const RssStarRow({
    required this.link,
    required this.origin,
    required this.sort,
    required this.title,
    required this.starTime,
    this.pubDate,
    this.description,
    this.content,
    this.image,
    this.group,
    this.variable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['link'] = Variable<String>(link);
    map['origin'] = Variable<String>(origin);
    map['sort'] = Variable<String>(sort);
    map['title'] = Variable<String>(title);
    map['starTime'] = Variable<int>(starTime);
    if (!nullToAbsent || pubDate != null) {
      map['pubDate'] = Variable<String>(pubDate);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    if (!nullToAbsent || group != null) {
      map['group'] = Variable<String>(group);
    }
    if (!nullToAbsent || variable != null) {
      map['variable'] = Variable<String>(variable);
    }
    return map;
  }

  RssStarsCompanion toCompanion(bool nullToAbsent) {
    return RssStarsCompanion(
      link: Value(link),
      origin: Value(origin),
      sort: Value(sort),
      title: Value(title),
      starTime: Value(starTime),
      pubDate:
          pubDate == null && nullToAbsent
              ? const Value.absent()
              : Value(pubDate),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      content:
          content == null && nullToAbsent
              ? const Value.absent()
              : Value(content),
      image:
          image == null && nullToAbsent ? const Value.absent() : Value(image),
      group:
          group == null && nullToAbsent ? const Value.absent() : Value(group),
      variable:
          variable == null && nullToAbsent
              ? const Value.absent()
              : Value(variable),
    );
  }

  factory RssStarRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssStarRow(
      link: serializer.fromJson<String>(json['link']),
      origin: serializer.fromJson<String>(json['origin']),
      sort: serializer.fromJson<String>(json['sort']),
      title: serializer.fromJson<String>(json['title']),
      starTime: serializer.fromJson<int>(json['starTime']),
      pubDate: serializer.fromJson<String?>(json['pubDate']),
      description: serializer.fromJson<String?>(json['description']),
      content: serializer.fromJson<String?>(json['content']),
      image: serializer.fromJson<String?>(json['image']),
      group: serializer.fromJson<String?>(json['group']),
      variable: serializer.fromJson<String?>(json['variable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'link': serializer.toJson<String>(link),
      'origin': serializer.toJson<String>(origin),
      'sort': serializer.toJson<String>(sort),
      'title': serializer.toJson<String>(title),
      'starTime': serializer.toJson<int>(starTime),
      'pubDate': serializer.toJson<String?>(pubDate),
      'description': serializer.toJson<String?>(description),
      'content': serializer.toJson<String?>(content),
      'image': serializer.toJson<String?>(image),
      'group': serializer.toJson<String?>(group),
      'variable': serializer.toJson<String?>(variable),
    };
  }

  RssStarRow copyWith({
    String? link,
    String? origin,
    String? sort,
    String? title,
    int? starTime,
    Value<String?> pubDate = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> content = const Value.absent(),
    Value<String?> image = const Value.absent(),
    Value<String?> group = const Value.absent(),
    Value<String?> variable = const Value.absent(),
  }) => RssStarRow(
    link: link ?? this.link,
    origin: origin ?? this.origin,
    sort: sort ?? this.sort,
    title: title ?? this.title,
    starTime: starTime ?? this.starTime,
    pubDate: pubDate.present ? pubDate.value : this.pubDate,
    description: description.present ? description.value : this.description,
    content: content.present ? content.value : this.content,
    image: image.present ? image.value : this.image,
    group: group.present ? group.value : this.group,
    variable: variable.present ? variable.value : this.variable,
  );
  RssStarRow copyWithCompanion(RssStarsCompanion data) {
    return RssStarRow(
      link: data.link.present ? data.link.value : this.link,
      origin: data.origin.present ? data.origin.value : this.origin,
      sort: data.sort.present ? data.sort.value : this.sort,
      title: data.title.present ? data.title.value : this.title,
      starTime: data.starTime.present ? data.starTime.value : this.starTime,
      pubDate: data.pubDate.present ? data.pubDate.value : this.pubDate,
      description:
          data.description.present ? data.description.value : this.description,
      content: data.content.present ? data.content.value : this.content,
      image: data.image.present ? data.image.value : this.image,
      group: data.group.present ? data.group.value : this.group,
      variable: data.variable.present ? data.variable.value : this.variable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssStarRow(')
          ..write('link: $link, ')
          ..write('origin: $origin, ')
          ..write('sort: $sort, ')
          ..write('title: $title, ')
          ..write('starTime: $starTime, ')
          ..write('pubDate: $pubDate, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('image: $image, ')
          ..write('group: $group, ')
          ..write('variable: $variable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    link,
    origin,
    sort,
    title,
    starTime,
    pubDate,
    description,
    content,
    image,
    group,
    variable,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssStarRow &&
          other.link == this.link &&
          other.origin == this.origin &&
          other.sort == this.sort &&
          other.title == this.title &&
          other.starTime == this.starTime &&
          other.pubDate == this.pubDate &&
          other.description == this.description &&
          other.content == this.content &&
          other.image == this.image &&
          other.group == this.group &&
          other.variable == this.variable);
}

class RssStarsCompanion extends UpdateCompanion<RssStarRow> {
  final Value<String> link;
  final Value<String> origin;
  final Value<String> sort;
  final Value<String> title;
  final Value<int> starTime;
  final Value<String?> pubDate;
  final Value<String?> description;
  final Value<String?> content;
  final Value<String?> image;
  final Value<String?> group;
  final Value<String?> variable;
  final Value<int> rowid;
  const RssStarsCompanion({
    this.link = const Value.absent(),
    this.origin = const Value.absent(),
    this.sort = const Value.absent(),
    this.title = const Value.absent(),
    this.starTime = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.image = const Value.absent(),
    this.group = const Value.absent(),
    this.variable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssStarsCompanion.insert({
    required String link,
    required String origin,
    required String sort,
    required String title,
    this.starTime = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.image = const Value.absent(),
    this.group = const Value.absent(),
    this.variable = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : link = Value(link),
       origin = Value(origin),
       sort = Value(sort),
       title = Value(title);
  static Insertable<RssStarRow> custom({
    Expression<String>? link,
    Expression<String>? origin,
    Expression<String>? sort,
    Expression<String>? title,
    Expression<int>? starTime,
    Expression<String>? pubDate,
    Expression<String>? description,
    Expression<String>? content,
    Expression<String>? image,
    Expression<String>? group,
    Expression<String>? variable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (link != null) 'link': link,
      if (origin != null) 'origin': origin,
      if (sort != null) 'sort': sort,
      if (title != null) 'title': title,
      if (starTime != null) 'starTime': starTime,
      if (pubDate != null) 'pubDate': pubDate,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (image != null) 'image': image,
      if (group != null) 'group': group,
      if (variable != null) 'variable': variable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssStarsCompanion copyWith({
    Value<String>? link,
    Value<String>? origin,
    Value<String>? sort,
    Value<String>? title,
    Value<int>? starTime,
    Value<String?>? pubDate,
    Value<String?>? description,
    Value<String?>? content,
    Value<String?>? image,
    Value<String?>? group,
    Value<String?>? variable,
    Value<int>? rowid,
  }) {
    return RssStarsCompanion(
      link: link ?? this.link,
      origin: origin ?? this.origin,
      sort: sort ?? this.sort,
      title: title ?? this.title,
      starTime: starTime ?? this.starTime,
      pubDate: pubDate ?? this.pubDate,
      description: description ?? this.description,
      content: content ?? this.content,
      image: image ?? this.image,
      group: group ?? this.group,
      variable: variable ?? this.variable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (sort.present) {
      map['sort'] = Variable<String>(sort.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (starTime.present) {
      map['starTime'] = Variable<int>(starTime.value);
    }
    if (pubDate.present) {
      map['pubDate'] = Variable<String>(pubDate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(group.value);
    }
    if (variable.present) {
      map['variable'] = Variable<String>(variable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssStarsCompanion(')
          ..write('link: $link, ')
          ..write('origin: $origin, ')
          ..write('sort: $sort, ')
          ..write('title: $title, ')
          ..write('starTime: $starTime, ')
          ..write('pubDate: $pubDate, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('image: $image, ')
          ..write('group: $group, ')
          ..write('variable: $variable, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServersTable extends Servers with TableInfo<$ServersTable, ServerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortNumberMeta = const VerificationMeta(
    'sortNumber',
  );
  @override
  late final GeneratedColumn<int> sortNumber = GeneratedColumn<int>(
    'sortNumber',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type, config, sortNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    }
    if (data.containsKey('sortNumber')) {
      context.handle(
        _sortNumberMeta,
        sortNumber.isAcceptableOrUnknown(data['sortNumber']!, _sortNumberMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      ),
      sortNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sortNumber'],
          )!,
    );
  }

  @override
  $ServersTable createAlias(String alias) {
    return $ServersTable(attachedDatabase, alias);
  }
}

class ServerRow extends DataClass implements Insertable<ServerRow> {
  final int id;
  final String name;
  final String type;
  final String? config;
  final int sortNumber;
  const ServerRow({
    required this.id,
    required this.name,
    required this.type,
    this.config,
    required this.sortNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || config != null) {
      map['config'] = Variable<String>(config);
    }
    map['sortNumber'] = Variable<int>(sortNumber);
    return map;
  }

  ServersCompanion toCompanion(bool nullToAbsent) {
    return ServersCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      config:
          config == null && nullToAbsent ? const Value.absent() : Value(config),
      sortNumber: Value(sortNumber),
    );
  }

  factory ServerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      config: serializer.fromJson<String?>(json['config']),
      sortNumber: serializer.fromJson<int>(json['sortNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'config': serializer.toJson<String?>(config),
      'sortNumber': serializer.toJson<int>(sortNumber),
    };
  }

  ServerRow copyWith({
    int? id,
    String? name,
    String? type,
    Value<String?> config = const Value.absent(),
    int? sortNumber,
  }) => ServerRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    config: config.present ? config.value : this.config,
    sortNumber: sortNumber ?? this.sortNumber,
  );
  ServerRow copyWithCompanion(ServersCompanion data) {
    return ServerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      config: data.config.present ? data.config.value : this.config,
      sortNumber:
          data.sortNumber.present ? data.sortNumber.value : this.sortNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('config: $config, ')
          ..write('sortNumber: $sortNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, config, sortNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.config == this.config &&
          other.sortNumber == this.sortNumber);
}

class ServersCompanion extends UpdateCompanion<ServerRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> config;
  final Value<int> sortNumber;
  const ServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.config = const Value.absent(),
    this.sortNumber = const Value.absent(),
  });
  ServersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    this.config = const Value.absent(),
    this.sortNumber = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<ServerRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? config,
    Expression<int>? sortNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (config != null) 'config': config,
      if (sortNumber != null) 'sortNumber': sortNumber,
    });
  }

  ServersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? config,
    Value<int>? sortNumber,
  }) {
    return ServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? this.config,
      sortNumber: sortNumber ?? this.sortNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (sortNumber.present) {
      map['sortNumber'] = Variable<int>(sortNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('config: $config, ')
          ..write('sortNumber: $sortNumber')
          ..write(')'))
        .toString();
  }
}

class $TxtTocRulesTable extends TxtTocRules
    with TableInfo<$TxtTocRulesTable, TxtTocRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TxtTocRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleMeta = const VerificationMeta('rule');
  @override
  late final GeneratedColumn<String> rule = GeneratedColumn<String>(
    'rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<int> serialNumber = GeneratedColumn<int>(
    'serialNumber',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _enableMeta = const VerificationMeta('enable');
  @override
  late final GeneratedColumn<int> enable = GeneratedColumn<int>(
    'enable',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    rule,
    example,
    serialNumber,
    enable,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'txt_toc_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<TxtTocRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rule')) {
      context.handle(
        _ruleMeta,
        rule.isAcceptableOrUnknown(data['rule']!, _ruleMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('serialNumber')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serialNumber']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('enable')) {
      context.handle(
        _enableMeta,
        enable.isAcceptableOrUnknown(data['enable']!, _enableMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TxtTocRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TxtTocRuleRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      rule:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}rule'],
          )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
      serialNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}serialNumber'],
          )!,
      enable:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enable'],
          )!,
    );
  }

  @override
  $TxtTocRulesTable createAlias(String alias) {
    return $TxtTocRulesTable(attachedDatabase, alias);
  }
}

class TxtTocRuleRow extends DataClass implements Insertable<TxtTocRuleRow> {
  final int id;
  final String name;
  final String rule;
  final String? example;
  final int serialNumber;
  final int enable;
  const TxtTocRuleRow({
    required this.id,
    required this.name,
    required this.rule,
    this.example,
    required this.serialNumber,
    required this.enable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['rule'] = Variable<String>(rule);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    map['serialNumber'] = Variable<int>(serialNumber);
    map['enable'] = Variable<int>(enable);
    return map;
  }

  TxtTocRulesCompanion toCompanion(bool nullToAbsent) {
    return TxtTocRulesCompanion(
      id: Value(id),
      name: Value(name),
      rule: Value(rule),
      example:
          example == null && nullToAbsent
              ? const Value.absent()
              : Value(example),
      serialNumber: Value(serialNumber),
      enable: Value(enable),
    );
  }

  factory TxtTocRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TxtTocRuleRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rule: serializer.fromJson<String>(json['rule']),
      example: serializer.fromJson<String?>(json['example']),
      serialNumber: serializer.fromJson<int>(json['serialNumber']),
      enable: serializer.fromJson<int>(json['enable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'rule': serializer.toJson<String>(rule),
      'example': serializer.toJson<String?>(example),
      'serialNumber': serializer.toJson<int>(serialNumber),
      'enable': serializer.toJson<int>(enable),
    };
  }

  TxtTocRuleRow copyWith({
    int? id,
    String? name,
    String? rule,
    Value<String?> example = const Value.absent(),
    int? serialNumber,
    int? enable,
  }) => TxtTocRuleRow(
    id: id ?? this.id,
    name: name ?? this.name,
    rule: rule ?? this.rule,
    example: example.present ? example.value : this.example,
    serialNumber: serialNumber ?? this.serialNumber,
    enable: enable ?? this.enable,
  );
  TxtTocRuleRow copyWithCompanion(TxtTocRulesCompanion data) {
    return TxtTocRuleRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rule: data.rule.present ? data.rule.value : this.rule,
      example: data.example.present ? data.example.value : this.example,
      serialNumber:
          data.serialNumber.present
              ? data.serialNumber.value
              : this.serialNumber,
      enable: data.enable.present ? data.enable.value : this.enable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TxtTocRuleRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rule: $rule, ')
          ..write('example: $example, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('enable: $enable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, rule, example, serialNumber, enable);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TxtTocRuleRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.rule == this.rule &&
          other.example == this.example &&
          other.serialNumber == this.serialNumber &&
          other.enable == this.enable);
}

class TxtTocRulesCompanion extends UpdateCompanion<TxtTocRuleRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> rule;
  final Value<String?> example;
  final Value<int> serialNumber;
  final Value<int> enable;
  const TxtTocRulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rule = const Value.absent(),
    this.example = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.enable = const Value.absent(),
  });
  TxtTocRulesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String rule,
    this.example = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.enable = const Value.absent(),
  }) : name = Value(name),
       rule = Value(rule);
  static Insertable<TxtTocRuleRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? rule,
    Expression<String>? example,
    Expression<int>? serialNumber,
    Expression<int>? enable,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rule != null) 'rule': rule,
      if (example != null) 'example': example,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (enable != null) 'enable': enable,
    });
  }

  TxtTocRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? rule,
    Value<String?>? example,
    Value<int>? serialNumber,
    Value<int>? enable,
  }) {
    return TxtTocRulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rule: rule ?? this.rule,
      example: example ?? this.example,
      serialNumber: serialNumber ?? this.serialNumber,
      enable: enable ?? this.enable,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rule.present) {
      map['rule'] = Variable<String>(rule.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (serialNumber.present) {
      map['serialNumber'] = Variable<int>(serialNumber.value);
    }
    if (enable.present) {
      map['enable'] = Variable<int>(enable.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TxtTocRulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rule: $rule, ')
          ..write('example: $example, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('enable: $enable')
          ..write(')'))
        .toString();
  }
}

class $CacheTable extends Cache with TableInfo<$CacheTable, CacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<int> deadline = GeneratedColumn<int>(
    'deadline',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, deadline];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheRow(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      deadline:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}deadline'],
          )!,
    );
  }

  @override
  $CacheTable createAlias(String alias) {
    return $CacheTable(attachedDatabase, alias);
  }
}

class CacheRow extends DataClass implements Insertable<CacheRow> {
  final String key;
  final String? value;
  final int deadline;
  const CacheRow({required this.key, this.value, required this.deadline});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['deadline'] = Variable<int>(deadline);
    return map;
  }

  CacheCompanion toCompanion(bool nullToAbsent) {
    return CacheCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      deadline: Value(deadline),
    );
  }

  factory CacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      deadline: serializer.fromJson<int>(json['deadline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'deadline': serializer.toJson<int>(deadline),
    };
  }

  CacheRow copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
    int? deadline,
  }) => CacheRow(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    deadline: deadline ?? this.deadline,
  );
  CacheRow copyWithCompanion(CacheCompanion data) {
    return CacheRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('deadline: $deadline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, deadline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.deadline == this.deadline);
}

class CacheCompanion extends UpdateCompanion<CacheRow> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> deadline;
  final Value<int> rowid;
  const CacheCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.deadline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.deadline = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<CacheRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? deadline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (deadline != null) 'deadline': deadline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? deadline,
    Value<int>? rowid,
  }) {
    return CacheCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      deadline: deadline ?? this.deadline,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<int>(deadline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('deadline: $deadline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyboardAssistsTable extends KeyboardAssists
    with TableInfo<$KeyboardAssistsTable, KeyboardAssistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyboardAssistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialNoMeta = const VerificationMeta(
    'serialNo',
  );
  @override
  late final GeneratedColumn<int> serialNo = GeneratedColumn<int>(
    'serialNo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [key, type, value, serialNo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'keyboard_assists';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyboardAssistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('serialNo')) {
      context.handle(
        _serialNoMeta,
        serialNo.isAcceptableOrUnknown(data['serialNo']!, _serialNoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyboardAssistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyboardAssistRow(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}type'],
          )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      serialNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}serialNo'],
          )!,
    );
  }

  @override
  $KeyboardAssistsTable createAlias(String alias) {
    return $KeyboardAssistsTable(attachedDatabase, alias);
  }
}

class KeyboardAssistRow extends DataClass
    implements Insertable<KeyboardAssistRow> {
  final String key;
  final int type;
  final String? value;
  final int serialNo;
  const KeyboardAssistRow({
    required this.key,
    required this.type,
    this.value,
    required this.serialNo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['type'] = Variable<int>(type);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['serialNo'] = Variable<int>(serialNo);
    return map;
  }

  KeyboardAssistsCompanion toCompanion(bool nullToAbsent) {
    return KeyboardAssistsCompanion(
      key: Value(key),
      type: Value(type),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      serialNo: Value(serialNo),
    );
  }

  factory KeyboardAssistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyboardAssistRow(
      key: serializer.fromJson<String>(json['key']),
      type: serializer.fromJson<int>(json['type']),
      value: serializer.fromJson<String?>(json['value']),
      serialNo: serializer.fromJson<int>(json['serialNo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'type': serializer.toJson<int>(type),
      'value': serializer.toJson<String?>(value),
      'serialNo': serializer.toJson<int>(serialNo),
    };
  }

  KeyboardAssistRow copyWith({
    String? key,
    int? type,
    Value<String?> value = const Value.absent(),
    int? serialNo,
  }) => KeyboardAssistRow(
    key: key ?? this.key,
    type: type ?? this.type,
    value: value.present ? value.value : this.value,
    serialNo: serialNo ?? this.serialNo,
  );
  KeyboardAssistRow copyWithCompanion(KeyboardAssistsCompanion data) {
    return KeyboardAssistRow(
      key: data.key.present ? data.key.value : this.key,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyboardAssistRow(')
          ..write('key: $key, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('serialNo: $serialNo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, type, value, serialNo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyboardAssistRow &&
          other.key == this.key &&
          other.type == this.type &&
          other.value == this.value &&
          other.serialNo == this.serialNo);
}

class KeyboardAssistsCompanion extends UpdateCompanion<KeyboardAssistRow> {
  final Value<String> key;
  final Value<int> type;
  final Value<String?> value;
  final Value<int> serialNo;
  final Value<int> rowid;
  const KeyboardAssistsCompanion({
    this.key = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyboardAssistsCompanion.insert({
    required String key,
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<KeyboardAssistRow> custom({
    Expression<String>? key,
    Expression<int>? type,
    Expression<String>? value,
    Expression<int>? serialNo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (serialNo != null) 'serialNo': serialNo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyboardAssistsCompanion copyWith({
    Value<String>? key,
    Value<int>? type,
    Value<String?>? value,
    Value<int>? serialNo,
    Value<int>? rowid,
  }) {
    return KeyboardAssistsCompanion(
      key: key ?? this.key,
      type: type ?? this.type,
      value: value ?? this.value,
      serialNo: serialNo ?? this.serialNo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (serialNo.present) {
      map['serialNo'] = Variable<int>(serialNo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyboardAssistsCompanion(')
          ..write('key: $key, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('serialNo: $serialNo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssReadRecordsTable extends RssReadRecords
    with TableInfo<$RssReadRecordsTable, RssReadRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssReadRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  @override
  late final GeneratedColumn<String> record = GeneratedColumn<String>(
    'record',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readTimeMeta = const VerificationMeta(
    'readTime',
  );
  @override
  late final GeneratedColumn<int> readTime = GeneratedColumn<int>(
    'readTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _readMeta = const VerificationMeta('read');
  @override
  late final GeneratedColumn<int> read = GeneratedColumn<int>(
    'read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [record, title, readTime, read];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_read_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssReadRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record')) {
      context.handle(
        _recordMeta,
        record.isAcceptableOrUnknown(data['record']!, _recordMeta),
      );
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('readTime')) {
      context.handle(
        _readTimeMeta,
        readTime.isAcceptableOrUnknown(data['readTime']!, _readTimeMeta),
      );
    }
    if (data.containsKey('read')) {
      context.handle(
        _readMeta,
        read.isAcceptableOrUnknown(data['read']!, _readMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {record};
  @override
  RssReadRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssReadRecordRow(
      record:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}record'],
          )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      readTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}readTime'],
          )!,
      read:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}read'],
          )!,
    );
  }

  @override
  $RssReadRecordsTable createAlias(String alias) {
    return $RssReadRecordsTable(attachedDatabase, alias);
  }
}

class RssReadRecordRow extends DataClass
    implements Insertable<RssReadRecordRow> {
  final String record;
  final String? title;
  final int readTime;
  final int read;
  const RssReadRecordRow({
    required this.record,
    this.title,
    required this.readTime,
    required this.read,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record'] = Variable<String>(record);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['readTime'] = Variable<int>(readTime);
    map['read'] = Variable<int>(read);
    return map;
  }

  RssReadRecordsCompanion toCompanion(bool nullToAbsent) {
    return RssReadRecordsCompanion(
      record: Value(record),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      readTime: Value(readTime),
      read: Value(read),
    );
  }

  factory RssReadRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssReadRecordRow(
      record: serializer.fromJson<String>(json['record']),
      title: serializer.fromJson<String?>(json['title']),
      readTime: serializer.fromJson<int>(json['readTime']),
      read: serializer.fromJson<int>(json['read']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'record': serializer.toJson<String>(record),
      'title': serializer.toJson<String?>(title),
      'readTime': serializer.toJson<int>(readTime),
      'read': serializer.toJson<int>(read),
    };
  }

  RssReadRecordRow copyWith({
    String? record,
    Value<String?> title = const Value.absent(),
    int? readTime,
    int? read,
  }) => RssReadRecordRow(
    record: record ?? this.record,
    title: title.present ? title.value : this.title,
    readTime: readTime ?? this.readTime,
    read: read ?? this.read,
  );
  RssReadRecordRow copyWithCompanion(RssReadRecordsCompanion data) {
    return RssReadRecordRow(
      record: data.record.present ? data.record.value : this.record,
      title: data.title.present ? data.title.value : this.title,
      readTime: data.readTime.present ? data.readTime.value : this.readTime,
      read: data.read.present ? data.read.value : this.read,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssReadRecordRow(')
          ..write('record: $record, ')
          ..write('title: $title, ')
          ..write('readTime: $readTime, ')
          ..write('read: $read')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(record, title, readTime, read);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssReadRecordRow &&
          other.record == this.record &&
          other.title == this.title &&
          other.readTime == this.readTime &&
          other.read == this.read);
}

class RssReadRecordsCompanion extends UpdateCompanion<RssReadRecordRow> {
  final Value<String> record;
  final Value<String?> title;
  final Value<int> readTime;
  final Value<int> read;
  final Value<int> rowid;
  const RssReadRecordsCompanion({
    this.record = const Value.absent(),
    this.title = const Value.absent(),
    this.readTime = const Value.absent(),
    this.read = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssReadRecordsCompanion.insert({
    required String record,
    this.title = const Value.absent(),
    this.readTime = const Value.absent(),
    this.read = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : record = Value(record);
  static Insertable<RssReadRecordRow> custom({
    Expression<String>? record,
    Expression<String>? title,
    Expression<int>? readTime,
    Expression<int>? read,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (record != null) 'record': record,
      if (title != null) 'title': title,
      if (readTime != null) 'readTime': readTime,
      if (read != null) 'read': read,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssReadRecordsCompanion copyWith({
    Value<String>? record,
    Value<String?>? title,
    Value<int>? readTime,
    Value<int>? read,
    Value<int>? rowid,
  }) {
    return RssReadRecordsCompanion(
      record: record ?? this.record,
      title: title ?? this.title,
      readTime: readTime ?? this.readTime,
      read: read ?? this.read,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (record.present) {
      map['record'] = Variable<String>(record.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (readTime.present) {
      map['readTime'] = Variable<int>(readTime.value);
    }
    if (read.present) {
      map['read'] = Variable<int>(read.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssReadRecordsCompanion(')
          ..write('record: $record, ')
          ..write('title: $title, ')
          ..write('readTime: $readTime, ')
          ..write('read: $read, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuleSubsTable extends RuleSubs
    with TableInfo<$RuleSubsTable, RuleSubRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleSubsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, url, type, enabled, order];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_subs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleSubRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleSubRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleSubRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      url:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}url'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}type'],
          )!,
      enabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabled'],
          )!,
      order:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}order'],
          )!,
    );
  }

  @override
  $RuleSubsTable createAlias(String alias) {
    return $RuleSubsTable(attachedDatabase, alias);
  }
}

class RuleSubRow extends DataClass implements Insertable<RuleSubRow> {
  final int id;
  final String name;
  final String url;
  final int type;
  final int enabled;
  final int order;
  const RuleSubRow({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.enabled,
    required this.order,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['type'] = Variable<int>(type);
    map['enabled'] = Variable<int>(enabled);
    map['order'] = Variable<int>(order);
    return map;
  }

  RuleSubsCompanion toCompanion(bool nullToAbsent) {
    return RuleSubsCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      type: Value(type),
      enabled: Value(enabled),
      order: Value(order),
    );
  }

  factory RuleSubRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleSubRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      type: serializer.fromJson<int>(json['type']),
      enabled: serializer.fromJson<int>(json['enabled']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'type': serializer.toJson<int>(type),
      'enabled': serializer.toJson<int>(enabled),
      'order': serializer.toJson<int>(order),
    };
  }

  RuleSubRow copyWith({
    int? id,
    String? name,
    String? url,
    int? type,
    int? enabled,
    int? order,
  }) => RuleSubRow(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    type: type ?? this.type,
    enabled: enabled ?? this.enabled,
    order: order ?? this.order,
  );
  RuleSubRow copyWithCompanion(RuleSubsCompanion data) {
    return RuleSubRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      type: data.type.present ? data.type.value : this.type,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleSubRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('type: $type, ')
          ..write('enabled: $enabled, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, url, type, enabled, order);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleSubRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.type == this.type &&
          other.enabled == this.enabled &&
          other.order == this.order);
}

class RuleSubsCompanion extends UpdateCompanion<RuleSubRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> url;
  final Value<int> type;
  final Value<int> enabled;
  final Value<int> order;
  const RuleSubsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.type = const Value.absent(),
    this.enabled = const Value.absent(),
    this.order = const Value.absent(),
  });
  RuleSubsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String url,
    this.type = const Value.absent(),
    this.enabled = const Value.absent(),
    this.order = const Value.absent(),
  }) : name = Value(name),
       url = Value(url);
  static Insertable<RuleSubRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<int>? type,
    Expression<int>? enabled,
    Expression<int>? order,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (type != null) 'type': type,
      if (enabled != null) 'enabled': enabled,
      if (order != null) 'order': order,
    });
  }

  RuleSubsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? url,
    Value<int>? type,
    Value<int>? enabled,
    Value<int>? order,
  }) {
    return RuleSubsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<int>(enabled.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleSubsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('type: $type, ')
          ..write('enabled: $enabled, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }
}

class $SourceSubscriptionsTable extends SourceSubscriptions
    with TableInfo<$SourceSubscriptionsTable, SourceSubscriptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceSubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [url, name, type, enabled, order];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceSubscriptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  SourceSubscriptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceSubscriptionRow(
      url:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}url'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}type'],
          )!,
      enabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}enabled'],
          )!,
      order:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}order'],
          )!,
    );
  }

  @override
  $SourceSubscriptionsTable createAlias(String alias) {
    return $SourceSubscriptionsTable(attachedDatabase, alias);
  }
}

class SourceSubscriptionRow extends DataClass
    implements Insertable<SourceSubscriptionRow> {
  final String url;
  final String name;
  final int type;
  final int enabled;
  final int order;
  const SourceSubscriptionRow({
    required this.url,
    required this.name,
    required this.type,
    required this.enabled,
    required this.order,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<int>(type);
    map['enabled'] = Variable<int>(enabled);
    map['order'] = Variable<int>(order);
    return map;
  }

  SourceSubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SourceSubscriptionsCompanion(
      url: Value(url),
      name: Value(name),
      type: Value(type),
      enabled: Value(enabled),
      order: Value(order),
    );
  }

  factory SourceSubscriptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceSubscriptionRow(
      url: serializer.fromJson<String>(json['url']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<int>(json['type']),
      enabled: serializer.fromJson<int>(json['enabled']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(type),
      'enabled': serializer.toJson<int>(enabled),
      'order': serializer.toJson<int>(order),
    };
  }

  SourceSubscriptionRow copyWith({
    String? url,
    String? name,
    int? type,
    int? enabled,
    int? order,
  }) => SourceSubscriptionRow(
    url: url ?? this.url,
    name: name ?? this.name,
    type: type ?? this.type,
    enabled: enabled ?? this.enabled,
    order: order ?? this.order,
  );
  SourceSubscriptionRow copyWithCompanion(SourceSubscriptionsCompanion data) {
    return SourceSubscriptionRow(
      url: data.url.present ? data.url.value : this.url,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceSubscriptionRow(')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('enabled: $enabled, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(url, name, type, enabled, order);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceSubscriptionRow &&
          other.url == this.url &&
          other.name == this.name &&
          other.type == this.type &&
          other.enabled == this.enabled &&
          other.order == this.order);
}

class SourceSubscriptionsCompanion
    extends UpdateCompanion<SourceSubscriptionRow> {
  final Value<String> url;
  final Value<String> name;
  final Value<int> type;
  final Value<int> enabled;
  final Value<int> order;
  final Value<int> rowid;
  const SourceSubscriptionsCompanion({
    this.url = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.enabled = const Value.absent(),
    this.order = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceSubscriptionsCompanion.insert({
    required String url,
    required String name,
    this.type = const Value.absent(),
    this.enabled = const Value.absent(),
    this.order = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       name = Value(name);
  static Insertable<SourceSubscriptionRow> custom({
    Expression<String>? url,
    Expression<String>? name,
    Expression<int>? type,
    Expression<int>? enabled,
    Expression<int>? order,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (enabled != null) 'enabled': enabled,
      if (order != null) 'order': order,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceSubscriptionsCompanion copyWith({
    Value<String>? url,
    Value<String>? name,
    Value<int>? type,
    Value<int>? enabled,
    Value<int>? order,
    Value<int>? rowid,
  }) {
    return SourceSubscriptionsCompanion(
      url: url ?? this.url,
      name: name ?? this.name,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<int>(enabled.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceSubscriptionsCompanion(')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('enabled: $enabled, ')
          ..write('order: $order, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchBooksTable extends SearchBooks
    with TableInfo<$SearchBooksTable, SearchBookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookUrlMeta = const VerificationMeta(
    'bookUrl',
  );
  @override
  late final GeneratedColumn<String> bookUrl = GeneratedColumn<String>(
    'bookUrl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'coverUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _introMeta = const VerificationMeta('intro');
  @override
  late final GeneratedColumn<String> intro = GeneratedColumn<String>(
    'intro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<String> wordCount = GeneratedColumn<String>(
    'wordCount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestChapterTitleMeta =
      const VerificationMeta('latestChapterTitle');
  @override
  late final GeneratedColumn<String> latestChapterTitle =
      GeneratedColumn<String>(
        'latestChapterTitle',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originNameMeta = const VerificationMeta(
    'originName',
  );
  @override
  late final GeneratedColumn<String> originName = GeneratedColumn<String>(
    'originName',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originOrderMeta = const VerificationMeta(
    'originOrder',
  );
  @override
  late final GeneratedColumn<int> originOrder = GeneratedColumn<int>(
    'originOrder',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addTimeMeta = const VerificationMeta(
    'addTime',
  );
  @override
  late final GeneratedColumn<int> addTime = GeneratedColumn<int>(
    'addTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _variableMeta = const VerificationMeta(
    'variable',
  );
  @override
  late final GeneratedColumn<String> variable = GeneratedColumn<String>(
    'variable',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tocUrlMeta = const VerificationMeta('tocUrl');
  @override
  late final GeneratedColumn<String> tocUrl = GeneratedColumn<String>(
    'tocUrl',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookUrl,
    name,
    author,
    kind,
    coverUrl,
    intro,
    wordCount,
    latestChapterTitle,
    origin,
    originName,
    originOrder,
    type,
    addTime,
    variable,
    tocUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchBookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bookUrl')) {
      context.handle(
        _bookUrlMeta,
        bookUrl.isAcceptableOrUnknown(data['bookUrl']!, _bookUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bookUrlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('coverUrl')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['coverUrl']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('intro')) {
      context.handle(
        _introMeta,
        intro.isAcceptableOrUnknown(data['intro']!, _introMeta),
      );
    }
    if (data.containsKey('wordCount')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['wordCount']!, _wordCountMeta),
      );
    }
    if (data.containsKey('latestChapterTitle')) {
      context.handle(
        _latestChapterTitleMeta,
        latestChapterTitle.isAcceptableOrUnknown(
          data['latestChapterTitle']!,
          _latestChapterTitleMeta,
        ),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('originName')) {
      context.handle(
        _originNameMeta,
        originName.isAcceptableOrUnknown(data['originName']!, _originNameMeta),
      );
    }
    if (data.containsKey('originOrder')) {
      context.handle(
        _originOrderMeta,
        originOrder.isAcceptableOrUnknown(
          data['originOrder']!,
          _originOrderMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('addTime')) {
      context.handle(
        _addTimeMeta,
        addTime.isAcceptableOrUnknown(data['addTime']!, _addTimeMeta),
      );
    }
    if (data.containsKey('variable')) {
      context.handle(
        _variableMeta,
        variable.isAcceptableOrUnknown(data['variable']!, _variableMeta),
      );
    }
    if (data.containsKey('tocUrl')) {
      context.handle(
        _tocUrlMeta,
        tocUrl.isAcceptableOrUnknown(data['tocUrl']!, _tocUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookUrl};
  @override
  SearchBookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchBookRow(
      bookUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookUrl'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coverUrl'],
      ),
      intro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intro'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wordCount'],
      ),
      latestChapterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latestChapterTitle'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      originName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}originName'],
      ),
      originOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}originOrder'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}type'],
          )!,
      addTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}addTime'],
          )!,
      variable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variable'],
      ),
      tocUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tocUrl'],
      ),
    );
  }

  @override
  $SearchBooksTable createAlias(String alias) {
    return $SearchBooksTable(attachedDatabase, alias);
  }
}

class SearchBookRow extends DataClass implements Insertable<SearchBookRow> {
  final String bookUrl;
  final String name;
  final String? author;
  final String? kind;
  final String? coverUrl;
  final String? intro;
  final String? wordCount;
  final String? latestChapterTitle;
  final String? origin;
  final String? originName;
  final int originOrder;
  final int type;
  final int addTime;
  final String? variable;
  final String? tocUrl;
  const SearchBookRow({
    required this.bookUrl,
    required this.name,
    this.author,
    this.kind,
    this.coverUrl,
    this.intro,
    this.wordCount,
    this.latestChapterTitle,
    this.origin,
    this.originName,
    required this.originOrder,
    required this.type,
    required this.addTime,
    this.variable,
    this.tocUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bookUrl'] = Variable<String>(bookUrl);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['coverUrl'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || intro != null) {
      map['intro'] = Variable<String>(intro);
    }
    if (!nullToAbsent || wordCount != null) {
      map['wordCount'] = Variable<String>(wordCount);
    }
    if (!nullToAbsent || latestChapterTitle != null) {
      map['latestChapterTitle'] = Variable<String>(latestChapterTitle);
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || originName != null) {
      map['originName'] = Variable<String>(originName);
    }
    map['originOrder'] = Variable<int>(originOrder);
    map['type'] = Variable<int>(type);
    map['addTime'] = Variable<int>(addTime);
    if (!nullToAbsent || variable != null) {
      map['variable'] = Variable<String>(variable);
    }
    if (!nullToAbsent || tocUrl != null) {
      map['tocUrl'] = Variable<String>(tocUrl);
    }
    return map;
  }

  SearchBooksCompanion toCompanion(bool nullToAbsent) {
    return SearchBooksCompanion(
      bookUrl: Value(bookUrl),
      name: Value(name),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      coverUrl:
          coverUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(coverUrl),
      intro:
          intro == null && nullToAbsent ? const Value.absent() : Value(intro),
      wordCount:
          wordCount == null && nullToAbsent
              ? const Value.absent()
              : Value(wordCount),
      latestChapterTitle:
          latestChapterTitle == null && nullToAbsent
              ? const Value.absent()
              : Value(latestChapterTitle),
      origin:
          origin == null && nullToAbsent ? const Value.absent() : Value(origin),
      originName:
          originName == null && nullToAbsent
              ? const Value.absent()
              : Value(originName),
      originOrder: Value(originOrder),
      type: Value(type),
      addTime: Value(addTime),
      variable:
          variable == null && nullToAbsent
              ? const Value.absent()
              : Value(variable),
      tocUrl:
          tocUrl == null && nullToAbsent ? const Value.absent() : Value(tocUrl),
    );
  }

  factory SearchBookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchBookRow(
      bookUrl: serializer.fromJson<String>(json['bookUrl']),
      name: serializer.fromJson<String>(json['name']),
      author: serializer.fromJson<String?>(json['author']),
      kind: serializer.fromJson<String?>(json['kind']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      intro: serializer.fromJson<String?>(json['intro']),
      wordCount: serializer.fromJson<String?>(json['wordCount']),
      latestChapterTitle: serializer.fromJson<String?>(
        json['latestChapterTitle'],
      ),
      origin: serializer.fromJson<String?>(json['origin']),
      originName: serializer.fromJson<String?>(json['originName']),
      originOrder: serializer.fromJson<int>(json['originOrder']),
      type: serializer.fromJson<int>(json['type']),
      addTime: serializer.fromJson<int>(json['addTime']),
      variable: serializer.fromJson<String?>(json['variable']),
      tocUrl: serializer.fromJson<String?>(json['tocUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookUrl': serializer.toJson<String>(bookUrl),
      'name': serializer.toJson<String>(name),
      'author': serializer.toJson<String?>(author),
      'kind': serializer.toJson<String?>(kind),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'intro': serializer.toJson<String?>(intro),
      'wordCount': serializer.toJson<String?>(wordCount),
      'latestChapterTitle': serializer.toJson<String?>(latestChapterTitle),
      'origin': serializer.toJson<String?>(origin),
      'originName': serializer.toJson<String?>(originName),
      'originOrder': serializer.toJson<int>(originOrder),
      'type': serializer.toJson<int>(type),
      'addTime': serializer.toJson<int>(addTime),
      'variable': serializer.toJson<String?>(variable),
      'tocUrl': serializer.toJson<String?>(tocUrl),
    };
  }

  SearchBookRow copyWith({
    String? bookUrl,
    String? name,
    Value<String?> author = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> intro = const Value.absent(),
    Value<String?> wordCount = const Value.absent(),
    Value<String?> latestChapterTitle = const Value.absent(),
    Value<String?> origin = const Value.absent(),
    Value<String?> originName = const Value.absent(),
    int? originOrder,
    int? type,
    int? addTime,
    Value<String?> variable = const Value.absent(),
    Value<String?> tocUrl = const Value.absent(),
  }) => SearchBookRow(
    bookUrl: bookUrl ?? this.bookUrl,
    name: name ?? this.name,
    author: author.present ? author.value : this.author,
    kind: kind.present ? kind.value : this.kind,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    intro: intro.present ? intro.value : this.intro,
    wordCount: wordCount.present ? wordCount.value : this.wordCount,
    latestChapterTitle:
        latestChapterTitle.present
            ? latestChapterTitle.value
            : this.latestChapterTitle,
    origin: origin.present ? origin.value : this.origin,
    originName: originName.present ? originName.value : this.originName,
    originOrder: originOrder ?? this.originOrder,
    type: type ?? this.type,
    addTime: addTime ?? this.addTime,
    variable: variable.present ? variable.value : this.variable,
    tocUrl: tocUrl.present ? tocUrl.value : this.tocUrl,
  );
  SearchBookRow copyWithCompanion(SearchBooksCompanion data) {
    return SearchBookRow(
      bookUrl: data.bookUrl.present ? data.bookUrl.value : this.bookUrl,
      name: data.name.present ? data.name.value : this.name,
      author: data.author.present ? data.author.value : this.author,
      kind: data.kind.present ? data.kind.value : this.kind,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      intro: data.intro.present ? data.intro.value : this.intro,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      latestChapterTitle:
          data.latestChapterTitle.present
              ? data.latestChapterTitle.value
              : this.latestChapterTitle,
      origin: data.origin.present ? data.origin.value : this.origin,
      originName:
          data.originName.present ? data.originName.value : this.originName,
      originOrder:
          data.originOrder.present ? data.originOrder.value : this.originOrder,
      type: data.type.present ? data.type.value : this.type,
      addTime: data.addTime.present ? data.addTime.value : this.addTime,
      variable: data.variable.present ? data.variable.value : this.variable,
      tocUrl: data.tocUrl.present ? data.tocUrl.value : this.tocUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchBookRow(')
          ..write('bookUrl: $bookUrl, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('intro: $intro, ')
          ..write('wordCount: $wordCount, ')
          ..write('latestChapterTitle: $latestChapterTitle, ')
          ..write('origin: $origin, ')
          ..write('originName: $originName, ')
          ..write('originOrder: $originOrder, ')
          ..write('type: $type, ')
          ..write('addTime: $addTime, ')
          ..write('variable: $variable, ')
          ..write('tocUrl: $tocUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookUrl,
    name,
    author,
    kind,
    coverUrl,
    intro,
    wordCount,
    latestChapterTitle,
    origin,
    originName,
    originOrder,
    type,
    addTime,
    variable,
    tocUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchBookRow &&
          other.bookUrl == this.bookUrl &&
          other.name == this.name &&
          other.author == this.author &&
          other.kind == this.kind &&
          other.coverUrl == this.coverUrl &&
          other.intro == this.intro &&
          other.wordCount == this.wordCount &&
          other.latestChapterTitle == this.latestChapterTitle &&
          other.origin == this.origin &&
          other.originName == this.originName &&
          other.originOrder == this.originOrder &&
          other.type == this.type &&
          other.addTime == this.addTime &&
          other.variable == this.variable &&
          other.tocUrl == this.tocUrl);
}

class SearchBooksCompanion extends UpdateCompanion<SearchBookRow> {
  final Value<String> bookUrl;
  final Value<String> name;
  final Value<String?> author;
  final Value<String?> kind;
  final Value<String?> coverUrl;
  final Value<String?> intro;
  final Value<String?> wordCount;
  final Value<String?> latestChapterTitle;
  final Value<String?> origin;
  final Value<String?> originName;
  final Value<int> originOrder;
  final Value<int> type;
  final Value<int> addTime;
  final Value<String?> variable;
  final Value<String?> tocUrl;
  final Value<int> rowid;
  const SearchBooksCompanion({
    this.bookUrl = const Value.absent(),
    this.name = const Value.absent(),
    this.author = const Value.absent(),
    this.kind = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.intro = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.latestChapterTitle = const Value.absent(),
    this.origin = const Value.absent(),
    this.originName = const Value.absent(),
    this.originOrder = const Value.absent(),
    this.type = const Value.absent(),
    this.addTime = const Value.absent(),
    this.variable = const Value.absent(),
    this.tocUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchBooksCompanion.insert({
    required String bookUrl,
    required String name,
    this.author = const Value.absent(),
    this.kind = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.intro = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.latestChapterTitle = const Value.absent(),
    this.origin = const Value.absent(),
    this.originName = const Value.absent(),
    this.originOrder = const Value.absent(),
    this.type = const Value.absent(),
    this.addTime = const Value.absent(),
    this.variable = const Value.absent(),
    this.tocUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookUrl = Value(bookUrl),
       name = Value(name);
  static Insertable<SearchBookRow> custom({
    Expression<String>? bookUrl,
    Expression<String>? name,
    Expression<String>? author,
    Expression<String>? kind,
    Expression<String>? coverUrl,
    Expression<String>? intro,
    Expression<String>? wordCount,
    Expression<String>? latestChapterTitle,
    Expression<String>? origin,
    Expression<String>? originName,
    Expression<int>? originOrder,
    Expression<int>? type,
    Expression<int>? addTime,
    Expression<String>? variable,
    Expression<String>? tocUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookUrl != null) 'bookUrl': bookUrl,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (kind != null) 'kind': kind,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (intro != null) 'intro': intro,
      if (wordCount != null) 'wordCount': wordCount,
      if (latestChapterTitle != null) 'latestChapterTitle': latestChapterTitle,
      if (origin != null) 'origin': origin,
      if (originName != null) 'originName': originName,
      if (originOrder != null) 'originOrder': originOrder,
      if (type != null) 'type': type,
      if (addTime != null) 'addTime': addTime,
      if (variable != null) 'variable': variable,
      if (tocUrl != null) 'tocUrl': tocUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchBooksCompanion copyWith({
    Value<String>? bookUrl,
    Value<String>? name,
    Value<String?>? author,
    Value<String?>? kind,
    Value<String?>? coverUrl,
    Value<String?>? intro,
    Value<String?>? wordCount,
    Value<String?>? latestChapterTitle,
    Value<String?>? origin,
    Value<String?>? originName,
    Value<int>? originOrder,
    Value<int>? type,
    Value<int>? addTime,
    Value<String?>? variable,
    Value<String?>? tocUrl,
    Value<int>? rowid,
  }) {
    return SearchBooksCompanion(
      bookUrl: bookUrl ?? this.bookUrl,
      name: name ?? this.name,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      coverUrl: coverUrl ?? this.coverUrl,
      intro: intro ?? this.intro,
      wordCount: wordCount ?? this.wordCount,
      latestChapterTitle: latestChapterTitle ?? this.latestChapterTitle,
      origin: origin ?? this.origin,
      originName: originName ?? this.originName,
      originOrder: originOrder ?? this.originOrder,
      type: type ?? this.type,
      addTime: addTime ?? this.addTime,
      variable: variable ?? this.variable,
      tocUrl: tocUrl ?? this.tocUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookUrl.present) {
      map['bookUrl'] = Variable<String>(bookUrl.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (coverUrl.present) {
      map['coverUrl'] = Variable<String>(coverUrl.value);
    }
    if (intro.present) {
      map['intro'] = Variable<String>(intro.value);
    }
    if (wordCount.present) {
      map['wordCount'] = Variable<String>(wordCount.value);
    }
    if (latestChapterTitle.present) {
      map['latestChapterTitle'] = Variable<String>(latestChapterTitle.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (originName.present) {
      map['originName'] = Variable<String>(originName.value);
    }
    if (originOrder.present) {
      map['originOrder'] = Variable<int>(originOrder.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (addTime.present) {
      map['addTime'] = Variable<int>(addTime.value);
    }
    if (variable.present) {
      map['variable'] = Variable<String>(variable.value);
    }
    if (tocUrl.present) {
      map['tocUrl'] = Variable<String>(tocUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchBooksCompanion(')
          ..write('bookUrl: $bookUrl, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('intro: $intro, ')
          ..write('wordCount: $wordCount, ')
          ..write('latestChapterTitle: $latestChapterTitle, ')
          ..write('origin: $origin, ')
          ..write('originName: $originName, ')
          ..write('originOrder: $originOrder, ')
          ..write('type: $type, ')
          ..write('addTime: $addTime, ')
          ..write('variable: $variable, ')
          ..write('tocUrl: $tocUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadTasksTable extends DownloadTasks
    with TableInfo<$DownloadTasksTable, DownloadTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookUrlMeta = const VerificationMeta(
    'bookUrl',
  );
  @override
  late final GeneratedColumn<String> bookUrl = GeneratedColumn<String>(
    'bookUrl',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'bookName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentChapterIndexMeta =
      const VerificationMeta('currentChapterIndex');
  @override
  late final GeneratedColumn<int> currentChapterIndex = GeneratedColumn<int>(
    'currentChapterIndex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalChapterCountMeta = const VerificationMeta(
    'totalChapterCount',
  );
  @override
  late final GeneratedColumn<int> totalChapterCount = GeneratedColumn<int>(
    'totalChapterCount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _successCountMeta = const VerificationMeta(
    'successCount',
  );
  @override
  late final GeneratedColumn<int> successCount = GeneratedColumn<int>(
    'successCount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorCountMeta = const VerificationMeta(
    'errorCount',
  );
  @override
  late final GeneratedColumn<int> errorCount = GeneratedColumn<int>(
    'errorCount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addTimeMeta = const VerificationMeta(
    'addTime',
  );
  @override
  late final GeneratedColumn<int> addTime = GeneratedColumn<int>(
    'addTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookUrl,
    bookName,
    currentChapterIndex,
    totalChapterCount,
    status,
    successCount,
    errorCount,
    addTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bookUrl')) {
      context.handle(
        _bookUrlMeta,
        bookUrl.isAcceptableOrUnknown(data['bookUrl']!, _bookUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bookUrlMeta);
    }
    if (data.containsKey('bookName')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['bookName']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('currentChapterIndex')) {
      context.handle(
        _currentChapterIndexMeta,
        currentChapterIndex.isAcceptableOrUnknown(
          data['currentChapterIndex']!,
          _currentChapterIndexMeta,
        ),
      );
    }
    if (data.containsKey('totalChapterCount')) {
      context.handle(
        _totalChapterCountMeta,
        totalChapterCount.isAcceptableOrUnknown(
          data['totalChapterCount']!,
          _totalChapterCountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('successCount')) {
      context.handle(
        _successCountMeta,
        successCount.isAcceptableOrUnknown(
          data['successCount']!,
          _successCountMeta,
        ),
      );
    }
    if (data.containsKey('errorCount')) {
      context.handle(
        _errorCountMeta,
        errorCount.isAcceptableOrUnknown(data['errorCount']!, _errorCountMeta),
      );
    }
    if (data.containsKey('addTime')) {
      context.handle(
        _addTimeMeta,
        addTime.isAcceptableOrUnknown(data['addTime']!, _addTimeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookUrl};
  @override
  DownloadTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadTaskRow(
      bookUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookUrl'],
          )!,
      bookName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}bookName'],
          )!,
      currentChapterIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}currentChapterIndex'],
          )!,
      totalChapterCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}totalChapterCount'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}status'],
          )!,
      successCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}successCount'],
          )!,
      errorCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}errorCount'],
          )!,
      addTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}addTime'],
          )!,
    );
  }

  @override
  $DownloadTasksTable createAlias(String alias) {
    return $DownloadTasksTable(attachedDatabase, alias);
  }
}

class DownloadTaskRow extends DataClass implements Insertable<DownloadTaskRow> {
  final String bookUrl;
  final String bookName;
  final int currentChapterIndex;
  final int totalChapterCount;
  final int status;
  final int successCount;
  final int errorCount;
  final int addTime;
  const DownloadTaskRow({
    required this.bookUrl,
    required this.bookName,
    required this.currentChapterIndex,
    required this.totalChapterCount,
    required this.status,
    required this.successCount,
    required this.errorCount,
    required this.addTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bookUrl'] = Variable<String>(bookUrl);
    map['bookName'] = Variable<String>(bookName);
    map['currentChapterIndex'] = Variable<int>(currentChapterIndex);
    map['totalChapterCount'] = Variable<int>(totalChapterCount);
    map['status'] = Variable<int>(status);
    map['successCount'] = Variable<int>(successCount);
    map['errorCount'] = Variable<int>(errorCount);
    map['addTime'] = Variable<int>(addTime);
    return map;
  }

  DownloadTasksCompanion toCompanion(bool nullToAbsent) {
    return DownloadTasksCompanion(
      bookUrl: Value(bookUrl),
      bookName: Value(bookName),
      currentChapterIndex: Value(currentChapterIndex),
      totalChapterCount: Value(totalChapterCount),
      status: Value(status),
      successCount: Value(successCount),
      errorCount: Value(errorCount),
      addTime: Value(addTime),
    );
  }

  factory DownloadTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadTaskRow(
      bookUrl: serializer.fromJson<String>(json['bookUrl']),
      bookName: serializer.fromJson<String>(json['bookName']),
      currentChapterIndex: serializer.fromJson<int>(
        json['currentChapterIndex'],
      ),
      totalChapterCount: serializer.fromJson<int>(json['totalChapterCount']),
      status: serializer.fromJson<int>(json['status']),
      successCount: serializer.fromJson<int>(json['successCount']),
      errorCount: serializer.fromJson<int>(json['errorCount']),
      addTime: serializer.fromJson<int>(json['addTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookUrl': serializer.toJson<String>(bookUrl),
      'bookName': serializer.toJson<String>(bookName),
      'currentChapterIndex': serializer.toJson<int>(currentChapterIndex),
      'totalChapterCount': serializer.toJson<int>(totalChapterCount),
      'status': serializer.toJson<int>(status),
      'successCount': serializer.toJson<int>(successCount),
      'errorCount': serializer.toJson<int>(errorCount),
      'addTime': serializer.toJson<int>(addTime),
    };
  }

  DownloadTaskRow copyWith({
    String? bookUrl,
    String? bookName,
    int? currentChapterIndex,
    int? totalChapterCount,
    int? status,
    int? successCount,
    int? errorCount,
    int? addTime,
  }) => DownloadTaskRow(
    bookUrl: bookUrl ?? this.bookUrl,
    bookName: bookName ?? this.bookName,
    currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
    totalChapterCount: totalChapterCount ?? this.totalChapterCount,
    status: status ?? this.status,
    successCount: successCount ?? this.successCount,
    errorCount: errorCount ?? this.errorCount,
    addTime: addTime ?? this.addTime,
  );
  DownloadTaskRow copyWithCompanion(DownloadTasksCompanion data) {
    return DownloadTaskRow(
      bookUrl: data.bookUrl.present ? data.bookUrl.value : this.bookUrl,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      currentChapterIndex:
          data.currentChapterIndex.present
              ? data.currentChapterIndex.value
              : this.currentChapterIndex,
      totalChapterCount:
          data.totalChapterCount.present
              ? data.totalChapterCount.value
              : this.totalChapterCount,
      status: data.status.present ? data.status.value : this.status,
      successCount:
          data.successCount.present
              ? data.successCount.value
              : this.successCount,
      errorCount:
          data.errorCount.present ? data.errorCount.value : this.errorCount,
      addTime: data.addTime.present ? data.addTime.value : this.addTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTaskRow(')
          ..write('bookUrl: $bookUrl, ')
          ..write('bookName: $bookName, ')
          ..write('currentChapterIndex: $currentChapterIndex, ')
          ..write('totalChapterCount: $totalChapterCount, ')
          ..write('status: $status, ')
          ..write('successCount: $successCount, ')
          ..write('errorCount: $errorCount, ')
          ..write('addTime: $addTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookUrl,
    bookName,
    currentChapterIndex,
    totalChapterCount,
    status,
    successCount,
    errorCount,
    addTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadTaskRow &&
          other.bookUrl == this.bookUrl &&
          other.bookName == this.bookName &&
          other.currentChapterIndex == this.currentChapterIndex &&
          other.totalChapterCount == this.totalChapterCount &&
          other.status == this.status &&
          other.successCount == this.successCount &&
          other.errorCount == this.errorCount &&
          other.addTime == this.addTime);
}

class DownloadTasksCompanion extends UpdateCompanion<DownloadTaskRow> {
  final Value<String> bookUrl;
  final Value<String> bookName;
  final Value<int> currentChapterIndex;
  final Value<int> totalChapterCount;
  final Value<int> status;
  final Value<int> successCount;
  final Value<int> errorCount;
  final Value<int> addTime;
  final Value<int> rowid;
  const DownloadTasksCompanion({
    this.bookUrl = const Value.absent(),
    this.bookName = const Value.absent(),
    this.currentChapterIndex = const Value.absent(),
    this.totalChapterCount = const Value.absent(),
    this.status = const Value.absent(),
    this.successCount = const Value.absent(),
    this.errorCount = const Value.absent(),
    this.addTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadTasksCompanion.insert({
    required String bookUrl,
    required String bookName,
    this.currentChapterIndex = const Value.absent(),
    this.totalChapterCount = const Value.absent(),
    this.status = const Value.absent(),
    this.successCount = const Value.absent(),
    this.errorCount = const Value.absent(),
    this.addTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookUrl = Value(bookUrl),
       bookName = Value(bookName);
  static Insertable<DownloadTaskRow> custom({
    Expression<String>? bookUrl,
    Expression<String>? bookName,
    Expression<int>? currentChapterIndex,
    Expression<int>? totalChapterCount,
    Expression<int>? status,
    Expression<int>? successCount,
    Expression<int>? errorCount,
    Expression<int>? addTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookUrl != null) 'bookUrl': bookUrl,
      if (bookName != null) 'bookName': bookName,
      if (currentChapterIndex != null)
        'currentChapterIndex': currentChapterIndex,
      if (totalChapterCount != null) 'totalChapterCount': totalChapterCount,
      if (status != null) 'status': status,
      if (successCount != null) 'successCount': successCount,
      if (errorCount != null) 'errorCount': errorCount,
      if (addTime != null) 'addTime': addTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadTasksCompanion copyWith({
    Value<String>? bookUrl,
    Value<String>? bookName,
    Value<int>? currentChapterIndex,
    Value<int>? totalChapterCount,
    Value<int>? status,
    Value<int>? successCount,
    Value<int>? errorCount,
    Value<int>? addTime,
    Value<int>? rowid,
  }) {
    return DownloadTasksCompanion(
      bookUrl: bookUrl ?? this.bookUrl,
      bookName: bookName ?? this.bookName,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      totalChapterCount: totalChapterCount ?? this.totalChapterCount,
      status: status ?? this.status,
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
      addTime: addTime ?? this.addTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookUrl.present) {
      map['bookUrl'] = Variable<String>(bookUrl.value);
    }
    if (bookName.present) {
      map['bookName'] = Variable<String>(bookName.value);
    }
    if (currentChapterIndex.present) {
      map['currentChapterIndex'] = Variable<int>(currentChapterIndex.value);
    }
    if (totalChapterCount.present) {
      map['totalChapterCount'] = Variable<int>(totalChapterCount.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (successCount.present) {
      map['successCount'] = Variable<int>(successCount.value);
    }
    if (errorCount.present) {
      map['errorCount'] = Variable<int>(errorCount.value);
    }
    if (addTime.present) {
      map['addTime'] = Variable<int>(addTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTasksCompanion(')
          ..write('bookUrl: $bookUrl, ')
          ..write('bookName: $bookName, ')
          ..write('currentChapterIndex: $currentChapterIndex, ')
          ..write('totalChapterCount: $totalChapterCount, ')
          ..write('status: $status, ')
          ..write('successCount: $successCount, ')
          ..write('errorCount: $errorCount, ')
          ..write('addTime: $addTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchKeywordsTable extends SearchKeywords
    with TableInfo<$SearchKeywordsTable, SearchKeywordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchKeywordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usageMeta = const VerificationMeta('usage');
  @override
  late final GeneratedColumn<int> usage = GeneratedColumn<int>(
    'usage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUseTimeMeta = const VerificationMeta(
    'lastUseTime',
  );
  @override
  late final GeneratedColumn<int> lastUseTime = GeneratedColumn<int>(
    'lastUseTime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [word, usage, lastUseTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_keywords';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchKeywordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('usage')) {
      context.handle(
        _usageMeta,
        usage.isAcceptableOrUnknown(data['usage']!, _usageMeta),
      );
    }
    if (data.containsKey('lastUseTime')) {
      context.handle(
        _lastUseTimeMeta,
        lastUseTime.isAcceptableOrUnknown(
          data['lastUseTime']!,
          _lastUseTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word};
  @override
  SearchKeywordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchKeywordRow(
      word:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}word'],
          )!,
      usage:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}usage'],
          )!,
      lastUseTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}lastUseTime'],
          )!,
    );
  }

  @override
  $SearchKeywordsTable createAlias(String alias) {
    return $SearchKeywordsTable(attachedDatabase, alias);
  }
}

class SearchKeywordRow extends DataClass
    implements Insertable<SearchKeywordRow> {
  final String word;
  final int usage;
  final int lastUseTime;
  const SearchKeywordRow({
    required this.word,
    required this.usage,
    required this.lastUseTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['usage'] = Variable<int>(usage);
    map['lastUseTime'] = Variable<int>(lastUseTime);
    return map;
  }

  SearchKeywordsCompanion toCompanion(bool nullToAbsent) {
    return SearchKeywordsCompanion(
      word: Value(word),
      usage: Value(usage),
      lastUseTime: Value(lastUseTime),
    );
  }

  factory SearchKeywordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchKeywordRow(
      word: serializer.fromJson<String>(json['word']),
      usage: serializer.fromJson<int>(json['usage']),
      lastUseTime: serializer.fromJson<int>(json['lastUseTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'usage': serializer.toJson<int>(usage),
      'lastUseTime': serializer.toJson<int>(lastUseTime),
    };
  }

  SearchKeywordRow copyWith({String? word, int? usage, int? lastUseTime}) =>
      SearchKeywordRow(
        word: word ?? this.word,
        usage: usage ?? this.usage,
        lastUseTime: lastUseTime ?? this.lastUseTime,
      );
  SearchKeywordRow copyWithCompanion(SearchKeywordsCompanion data) {
    return SearchKeywordRow(
      word: data.word.present ? data.word.value : this.word,
      usage: data.usage.present ? data.usage.value : this.usage,
      lastUseTime:
          data.lastUseTime.present ? data.lastUseTime.value : this.lastUseTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchKeywordRow(')
          ..write('word: $word, ')
          ..write('usage: $usage, ')
          ..write('lastUseTime: $lastUseTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(word, usage, lastUseTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchKeywordRow &&
          other.word == this.word &&
          other.usage == this.usage &&
          other.lastUseTime == this.lastUseTime);
}

class SearchKeywordsCompanion extends UpdateCompanion<SearchKeywordRow> {
  final Value<String> word;
  final Value<int> usage;
  final Value<int> lastUseTime;
  final Value<int> rowid;
  const SearchKeywordsCompanion({
    this.word = const Value.absent(),
    this.usage = const Value.absent(),
    this.lastUseTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchKeywordsCompanion.insert({
    required String word,
    this.usage = const Value.absent(),
    this.lastUseTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : word = Value(word);
  static Insertable<SearchKeywordRow> custom({
    Expression<String>? word,
    Expression<int>? usage,
    Expression<int>? lastUseTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (usage != null) 'usage': usage,
      if (lastUseTime != null) 'lastUseTime': lastUseTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchKeywordsCompanion copyWith({
    Value<String>? word,
    Value<int>? usage,
    Value<int>? lastUseTime,
    Value<int>? rowid,
  }) {
    return SearchKeywordsCompanion(
      word: word ?? this.word,
      usage: usage ?? this.usage,
      lastUseTime: lastUseTime ?? this.lastUseTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (usage.present) {
      map['usage'] = Variable<int>(usage.value);
    }
    if (lastUseTime.present) {
      map['lastUseTime'] = Variable<int>(lastUseTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchKeywordsCompanion(')
          ..write('word: $word, ')
          ..write('usage: $usage, ')
          ..write('lastUseTime: $lastUseTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $BookSourcesTable bookSources = $BookSourcesTable(this);
  late final $BookGroupsTable bookGroups = $BookGroupsTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  late final $ReplaceRulesTable replaceRules = $ReplaceRulesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $CookiesTable cookies = $CookiesTable(this);
  late final $DictRulesTable dictRules = $DictRulesTable(this);
  late final $HttpTtsTable httpTts = $HttpTtsTable(this);
  late final $ReadRecordsTable readRecords = $ReadRecordsTable(this);
  late final $RssArticlesTable rssArticles = $RssArticlesTable(this);
  late final $RssSourcesTable rssSources = $RssSourcesTable(this);
  late final $RssStarsTable rssStars = $RssStarsTable(this);
  late final $ServersTable servers = $ServersTable(this);
  late final $TxtTocRulesTable txtTocRules = $TxtTocRulesTable(this);
  late final $CacheTable cache = $CacheTable(this);
  late final $KeyboardAssistsTable keyboardAssists = $KeyboardAssistsTable(
    this,
  );
  late final $RssReadRecordsTable rssReadRecords = $RssReadRecordsTable(this);
  late final $RuleSubsTable ruleSubs = $RuleSubsTable(this);
  late final $SourceSubscriptionsTable sourceSubscriptions =
      $SourceSubscriptionsTable(this);
  late final $SearchBooksTable searchBooks = $SearchBooksTable(this);
  late final $DownloadTasksTable downloadTasks = $DownloadTasksTable(this);
  late final $SearchKeywordsTable searchKeywords = $SearchKeywordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    chapters,
    bookSources,
    bookGroups,
    searchHistory,
    replaceRules,
    bookmarks,
    cookies,
    dictRules,
    httpTts,
    readRecords,
    rssArticles,
    rssSources,
    rssStars,
    servers,
    txtTocRules,
    cache,
    keyboardAssists,
    rssReadRecords,
    ruleSubs,
    sourceSubscriptions,
    searchBooks,
    downloadTasks,
    searchKeywords,
  ];
}

typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      required String bookUrl,
      Value<String?> tocUrl,
      Value<String?> origin,
      Value<String?> originName,
      required String name,
      Value<String?> author,
      Value<String?> kind,
      Value<String?> customTag,
      Value<String?> coverUrl,
      Value<String?> customCoverUrl,
      Value<String?> intro,
      Value<String?> customIntro,
      Value<String?> charset,
      Value<int> type,
      Value<int> group,
      Value<String?> latestChapterTitle,
      Value<int> latestChapterTime,
      Value<int> lastCheckTime,
      Value<int> lastCheckCount,
      Value<int> totalChapterNum,
      Value<String?> durChapterTitle,
      Value<int> durChapterIndex,
      Value<int> durChapterPos,
      Value<int> durChapterTime,
      Value<String?> wordCount,
      Value<int> canUpdate,
      Value<int> order,
      Value<int> originOrder,
      Value<String?> variable,
      Value<String?> readConfig,
      Value<int> syncTime,
      Value<int> isInBookshelf,
      Value<int> rowid,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<String> bookUrl,
      Value<String?> tocUrl,
      Value<String?> origin,
      Value<String?> originName,
      Value<String> name,
      Value<String?> author,
      Value<String?> kind,
      Value<String?> customTag,
      Value<String?> coverUrl,
      Value<String?> customCoverUrl,
      Value<String?> intro,
      Value<String?> customIntro,
      Value<String?> charset,
      Value<int> type,
      Value<int> group,
      Value<String?> latestChapterTitle,
      Value<int> latestChapterTime,
      Value<int> lastCheckTime,
      Value<int> lastCheckCount,
      Value<int> totalChapterNum,
      Value<String?> durChapterTitle,
      Value<int> durChapterIndex,
      Value<int> durChapterPos,
      Value<int> durChapterTime,
      Value<String?> wordCount,
      Value<int> canUpdate,
      Value<int> order,
      Value<int> originOrder,
      Value<String?> variable,
      Value<String?> readConfig,
      Value<int> syncTime,
      Value<int> isInBookshelf,
      Value<int> rowid,
    });

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tocUrl => $composableBuilder(
    column: $table.tocUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customTag => $composableBuilder(
    column: $table.customTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customCoverUrl => $composableBuilder(
    column: $table.customCoverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intro => $composableBuilder(
    column: $table.intro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customIntro => $composableBuilder(
    column: $table.customIntro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get charset => $composableBuilder(
    column: $table.charset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestChapterTitle => $composableBuilder(
    column: $table.latestChapterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestChapterTime => $composableBuilder(
    column: $table.latestChapterTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCheckTime => $composableBuilder(
    column: $table.lastCheckTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCheckCount => $composableBuilder(
    column: $table.lastCheckCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChapterNum => $composableBuilder(
    column: $table.totalChapterNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get durChapterTitle => $composableBuilder(
    column: $table.durChapterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durChapterIndex => $composableBuilder(
    column: $table.durChapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durChapterPos => $composableBuilder(
    column: $table.durChapterPos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durChapterTime => $composableBuilder(
    column: $table.durChapterTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get canUpdate => $composableBuilder(
    column: $table.canUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originOrder => $composableBuilder(
    column: $table.originOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readConfig => $composableBuilder(
    column: $table.readConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncTime => $composableBuilder(
    column: $table.syncTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isInBookshelf => $composableBuilder(
    column: $table.isInBookshelf,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tocUrl => $composableBuilder(
    column: $table.tocUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customTag => $composableBuilder(
    column: $table.customTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customCoverUrl => $composableBuilder(
    column: $table.customCoverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intro => $composableBuilder(
    column: $table.intro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customIntro => $composableBuilder(
    column: $table.customIntro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get charset => $composableBuilder(
    column: $table.charset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestChapterTitle => $composableBuilder(
    column: $table.latestChapterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestChapterTime => $composableBuilder(
    column: $table.latestChapterTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCheckTime => $composableBuilder(
    column: $table.lastCheckTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCheckCount => $composableBuilder(
    column: $table.lastCheckCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChapterNum => $composableBuilder(
    column: $table.totalChapterNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durChapterTitle => $composableBuilder(
    column: $table.durChapterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durChapterIndex => $composableBuilder(
    column: $table.durChapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durChapterPos => $composableBuilder(
    column: $table.durChapterPos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durChapterTime => $composableBuilder(
    column: $table.durChapterTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get canUpdate => $composableBuilder(
    column: $table.canUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originOrder => $composableBuilder(
    column: $table.originOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readConfig => $composableBuilder(
    column: $table.readConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncTime => $composableBuilder(
    column: $table.syncTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isInBookshelf => $composableBuilder(
    column: $table.isInBookshelf,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookUrl =>
      $composableBuilder(column: $table.bookUrl, builder: (column) => column);

  GeneratedColumn<String> get tocUrl =>
      $composableBuilder(column: $table.tocUrl, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get customTag =>
      $composableBuilder(column: $table.customTag, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get customCoverUrl => $composableBuilder(
    column: $table.customCoverUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intro =>
      $composableBuilder(column: $table.intro, builder: (column) => column);

  GeneratedColumn<String> get customIntro => $composableBuilder(
    column: $table.customIntro,
    builder: (column) => column,
  );

  GeneratedColumn<String> get charset =>
      $composableBuilder(column: $table.charset, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get group =>
      $composableBuilder(column: $table.group, builder: (column) => column);

  GeneratedColumn<String> get latestChapterTitle => $composableBuilder(
    column: $table.latestChapterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestChapterTime => $composableBuilder(
    column: $table.latestChapterTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCheckTime => $composableBuilder(
    column: $table.lastCheckTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCheckCount => $composableBuilder(
    column: $table.lastCheckCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChapterNum => $composableBuilder(
    column: $table.totalChapterNum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get durChapterTitle => $composableBuilder(
    column: $table.durChapterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durChapterIndex => $composableBuilder(
    column: $table.durChapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durChapterPos => $composableBuilder(
    column: $table.durChapterPos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durChapterTime => $composableBuilder(
    column: $table.durChapterTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<int> get canUpdate =>
      $composableBuilder(column: $table.canUpdate, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<int> get originOrder => $composableBuilder(
    column: $table.originOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variable =>
      $composableBuilder(column: $table.variable, builder: (column) => column);

  GeneratedColumn<String> get readConfig => $composableBuilder(
    column: $table.readConfig,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncTime =>
      $composableBuilder(column: $table.syncTime, builder: (column) => column);

  GeneratedColumn<int> get isInBookshelf => $composableBuilder(
    column: $table.isInBookshelf,
    builder: (column) => column,
  );
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          BookRow,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
          BookRow,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookUrl = const Value.absent(),
                Value<String?> tocUrl = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> customTag = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> customCoverUrl = const Value.absent(),
                Value<String?> intro = const Value.absent(),
                Value<String?> customIntro = const Value.absent(),
                Value<String?> charset = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> group = const Value.absent(),
                Value<String?> latestChapterTitle = const Value.absent(),
                Value<int> latestChapterTime = const Value.absent(),
                Value<int> lastCheckTime = const Value.absent(),
                Value<int> lastCheckCount = const Value.absent(),
                Value<int> totalChapterNum = const Value.absent(),
                Value<String?> durChapterTitle = const Value.absent(),
                Value<int> durChapterIndex = const Value.absent(),
                Value<int> durChapterPos = const Value.absent(),
                Value<int> durChapterTime = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<int> canUpdate = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> originOrder = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<String?> readConfig = const Value.absent(),
                Value<int> syncTime = const Value.absent(),
                Value<int> isInBookshelf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                bookUrl: bookUrl,
                tocUrl: tocUrl,
                origin: origin,
                originName: originName,
                name: name,
                author: author,
                kind: kind,
                customTag: customTag,
                coverUrl: coverUrl,
                customCoverUrl: customCoverUrl,
                intro: intro,
                customIntro: customIntro,
                charset: charset,
                type: type,
                group: group,
                latestChapterTitle: latestChapterTitle,
                latestChapterTime: latestChapterTime,
                lastCheckTime: lastCheckTime,
                lastCheckCount: lastCheckCount,
                totalChapterNum: totalChapterNum,
                durChapterTitle: durChapterTitle,
                durChapterIndex: durChapterIndex,
                durChapterPos: durChapterPos,
                durChapterTime: durChapterTime,
                wordCount: wordCount,
                canUpdate: canUpdate,
                order: order,
                originOrder: originOrder,
                variable: variable,
                readConfig: readConfig,
                syncTime: syncTime,
                isInBookshelf: isInBookshelf,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookUrl,
                Value<String?> tocUrl = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                required String name,
                Value<String?> author = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> customTag = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> customCoverUrl = const Value.absent(),
                Value<String?> intro = const Value.absent(),
                Value<String?> customIntro = const Value.absent(),
                Value<String?> charset = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> group = const Value.absent(),
                Value<String?> latestChapterTitle = const Value.absent(),
                Value<int> latestChapterTime = const Value.absent(),
                Value<int> lastCheckTime = const Value.absent(),
                Value<int> lastCheckCount = const Value.absent(),
                Value<int> totalChapterNum = const Value.absent(),
                Value<String?> durChapterTitle = const Value.absent(),
                Value<int> durChapterIndex = const Value.absent(),
                Value<int> durChapterPos = const Value.absent(),
                Value<int> durChapterTime = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<int> canUpdate = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> originOrder = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<String?> readConfig = const Value.absent(),
                Value<int> syncTime = const Value.absent(),
                Value<int> isInBookshelf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                bookUrl: bookUrl,
                tocUrl: tocUrl,
                origin: origin,
                originName: originName,
                name: name,
                author: author,
                kind: kind,
                customTag: customTag,
                coverUrl: coverUrl,
                customCoverUrl: customCoverUrl,
                intro: intro,
                customIntro: customIntro,
                charset: charset,
                type: type,
                group: group,
                latestChapterTitle: latestChapterTitle,
                latestChapterTime: latestChapterTime,
                lastCheckTime: lastCheckTime,
                lastCheckCount: lastCheckCount,
                totalChapterNum: totalChapterNum,
                durChapterTitle: durChapterTitle,
                durChapterIndex: durChapterIndex,
                durChapterPos: durChapterPos,
                durChapterTime: durChapterTime,
                wordCount: wordCount,
                canUpdate: canUpdate,
                order: order,
                originOrder: originOrder,
                variable: variable,
                readConfig: readConfig,
                syncTime: syncTime,
                isInBookshelf: isInBookshelf,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      BookRow,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
      BookRow,
      PrefetchHooks Function()
    >;
typedef $$ChaptersTableCreateCompanionBuilder =
    ChaptersCompanion Function({
      required String url,
      required String title,
      Value<int> isVolume,
      Value<String?> baseUrl,
      required String bookUrl,
      required int index,
      Value<int> isVip,
      Value<int> isPay,
      Value<String?> resourceUrl,
      Value<String?> tag,
      Value<String?> wordCount,
      Value<int?> start,
      Value<int?> end,
      Value<String?> startFragmentId,
      Value<String?> endFragmentId,
      Value<String?> variable,
      Value<String?> content,
      Value<int> rowid,
    });
typedef $$ChaptersTableUpdateCompanionBuilder =
    ChaptersCompanion Function({
      Value<String> url,
      Value<String> title,
      Value<int> isVolume,
      Value<String?> baseUrl,
      Value<String> bookUrl,
      Value<int> index,
      Value<int> isVip,
      Value<int> isPay,
      Value<String?> resourceUrl,
      Value<String?> tag,
      Value<String?> wordCount,
      Value<int?> start,
      Value<int?> end,
      Value<String?> startFragmentId,
      Value<String?> endFragmentId,
      Value<String?> variable,
      Value<String?> content,
      Value<int> rowid,
    });

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isVolume => $composableBuilder(
    column: $table.isVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get index => $composableBuilder(
    column: $table.index,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isVip => $composableBuilder(
    column: $table.isVip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isPay => $composableBuilder(
    column: $table.isPay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceUrl => $composableBuilder(
    column: $table.resourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startFragmentId => $composableBuilder(
    column: $table.startFragmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endFragmentId => $composableBuilder(
    column: $table.endFragmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isVolume => $composableBuilder(
    column: $table.isVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get index => $composableBuilder(
    column: $table.index,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isVip => $composableBuilder(
    column: $table.isVip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isPay => $composableBuilder(
    column: $table.isPay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceUrl => $composableBuilder(
    column: $table.resourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startFragmentId => $composableBuilder(
    column: $table.startFragmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endFragmentId => $composableBuilder(
    column: $table.endFragmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get isVolume =>
      $composableBuilder(column: $table.isVolume, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get bookUrl =>
      $composableBuilder(column: $table.bookUrl, builder: (column) => column);

  GeneratedColumn<int> get index =>
      $composableBuilder(column: $table.index, builder: (column) => column);

  GeneratedColumn<int> get isVip =>
      $composableBuilder(column: $table.isVip, builder: (column) => column);

  GeneratedColumn<int> get isPay =>
      $composableBuilder(column: $table.isPay, builder: (column) => column);

  GeneratedColumn<String> get resourceUrl => $composableBuilder(
    column: $table.resourceUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get startFragmentId => $composableBuilder(
    column: $table.startFragmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endFragmentId => $composableBuilder(
    column: $table.endFragmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variable =>
      $composableBuilder(column: $table.variable, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChaptersTable,
          ChapterRow,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (
            ChapterRow,
            BaseReferences<_$AppDatabase, $ChaptersTable, ChapterRow>,
          ),
          ChapterRow,
          PrefetchHooks Function()
        > {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> isVolume = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<String> bookUrl = const Value.absent(),
                Value<int> index = const Value.absent(),
                Value<int> isVip = const Value.absent(),
                Value<int> isPay = const Value.absent(),
                Value<String?> resourceUrl = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<int?> start = const Value.absent(),
                Value<int?> end = const Value.absent(),
                Value<String?> startFragmentId = const Value.absent(),
                Value<String?> endFragmentId = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion(
                url: url,
                title: title,
                isVolume: isVolume,
                baseUrl: baseUrl,
                bookUrl: bookUrl,
                index: index,
                isVip: isVip,
                isPay: isPay,
                resourceUrl: resourceUrl,
                tag: tag,
                wordCount: wordCount,
                start: start,
                end: end,
                startFragmentId: startFragmentId,
                endFragmentId: endFragmentId,
                variable: variable,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required String title,
                Value<int> isVolume = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                required String bookUrl,
                required int index,
                Value<int> isVip = const Value.absent(),
                Value<int> isPay = const Value.absent(),
                Value<String?> resourceUrl = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<int?> start = const Value.absent(),
                Value<int?> end = const Value.absent(),
                Value<String?> startFragmentId = const Value.absent(),
                Value<String?> endFragmentId = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion.insert(
                url: url,
                title: title,
                isVolume: isVolume,
                baseUrl: baseUrl,
                bookUrl: bookUrl,
                index: index,
                isVip: isVip,
                isPay: isPay,
                resourceUrl: resourceUrl,
                tag: tag,
                wordCount: wordCount,
                start: start,
                end: end,
                startFragmentId: startFragmentId,
                endFragmentId: endFragmentId,
                variable: variable,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChaptersTable,
      ChapterRow,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (ChapterRow, BaseReferences<_$AppDatabase, $ChaptersTable, ChapterRow>),
      ChapterRow,
      PrefetchHooks Function()
    >;
typedef $$BookSourcesTableCreateCompanionBuilder =
    BookSourcesCompanion Function({
      required String bookSourceUrl,
      required String bookSourceName,
      Value<int> bookSourceType,
      Value<String?> bookSourceGroup,
      Value<String?> bookSourceComment,
      Value<String?> loginUrl,
      Value<String?> loginUi,
      Value<String?> loginCheckJs,
      Value<String?> coverDecodeJs,
      Value<String?> bookUrlPattern,
      Value<String?> header,
      Value<String?> variableComment,
      Value<int> customOrder,
      Value<int> weight,
      Value<int> enabled,
      Value<int> enabledExplore,
      Value<int> enabledCookieJar,
      Value<int> lastUpdateTime,
      Value<int> respondTime,
      Value<String?> jsLib,
      Value<String?> concurrentRate,
      Value<String?> exploreUrl,
      Value<String?> exploreScreen,
      Value<String?> searchUrl,
      Value<String?> ruleSearch,
      Value<String?> ruleExplore,
      Value<String?> ruleBookInfo,
      Value<String?> ruleToc,
      Value<String?> ruleContent,
      Value<String?> ruleReview,
      Value<int> rowid,
    });
typedef $$BookSourcesTableUpdateCompanionBuilder =
    BookSourcesCompanion Function({
      Value<String> bookSourceUrl,
      Value<String> bookSourceName,
      Value<int> bookSourceType,
      Value<String?> bookSourceGroup,
      Value<String?> bookSourceComment,
      Value<String?> loginUrl,
      Value<String?> loginUi,
      Value<String?> loginCheckJs,
      Value<String?> coverDecodeJs,
      Value<String?> bookUrlPattern,
      Value<String?> header,
      Value<String?> variableComment,
      Value<int> customOrder,
      Value<int> weight,
      Value<int> enabled,
      Value<int> enabledExplore,
      Value<int> enabledCookieJar,
      Value<int> lastUpdateTime,
      Value<int> respondTime,
      Value<String?> jsLib,
      Value<String?> concurrentRate,
      Value<String?> exploreUrl,
      Value<String?> exploreScreen,
      Value<String?> searchUrl,
      Value<String?> ruleSearch,
      Value<String?> ruleExplore,
      Value<String?> ruleBookInfo,
      Value<String?> ruleToc,
      Value<String?> ruleContent,
      Value<String?> ruleReview,
      Value<int> rowid,
    });

class $$BookSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $BookSourcesTable> {
  $$BookSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookSourceUrl => $composableBuilder(
    column: $table.bookSourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookSourceName => $composableBuilder(
    column: $table.bookSourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookSourceType => $composableBuilder(
    column: $table.bookSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookSourceGroup => $composableBuilder(
    column: $table.bookSourceGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookSourceComment => $composableBuilder(
    column: $table.bookSourceComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUi => $composableBuilder(
    column: $table.loginUi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverDecodeJs => $composableBuilder(
    column: $table.coverDecodeJs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookUrlPattern => $composableBuilder(
    column: $table.bookUrlPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variableComment => $composableBuilder(
    column: $table.variableComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabledExplore => $composableBuilder(
    column: $table.enabledExplore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get respondTime => $composableBuilder(
    column: $table.respondTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exploreUrl => $composableBuilder(
    column: $table.exploreUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exploreScreen => $composableBuilder(
    column: $table.exploreScreen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchUrl => $composableBuilder(
    column: $table.searchUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleSearch => $composableBuilder(
    column: $table.ruleSearch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleExplore => $composableBuilder(
    column: $table.ruleExplore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleBookInfo => $composableBuilder(
    column: $table.ruleBookInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleToc => $composableBuilder(
    column: $table.ruleToc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleContent => $composableBuilder(
    column: $table.ruleContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleReview => $composableBuilder(
    column: $table.ruleReview,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $BookSourcesTable> {
  $$BookSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookSourceUrl => $composableBuilder(
    column: $table.bookSourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookSourceName => $composableBuilder(
    column: $table.bookSourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookSourceType => $composableBuilder(
    column: $table.bookSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookSourceGroup => $composableBuilder(
    column: $table.bookSourceGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookSourceComment => $composableBuilder(
    column: $table.bookSourceComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUi => $composableBuilder(
    column: $table.loginUi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverDecodeJs => $composableBuilder(
    column: $table.coverDecodeJs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookUrlPattern => $composableBuilder(
    column: $table.bookUrlPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variableComment => $composableBuilder(
    column: $table.variableComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabledExplore => $composableBuilder(
    column: $table.enabledExplore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get respondTime => $composableBuilder(
    column: $table.respondTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exploreUrl => $composableBuilder(
    column: $table.exploreUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exploreScreen => $composableBuilder(
    column: $table.exploreScreen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchUrl => $composableBuilder(
    column: $table.searchUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleSearch => $composableBuilder(
    column: $table.ruleSearch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleExplore => $composableBuilder(
    column: $table.ruleExplore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleBookInfo => $composableBuilder(
    column: $table.ruleBookInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleToc => $composableBuilder(
    column: $table.ruleToc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleContent => $composableBuilder(
    column: $table.ruleContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleReview => $composableBuilder(
    column: $table.ruleReview,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookSourcesTable> {
  $$BookSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookSourceUrl => $composableBuilder(
    column: $table.bookSourceUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookSourceName => $composableBuilder(
    column: $table.bookSourceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bookSourceType => $composableBuilder(
    column: $table.bookSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookSourceGroup => $composableBuilder(
    column: $table.bookSourceGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookSourceComment => $composableBuilder(
    column: $table.bookSourceComment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginUrl =>
      $composableBuilder(column: $table.loginUrl, builder: (column) => column);

  GeneratedColumn<String> get loginUi =>
      $composableBuilder(column: $table.loginUi, builder: (column) => column);

  GeneratedColumn<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverDecodeJs => $composableBuilder(
    column: $table.coverDecodeJs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookUrlPattern => $composableBuilder(
    column: $table.bookUrlPattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get header =>
      $composableBuilder(column: $table.header, builder: (column) => column);

  GeneratedColumn<String> get variableComment => $composableBuilder(
    column: $table.variableComment,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get enabledExplore => $composableBuilder(
    column: $table.enabledExplore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get respondTime => $composableBuilder(
    column: $table.respondTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsLib =>
      $composableBuilder(column: $table.jsLib, builder: (column) => column);

  GeneratedColumn<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exploreUrl => $composableBuilder(
    column: $table.exploreUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exploreScreen => $composableBuilder(
    column: $table.exploreScreen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchUrl =>
      $composableBuilder(column: $table.searchUrl, builder: (column) => column);

  GeneratedColumn<String> get ruleSearch => $composableBuilder(
    column: $table.ruleSearch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleExplore => $composableBuilder(
    column: $table.ruleExplore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleBookInfo => $composableBuilder(
    column: $table.ruleBookInfo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleToc =>
      $composableBuilder(column: $table.ruleToc, builder: (column) => column);

  GeneratedColumn<String> get ruleContent => $composableBuilder(
    column: $table.ruleContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleReview => $composableBuilder(
    column: $table.ruleReview,
    builder: (column) => column,
  );
}

class $$BookSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookSourcesTable,
          BookSourceRow,
          $$BookSourcesTableFilterComposer,
          $$BookSourcesTableOrderingComposer,
          $$BookSourcesTableAnnotationComposer,
          $$BookSourcesTableCreateCompanionBuilder,
          $$BookSourcesTableUpdateCompanionBuilder,
          (
            BookSourceRow,
            BaseReferences<_$AppDatabase, $BookSourcesTable, BookSourceRow>,
          ),
          BookSourceRow,
          PrefetchHooks Function()
        > {
  $$BookSourcesTableTableManager(_$AppDatabase db, $BookSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$BookSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$BookSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$BookSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookSourceUrl = const Value.absent(),
                Value<String> bookSourceName = const Value.absent(),
                Value<int> bookSourceType = const Value.absent(),
                Value<String?> bookSourceGroup = const Value.absent(),
                Value<String?> bookSourceComment = const Value.absent(),
                Value<String?> loginUrl = const Value.absent(),
                Value<String?> loginUi = const Value.absent(),
                Value<String?> loginCheckJs = const Value.absent(),
                Value<String?> coverDecodeJs = const Value.absent(),
                Value<String?> bookUrlPattern = const Value.absent(),
                Value<String?> header = const Value.absent(),
                Value<String?> variableComment = const Value.absent(),
                Value<int> customOrder = const Value.absent(),
                Value<int> weight = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> enabledExplore = const Value.absent(),
                Value<int> enabledCookieJar = const Value.absent(),
                Value<int> lastUpdateTime = const Value.absent(),
                Value<int> respondTime = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<String?> concurrentRate = const Value.absent(),
                Value<String?> exploreUrl = const Value.absent(),
                Value<String?> exploreScreen = const Value.absent(),
                Value<String?> searchUrl = const Value.absent(),
                Value<String?> ruleSearch = const Value.absent(),
                Value<String?> ruleExplore = const Value.absent(),
                Value<String?> ruleBookInfo = const Value.absent(),
                Value<String?> ruleToc = const Value.absent(),
                Value<String?> ruleContent = const Value.absent(),
                Value<String?> ruleReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookSourcesCompanion(
                bookSourceUrl: bookSourceUrl,
                bookSourceName: bookSourceName,
                bookSourceType: bookSourceType,
                bookSourceGroup: bookSourceGroup,
                bookSourceComment: bookSourceComment,
                loginUrl: loginUrl,
                loginUi: loginUi,
                loginCheckJs: loginCheckJs,
                coverDecodeJs: coverDecodeJs,
                bookUrlPattern: bookUrlPattern,
                header: header,
                variableComment: variableComment,
                customOrder: customOrder,
                weight: weight,
                enabled: enabled,
                enabledExplore: enabledExplore,
                enabledCookieJar: enabledCookieJar,
                lastUpdateTime: lastUpdateTime,
                respondTime: respondTime,
                jsLib: jsLib,
                concurrentRate: concurrentRate,
                exploreUrl: exploreUrl,
                exploreScreen: exploreScreen,
                searchUrl: searchUrl,
                ruleSearch: ruleSearch,
                ruleExplore: ruleExplore,
                ruleBookInfo: ruleBookInfo,
                ruleToc: ruleToc,
                ruleContent: ruleContent,
                ruleReview: ruleReview,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookSourceUrl,
                required String bookSourceName,
                Value<int> bookSourceType = const Value.absent(),
                Value<String?> bookSourceGroup = const Value.absent(),
                Value<String?> bookSourceComment = const Value.absent(),
                Value<String?> loginUrl = const Value.absent(),
                Value<String?> loginUi = const Value.absent(),
                Value<String?> loginCheckJs = const Value.absent(),
                Value<String?> coverDecodeJs = const Value.absent(),
                Value<String?> bookUrlPattern = const Value.absent(),
                Value<String?> header = const Value.absent(),
                Value<String?> variableComment = const Value.absent(),
                Value<int> customOrder = const Value.absent(),
                Value<int> weight = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> enabledExplore = const Value.absent(),
                Value<int> enabledCookieJar = const Value.absent(),
                Value<int> lastUpdateTime = const Value.absent(),
                Value<int> respondTime = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<String?> concurrentRate = const Value.absent(),
                Value<String?> exploreUrl = const Value.absent(),
                Value<String?> exploreScreen = const Value.absent(),
                Value<String?> searchUrl = const Value.absent(),
                Value<String?> ruleSearch = const Value.absent(),
                Value<String?> ruleExplore = const Value.absent(),
                Value<String?> ruleBookInfo = const Value.absent(),
                Value<String?> ruleToc = const Value.absent(),
                Value<String?> ruleContent = const Value.absent(),
                Value<String?> ruleReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookSourcesCompanion.insert(
                bookSourceUrl: bookSourceUrl,
                bookSourceName: bookSourceName,
                bookSourceType: bookSourceType,
                bookSourceGroup: bookSourceGroup,
                bookSourceComment: bookSourceComment,
                loginUrl: loginUrl,
                loginUi: loginUi,
                loginCheckJs: loginCheckJs,
                coverDecodeJs: coverDecodeJs,
                bookUrlPattern: bookUrlPattern,
                header: header,
                variableComment: variableComment,
                customOrder: customOrder,
                weight: weight,
                enabled: enabled,
                enabledExplore: enabledExplore,
                enabledCookieJar: enabledCookieJar,
                lastUpdateTime: lastUpdateTime,
                respondTime: respondTime,
                jsLib: jsLib,
                concurrentRate: concurrentRate,
                exploreUrl: exploreUrl,
                exploreScreen: exploreScreen,
                searchUrl: searchUrl,
                ruleSearch: ruleSearch,
                ruleExplore: ruleExplore,
                ruleBookInfo: ruleBookInfo,
                ruleToc: ruleToc,
                ruleContent: ruleContent,
                ruleReview: ruleReview,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookSourcesTable,
      BookSourceRow,
      $$BookSourcesTableFilterComposer,
      $$BookSourcesTableOrderingComposer,
      $$BookSourcesTableAnnotationComposer,
      $$BookSourcesTableCreateCompanionBuilder,
      $$BookSourcesTableUpdateCompanionBuilder,
      (
        BookSourceRow,
        BaseReferences<_$AppDatabase, $BookSourcesTable, BookSourceRow>,
      ),
      BookSourceRow,
      PrefetchHooks Function()
    >;
typedef $$BookGroupsTableCreateCompanionBuilder =
    BookGroupsCompanion Function({
      Value<int> groupId,
      required String groupName,
      Value<int> order,
      Value<int> show,
      Value<String?> coverPath,
      Value<int> enableRefresh,
      Value<int> bookSort,
    });
typedef $$BookGroupsTableUpdateCompanionBuilder =
    BookGroupsCompanion Function({
      Value<int> groupId,
      Value<String> groupName,
      Value<int> order,
      Value<int> show,
      Value<String?> coverPath,
      Value<int> enableRefresh,
      Value<int> bookSort,
    });

class $$BookGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $BookGroupsTable> {
  $$BookGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get show => $composableBuilder(
    column: $table.show,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enableRefresh => $composableBuilder(
    column: $table.enableRefresh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookSort => $composableBuilder(
    column: $table.bookSort,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookGroupsTable> {
  $$BookGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get show => $composableBuilder(
    column: $table.show,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enableRefresh => $composableBuilder(
    column: $table.enableRefresh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookSort => $composableBuilder(
    column: $table.bookSort,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookGroupsTable> {
  $$BookGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<int> get show =>
      $composableBuilder(column: $table.show, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<int> get enableRefresh => $composableBuilder(
    column: $table.enableRefresh,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bookSort =>
      $composableBuilder(column: $table.bookSort, builder: (column) => column);
}

class $$BookGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookGroupsTable,
          BookGroupRow,
          $$BookGroupsTableFilterComposer,
          $$BookGroupsTableOrderingComposer,
          $$BookGroupsTableAnnotationComposer,
          $$BookGroupsTableCreateCompanionBuilder,
          $$BookGroupsTableUpdateCompanionBuilder,
          (
            BookGroupRow,
            BaseReferences<_$AppDatabase, $BookGroupsTable, BookGroupRow>,
          ),
          BookGroupRow,
          PrefetchHooks Function()
        > {
  $$BookGroupsTableTableManager(_$AppDatabase db, $BookGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$BookGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$BookGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$BookGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                Value<String> groupName = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> show = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<int> enableRefresh = const Value.absent(),
                Value<int> bookSort = const Value.absent(),
              }) => BookGroupsCompanion(
                groupId: groupId,
                groupName: groupName,
                order: order,
                show: show,
                coverPath: coverPath,
                enableRefresh: enableRefresh,
                bookSort: bookSort,
              ),
          createCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                required String groupName,
                Value<int> order = const Value.absent(),
                Value<int> show = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<int> enableRefresh = const Value.absent(),
                Value<int> bookSort = const Value.absent(),
              }) => BookGroupsCompanion.insert(
                groupId: groupId,
                groupName: groupName,
                order: order,
                show: show,
                coverPath: coverPath,
                enableRefresh: enableRefresh,
                bookSort: bookSort,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookGroupsTable,
      BookGroupRow,
      $$BookGroupsTableFilterComposer,
      $$BookGroupsTableOrderingComposer,
      $$BookGroupsTableAnnotationComposer,
      $$BookGroupsTableCreateCompanionBuilder,
      $$BookGroupsTableUpdateCompanionBuilder,
      (
        BookGroupRow,
        BaseReferences<_$AppDatabase, $BookGroupsTable, BookGroupRow>,
      ),
      BookGroupRow,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryTableCreateCompanionBuilder =
    SearchHistoryCompanion Function({
      Value<int> id,
      required String keyword,
      required int searchTime,
    });
typedef $$SearchHistoryTableUpdateCompanionBuilder =
    SearchHistoryCompanion Function({
      Value<int> id,
      Value<String> keyword,
      Value<int> searchTime,
    });

class $$SearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get searchTime => $composableBuilder(
    column: $table.searchTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get searchTime => $composableBuilder(
    column: $table.searchTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<int> get searchTime => $composableBuilder(
    column: $table.searchTime,
    builder: (column) => column,
  );
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryTable,
          SearchHistoryRow,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (
            SearchHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryTable,
              SearchHistoryRow
            >,
          ),
          SearchHistoryRow,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(_$AppDatabase db, $SearchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SearchHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> keyword = const Value.absent(),
                Value<int> searchTime = const Value.absent(),
              }) => SearchHistoryCompanion(
                id: id,
                keyword: keyword,
                searchTime: searchTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String keyword,
                required int searchTime,
              }) => SearchHistoryCompanion.insert(
                id: id,
                keyword: keyword,
                searchTime: searchTime,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryTable,
      SearchHistoryRow,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (
        SearchHistoryRow,
        BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryRow>,
      ),
      SearchHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$ReplaceRulesTableCreateCompanionBuilder =
    ReplaceRulesCompanion Function({
      Value<int> id,
      Value<String?> name,
      required String pattern,
      Value<String?> replacement,
      Value<String?> scope,
      Value<int> scopeTitle,
      Value<int> scopeContent,
      Value<String?> excludeScope,
      Value<int> isEnabled,
      Value<int> isRegex,
      Value<int> timeoutMillisecond,
      Value<String?> group,
      Value<int> order,
    });
typedef $$ReplaceRulesTableUpdateCompanionBuilder =
    ReplaceRulesCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<String> pattern,
      Value<String?> replacement,
      Value<String?> scope,
      Value<int> scopeTitle,
      Value<int> scopeContent,
      Value<String?> excludeScope,
      Value<int> isEnabled,
      Value<int> isRegex,
      Value<int> timeoutMillisecond,
      Value<String?> group,
      Value<int> order,
    });

class $$ReplaceRulesTableFilterComposer
    extends Composer<_$AppDatabase, $ReplaceRulesTable> {
  $$ReplaceRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacement => $composableBuilder(
    column: $table.replacement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scopeTitle => $composableBuilder(
    column: $table.scopeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scopeContent => $composableBuilder(
    column: $table.scopeContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excludeScope => $composableBuilder(
    column: $table.excludeScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isRegex => $composableBuilder(
    column: $table.isRegex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeoutMillisecond => $composableBuilder(
    column: $table.timeoutMillisecond,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReplaceRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReplaceRulesTable> {
  $$ReplaceRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacement => $composableBuilder(
    column: $table.replacement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scopeTitle => $composableBuilder(
    column: $table.scopeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scopeContent => $composableBuilder(
    column: $table.scopeContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excludeScope => $composableBuilder(
    column: $table.excludeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isRegex => $composableBuilder(
    column: $table.isRegex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeoutMillisecond => $composableBuilder(
    column: $table.timeoutMillisecond,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReplaceRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReplaceRulesTable> {
  $$ReplaceRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<String> get replacement => $composableBuilder(
    column: $table.replacement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<int> get scopeTitle => $composableBuilder(
    column: $table.scopeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scopeContent => $composableBuilder(
    column: $table.scopeContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get excludeScope => $composableBuilder(
    column: $table.excludeScope,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get isRegex =>
      $composableBuilder(column: $table.isRegex, builder: (column) => column);

  GeneratedColumn<int> get timeoutMillisecond => $composableBuilder(
    column: $table.timeoutMillisecond,
    builder: (column) => column,
  );

  GeneratedColumn<String> get group =>
      $composableBuilder(column: $table.group, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);
}

class $$ReplaceRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReplaceRulesTable,
          ReplaceRuleRow,
          $$ReplaceRulesTableFilterComposer,
          $$ReplaceRulesTableOrderingComposer,
          $$ReplaceRulesTableAnnotationComposer,
          $$ReplaceRulesTableCreateCompanionBuilder,
          $$ReplaceRulesTableUpdateCompanionBuilder,
          (
            ReplaceRuleRow,
            BaseReferences<_$AppDatabase, $ReplaceRulesTable, ReplaceRuleRow>,
          ),
          ReplaceRuleRow,
          PrefetchHooks Function()
        > {
  $$ReplaceRulesTableTableManager(_$AppDatabase db, $ReplaceRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ReplaceRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ReplaceRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$ReplaceRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<String?> replacement = const Value.absent(),
                Value<String?> scope = const Value.absent(),
                Value<int> scopeTitle = const Value.absent(),
                Value<int> scopeContent = const Value.absent(),
                Value<String?> excludeScope = const Value.absent(),
                Value<int> isEnabled = const Value.absent(),
                Value<int> isRegex = const Value.absent(),
                Value<int> timeoutMillisecond = const Value.absent(),
                Value<String?> group = const Value.absent(),
                Value<int> order = const Value.absent(),
              }) => ReplaceRulesCompanion(
                id: id,
                name: name,
                pattern: pattern,
                replacement: replacement,
                scope: scope,
                scopeTitle: scopeTitle,
                scopeContent: scopeContent,
                excludeScope: excludeScope,
                isEnabled: isEnabled,
                isRegex: isRegex,
                timeoutMillisecond: timeoutMillisecond,
                group: group,
                order: order,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                required String pattern,
                Value<String?> replacement = const Value.absent(),
                Value<String?> scope = const Value.absent(),
                Value<int> scopeTitle = const Value.absent(),
                Value<int> scopeContent = const Value.absent(),
                Value<String?> excludeScope = const Value.absent(),
                Value<int> isEnabled = const Value.absent(),
                Value<int> isRegex = const Value.absent(),
                Value<int> timeoutMillisecond = const Value.absent(),
                Value<String?> group = const Value.absent(),
                Value<int> order = const Value.absent(),
              }) => ReplaceRulesCompanion.insert(
                id: id,
                name: name,
                pattern: pattern,
                replacement: replacement,
                scope: scope,
                scopeTitle: scopeTitle,
                scopeContent: scopeContent,
                excludeScope: excludeScope,
                isEnabled: isEnabled,
                isRegex: isRegex,
                timeoutMillisecond: timeoutMillisecond,
                group: group,
                order: order,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReplaceRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReplaceRulesTable,
      ReplaceRuleRow,
      $$ReplaceRulesTableFilterComposer,
      $$ReplaceRulesTableOrderingComposer,
      $$ReplaceRulesTableAnnotationComposer,
      $$ReplaceRulesTableCreateCompanionBuilder,
      $$ReplaceRulesTableUpdateCompanionBuilder,
      (
        ReplaceRuleRow,
        BaseReferences<_$AppDatabase, $ReplaceRulesTable, ReplaceRuleRow>,
      ),
      ReplaceRuleRow,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required int time,
      required String bookName,
      Value<String?> bookAuthor,
      Value<int> chapterIndex,
      Value<int> chapterPos,
      Value<String?> chapterName,
      required String bookUrl,
      Value<String?> bookText,
      Value<String?> content,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<int> time,
      Value<String> bookName,
      Value<String?> bookAuthor,
      Value<int> chapterIndex,
      Value<int> chapterPos,
      Value<String?> chapterName,
      Value<String> bookUrl,
      Value<String?> bookText,
      Value<String?> content,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookAuthor => $composableBuilder(
    column: $table.bookAuthor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterPos => $composableBuilder(
    column: $table.chapterPos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterName => $composableBuilder(
    column: $table.chapterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookText => $composableBuilder(
    column: $table.bookText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookAuthor => $composableBuilder(
    column: $table.bookAuthor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterPos => $composableBuilder(
    column: $table.chapterPos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterName => $composableBuilder(
    column: $table.chapterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookText => $composableBuilder(
    column: $table.bookText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<String> get bookAuthor => $composableBuilder(
    column: $table.bookAuthor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chapterPos => $composableBuilder(
    column: $table.chapterPos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chapterName => $composableBuilder(
    column: $table.chapterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookUrl =>
      $composableBuilder(column: $table.bookUrl, builder: (column) => column);

  GeneratedColumn<String> get bookText =>
      $composableBuilder(column: $table.bookText, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          BookmarkRow,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (
            BookmarkRow,
            BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
          ),
          BookmarkRow,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> time = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<String?> bookAuthor = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<int> chapterPos = const Value.absent(),
                Value<String?> chapterName = const Value.absent(),
                Value<String> bookUrl = const Value.absent(),
                Value<String?> bookText = const Value.absent(),
                Value<String?> content = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                time: time,
                bookName: bookName,
                bookAuthor: bookAuthor,
                chapterIndex: chapterIndex,
                chapterPos: chapterPos,
                chapterName: chapterName,
                bookUrl: bookUrl,
                bookText: bookText,
                content: content,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int time,
                required String bookName,
                Value<String?> bookAuthor = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<int> chapterPos = const Value.absent(),
                Value<String?> chapterName = const Value.absent(),
                required String bookUrl,
                Value<String?> bookText = const Value.absent(),
                Value<String?> content = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                time: time,
                bookName: bookName,
                bookAuthor: bookAuthor,
                chapterIndex: chapterIndex,
                chapterPos: chapterPos,
                chapterName: chapterName,
                bookUrl: bookUrl,
                bookText: bookText,
                content: content,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      BookmarkRow,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (
        BookmarkRow,
        BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
      ),
      BookmarkRow,
      PrefetchHooks Function()
    >;
typedef $$CookiesTableCreateCompanionBuilder =
    CookiesCompanion Function({
      required String url,
      required String cookie,
      Value<int> rowid,
    });
typedef $$CookiesTableUpdateCompanionBuilder =
    CookiesCompanion Function({
      Value<String> url,
      Value<String> cookie,
      Value<int> rowid,
    });

class $$CookiesTableFilterComposer
    extends Composer<_$AppDatabase, $CookiesTable> {
  $$CookiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cookie => $composableBuilder(
    column: $table.cookie,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CookiesTableOrderingComposer
    extends Composer<_$AppDatabase, $CookiesTable> {
  $$CookiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cookie => $composableBuilder(
    column: $table.cookie,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CookiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CookiesTable> {
  $$CookiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get cookie =>
      $composableBuilder(column: $table.cookie, builder: (column) => column);
}

class $$CookiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CookiesTable,
          CookieRow,
          $$CookiesTableFilterComposer,
          $$CookiesTableOrderingComposer,
          $$CookiesTableAnnotationComposer,
          $$CookiesTableCreateCompanionBuilder,
          $$CookiesTableUpdateCompanionBuilder,
          (CookieRow, BaseReferences<_$AppDatabase, $CookiesTable, CookieRow>),
          CookieRow,
          PrefetchHooks Function()
        > {
  $$CookiesTableTableManager(_$AppDatabase db, $CookiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CookiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CookiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CookiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<String> cookie = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CookiesCompanion(url: url, cookie: cookie, rowid: rowid),
          createCompanionCallback:
              ({
                required String url,
                required String cookie,
                Value<int> rowid = const Value.absent(),
              }) => CookiesCompanion.insert(
                url: url,
                cookie: cookie,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CookiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CookiesTable,
      CookieRow,
      $$CookiesTableFilterComposer,
      $$CookiesTableOrderingComposer,
      $$CookiesTableAnnotationComposer,
      $$CookiesTableCreateCompanionBuilder,
      $$CookiesTableUpdateCompanionBuilder,
      (CookieRow, BaseReferences<_$AppDatabase, $CookiesTable, CookieRow>),
      CookieRow,
      PrefetchHooks Function()
    >;
typedef $$DictRulesTableCreateCompanionBuilder =
    DictRulesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> urlRule,
      Value<String?> showRule,
      Value<int> enabled,
      Value<int> sortNumber,
    });
typedef $$DictRulesTableUpdateCompanionBuilder =
    DictRulesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> urlRule,
      Value<String?> showRule,
      Value<int> enabled,
      Value<int> sortNumber,
    });

class $$DictRulesTableFilterComposer
    extends Composer<_$AppDatabase, $DictRulesTable> {
  $$DictRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urlRule => $composableBuilder(
    column: $table.urlRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showRule => $composableBuilder(
    column: $table.showRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortNumber => $composableBuilder(
    column: $table.sortNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictRulesTable> {
  $$DictRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urlRule => $composableBuilder(
    column: $table.urlRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showRule => $composableBuilder(
    column: $table.showRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortNumber => $composableBuilder(
    column: $table.sortNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictRulesTable> {
  $$DictRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get urlRule =>
      $composableBuilder(column: $table.urlRule, builder: (column) => column);

  GeneratedColumn<String> get showRule =>
      $composableBuilder(column: $table.showRule, builder: (column) => column);

  GeneratedColumn<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get sortNumber => $composableBuilder(
    column: $table.sortNumber,
    builder: (column) => column,
  );
}

class $$DictRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictRulesTable,
          DictRuleRow,
          $$DictRulesTableFilterComposer,
          $$DictRulesTableOrderingComposer,
          $$DictRulesTableAnnotationComposer,
          $$DictRulesTableCreateCompanionBuilder,
          $$DictRulesTableUpdateCompanionBuilder,
          (
            DictRuleRow,
            BaseReferences<_$AppDatabase, $DictRulesTable, DictRuleRow>,
          ),
          DictRuleRow,
          PrefetchHooks Function()
        > {
  $$DictRulesTableTableManager(_$AppDatabase db, $DictRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DictRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DictRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DictRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> urlRule = const Value.absent(),
                Value<String?> showRule = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> sortNumber = const Value.absent(),
              }) => DictRulesCompanion(
                id: id,
                name: name,
                urlRule: urlRule,
                showRule: showRule,
                enabled: enabled,
                sortNumber: sortNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> urlRule = const Value.absent(),
                Value<String?> showRule = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> sortNumber = const Value.absent(),
              }) => DictRulesCompanion.insert(
                id: id,
                name: name,
                urlRule: urlRule,
                showRule: showRule,
                enabled: enabled,
                sortNumber: sortNumber,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictRulesTable,
      DictRuleRow,
      $$DictRulesTableFilterComposer,
      $$DictRulesTableOrderingComposer,
      $$DictRulesTableAnnotationComposer,
      $$DictRulesTableCreateCompanionBuilder,
      $$DictRulesTableUpdateCompanionBuilder,
      (
        DictRuleRow,
        BaseReferences<_$AppDatabase, $DictRulesTable, DictRuleRow>,
      ),
      DictRuleRow,
      PrefetchHooks Function()
    >;
typedef $$HttpTtsTableCreateCompanionBuilder =
    HttpTtsCompanion Function({
      Value<int> id,
      required String name,
      required String url,
      Value<String?> contentType,
      Value<String?> concurrentRate,
      Value<String?> loginUrl,
      Value<String?> loginUi,
      Value<String?> header,
      Value<String?> jsLib,
      Value<int> enabledCookieJar,
      Value<String?> loginCheckJs,
      Value<int> lastUpdateTime,
    });
typedef $$HttpTtsTableUpdateCompanionBuilder =
    HttpTtsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> url,
      Value<String?> contentType,
      Value<String?> concurrentRate,
      Value<String?> loginUrl,
      Value<String?> loginUi,
      Value<String?> header,
      Value<String?> jsLib,
      Value<int> enabledCookieJar,
      Value<String?> loginCheckJs,
      Value<int> lastUpdateTime,
    });

class $$HttpTtsTableFilterComposer
    extends Composer<_$AppDatabase, $HttpTtsTable> {
  $$HttpTtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUi => $composableBuilder(
    column: $table.loginUi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HttpTtsTableOrderingComposer
    extends Composer<_$AppDatabase, $HttpTtsTable> {
  $$HttpTtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUi => $composableBuilder(
    column: $table.loginUi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HttpTtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HttpTtsTable> {
  $$HttpTtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginUrl =>
      $composableBuilder(column: $table.loginUrl, builder: (column) => column);

  GeneratedColumn<String> get loginUi =>
      $composableBuilder(column: $table.loginUi, builder: (column) => column);

  GeneratedColumn<String> get header =>
      $composableBuilder(column: $table.header, builder: (column) => column);

  GeneratedColumn<String> get jsLib =>
      $composableBuilder(column: $table.jsLib, builder: (column) => column);

  GeneratedColumn<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => column,
  );
}

class $$HttpTtsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HttpTtsTable,
          HttpTtsRow,
          $$HttpTtsTableFilterComposer,
          $$HttpTtsTableOrderingComposer,
          $$HttpTtsTableAnnotationComposer,
          $$HttpTtsTableCreateCompanionBuilder,
          $$HttpTtsTableUpdateCompanionBuilder,
          (
            HttpTtsRow,
            BaseReferences<_$AppDatabase, $HttpTtsTable, HttpTtsRow>,
          ),
          HttpTtsRow,
          PrefetchHooks Function()
        > {
  $$HttpTtsTableTableManager(_$AppDatabase db, $HttpTtsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$HttpTtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HttpTtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$HttpTtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> contentType = const Value.absent(),
                Value<String?> concurrentRate = const Value.absent(),
                Value<String?> loginUrl = const Value.absent(),
                Value<String?> loginUi = const Value.absent(),
                Value<String?> header = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<int> enabledCookieJar = const Value.absent(),
                Value<String?> loginCheckJs = const Value.absent(),
                Value<int> lastUpdateTime = const Value.absent(),
              }) => HttpTtsCompanion(
                id: id,
                name: name,
                url: url,
                contentType: contentType,
                concurrentRate: concurrentRate,
                loginUrl: loginUrl,
                loginUi: loginUi,
                header: header,
                jsLib: jsLib,
                enabledCookieJar: enabledCookieJar,
                loginCheckJs: loginCheckJs,
                lastUpdateTime: lastUpdateTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String url,
                Value<String?> contentType = const Value.absent(),
                Value<String?> concurrentRate = const Value.absent(),
                Value<String?> loginUrl = const Value.absent(),
                Value<String?> loginUi = const Value.absent(),
                Value<String?> header = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<int> enabledCookieJar = const Value.absent(),
                Value<String?> loginCheckJs = const Value.absent(),
                Value<int> lastUpdateTime = const Value.absent(),
              }) => HttpTtsCompanion.insert(
                id: id,
                name: name,
                url: url,
                contentType: contentType,
                concurrentRate: concurrentRate,
                loginUrl: loginUrl,
                loginUi: loginUi,
                header: header,
                jsLib: jsLib,
                enabledCookieJar: enabledCookieJar,
                loginCheckJs: loginCheckJs,
                lastUpdateTime: lastUpdateTime,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HttpTtsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HttpTtsTable,
      HttpTtsRow,
      $$HttpTtsTableFilterComposer,
      $$HttpTtsTableOrderingComposer,
      $$HttpTtsTableAnnotationComposer,
      $$HttpTtsTableCreateCompanionBuilder,
      $$HttpTtsTableUpdateCompanionBuilder,
      (HttpTtsRow, BaseReferences<_$AppDatabase, $HttpTtsTable, HttpTtsRow>),
      HttpTtsRow,
      PrefetchHooks Function()
    >;
typedef $$ReadRecordsTableCreateCompanionBuilder =
    ReadRecordsCompanion Function({
      Value<int> id,
      required String bookName,
      required String deviceId,
      Value<int> readTime,
      Value<int> lastRead,
    });
typedef $$ReadRecordsTableUpdateCompanionBuilder =
    ReadRecordsCompanion Function({
      Value<int> id,
      Value<String> bookName,
      Value<String> deviceId,
      Value<int> readTime,
      Value<int> lastRead,
    });

class $$ReadRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadRecordsTable> {
  $$ReadRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readTime => $composableBuilder(
    column: $table.readTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRead => $composableBuilder(
    column: $table.lastRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadRecordsTable> {
  $$ReadRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readTime => $composableBuilder(
    column: $table.readTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRead => $composableBuilder(
    column: $table.lastRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadRecordsTable> {
  $$ReadRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get readTime =>
      $composableBuilder(column: $table.readTime, builder: (column) => column);

  GeneratedColumn<int> get lastRead =>
      $composableBuilder(column: $table.lastRead, builder: (column) => column);
}

class $$ReadRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadRecordsTable,
          ReadRecordRow,
          $$ReadRecordsTableFilterComposer,
          $$ReadRecordsTableOrderingComposer,
          $$ReadRecordsTableAnnotationComposer,
          $$ReadRecordsTableCreateCompanionBuilder,
          $$ReadRecordsTableUpdateCompanionBuilder,
          (
            ReadRecordRow,
            BaseReferences<_$AppDatabase, $ReadRecordsTable, ReadRecordRow>,
          ),
          ReadRecordRow,
          PrefetchHooks Function()
        > {
  $$ReadRecordsTableTableManager(_$AppDatabase db, $ReadRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ReadRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ReadRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$ReadRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> readTime = const Value.absent(),
                Value<int> lastRead = const Value.absent(),
              }) => ReadRecordsCompanion(
                id: id,
                bookName: bookName,
                deviceId: deviceId,
                readTime: readTime,
                lastRead: lastRead,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bookName,
                required String deviceId,
                Value<int> readTime = const Value.absent(),
                Value<int> lastRead = const Value.absent(),
              }) => ReadRecordsCompanion.insert(
                id: id,
                bookName: bookName,
                deviceId: deviceId,
                readTime: readTime,
                lastRead: lastRead,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadRecordsTable,
      ReadRecordRow,
      $$ReadRecordsTableFilterComposer,
      $$ReadRecordsTableOrderingComposer,
      $$ReadRecordsTableAnnotationComposer,
      $$ReadRecordsTableCreateCompanionBuilder,
      $$ReadRecordsTableUpdateCompanionBuilder,
      (
        ReadRecordRow,
        BaseReferences<_$AppDatabase, $ReadRecordsTable, ReadRecordRow>,
      ),
      ReadRecordRow,
      PrefetchHooks Function()
    >;
typedef $$RssArticlesTableCreateCompanionBuilder =
    RssArticlesCompanion Function({
      required String link,
      required String origin,
      required String sort,
      required String title,
      Value<int> order,
      Value<String?> pubDate,
      Value<String?> description,
      Value<String?> content,
      Value<String?> image,
      Value<String?> group,
      Value<int> read,
      Value<String?> variable,
      Value<int> rowid,
    });
typedef $$RssArticlesTableUpdateCompanionBuilder =
    RssArticlesCompanion Function({
      Value<String> link,
      Value<String> origin,
      Value<String> sort,
      Value<String> title,
      Value<int> order,
      Value<String?> pubDate,
      Value<String?> description,
      Value<String?> content,
      Value<String?> image,
      Value<String?> group,
      Value<int> read,
      Value<String?> variable,
      Value<int> rowid,
    });

class $$RssArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $RssArticlesTable> {
  $$RssArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RssArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $RssArticlesTable> {
  $$RssArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RssArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RssArticlesTable> {
  $$RssArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get pubDate =>
      $composableBuilder(column: $table.pubDate, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get group =>
      $composableBuilder(column: $table.group, builder: (column) => column);

  GeneratedColumn<int> get read =>
      $composableBuilder(column: $table.read, builder: (column) => column);

  GeneratedColumn<String> get variable =>
      $composableBuilder(column: $table.variable, builder: (column) => column);
}

class $$RssArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RssArticlesTable,
          RssArticleRow,
          $$RssArticlesTableFilterComposer,
          $$RssArticlesTableOrderingComposer,
          $$RssArticlesTableAnnotationComposer,
          $$RssArticlesTableCreateCompanionBuilder,
          $$RssArticlesTableUpdateCompanionBuilder,
          (
            RssArticleRow,
            BaseReferences<_$AppDatabase, $RssArticlesTable, RssArticleRow>,
          ),
          RssArticleRow,
          PrefetchHooks Function()
        > {
  $$RssArticlesTableTableManager(_$AppDatabase db, $RssArticlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RssArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RssArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$RssArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> link = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> sort = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<String?> group = const Value.absent(),
                Value<int> read = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesCompanion(
                link: link,
                origin: origin,
                sort: sort,
                title: title,
                order: order,
                pubDate: pubDate,
                description: description,
                content: content,
                image: image,
                group: group,
                read: read,
                variable: variable,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String link,
                required String origin,
                required String sort,
                required String title,
                Value<int> order = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<String?> group = const Value.absent(),
                Value<int> read = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesCompanion.insert(
                link: link,
                origin: origin,
                sort: sort,
                title: title,
                order: order,
                pubDate: pubDate,
                description: description,
                content: content,
                image: image,
                group: group,
                read: read,
                variable: variable,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RssArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RssArticlesTable,
      RssArticleRow,
      $$RssArticlesTableFilterComposer,
      $$RssArticlesTableOrderingComposer,
      $$RssArticlesTableAnnotationComposer,
      $$RssArticlesTableCreateCompanionBuilder,
      $$RssArticlesTableUpdateCompanionBuilder,
      (
        RssArticleRow,
        BaseReferences<_$AppDatabase, $RssArticlesTable, RssArticleRow>,
      ),
      RssArticleRow,
      PrefetchHooks Function()
    >;
typedef $$RssSourcesTableCreateCompanionBuilder =
    RssSourcesCompanion Function({
      required String sourceUrl,
      required String sourceName,
      Value<String?> sourceIcon,
      Value<String?> sourceGroup,
      Value<String?> sourceComment,
      Value<int> enabled,
      Value<String?> variableComment,
      Value<String?> jsLib,
      Value<int> enabledCookieJar,
      Value<String?> concurrentRate,
      Value<String?> header,
      Value<String?> loginUrl,
      Value<String?> loginUi,
      Value<String?> loginCheckJs,
      Value<String?> coverDecodeJs,
      Value<String?> sortUrl,
      Value<int> singleUrl,
      Value<int> articleStyle,
      Value<String?> ruleArticles,
      Value<String?> ruleNextPage,
      Value<String?> ruleTitle,
      Value<String?> rulePubDate,
      Value<String?> ruleDescription,
      Value<String?> ruleImage,
      Value<String?> ruleLink,
      Value<String?> ruleContent,
      Value<String?> contentWhitelist,
      Value<String?> contentBlacklist,
      Value<String?> shouldOverrideUrlLoading,
      Value<String?> style,
      Value<int> enableJs,
      Value<int> loadWithBaseUrl,
      Value<String?> injectJs,
      Value<int> lastUpdateTime,
      Value<int> customOrder,
      Value<int> rowid,
    });
typedef $$RssSourcesTableUpdateCompanionBuilder =
    RssSourcesCompanion Function({
      Value<String> sourceUrl,
      Value<String> sourceName,
      Value<String?> sourceIcon,
      Value<String?> sourceGroup,
      Value<String?> sourceComment,
      Value<int> enabled,
      Value<String?> variableComment,
      Value<String?> jsLib,
      Value<int> enabledCookieJar,
      Value<String?> concurrentRate,
      Value<String?> header,
      Value<String?> loginUrl,
      Value<String?> loginUi,
      Value<String?> loginCheckJs,
      Value<String?> coverDecodeJs,
      Value<String?> sortUrl,
      Value<int> singleUrl,
      Value<int> articleStyle,
      Value<String?> ruleArticles,
      Value<String?> ruleNextPage,
      Value<String?> ruleTitle,
      Value<String?> rulePubDate,
      Value<String?> ruleDescription,
      Value<String?> ruleImage,
      Value<String?> ruleLink,
      Value<String?> ruleContent,
      Value<String?> contentWhitelist,
      Value<String?> contentBlacklist,
      Value<String?> shouldOverrideUrlLoading,
      Value<String?> style,
      Value<int> enableJs,
      Value<int> loadWithBaseUrl,
      Value<String?> injectJs,
      Value<int> lastUpdateTime,
      Value<int> customOrder,
      Value<int> rowid,
    });

class $$RssSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $RssSourcesTable> {
  $$RssSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceIcon => $composableBuilder(
    column: $table.sourceIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceGroup => $composableBuilder(
    column: $table.sourceGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceComment => $composableBuilder(
    column: $table.sourceComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variableComment => $composableBuilder(
    column: $table.variableComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUi => $composableBuilder(
    column: $table.loginUi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverDecodeJs => $composableBuilder(
    column: $table.coverDecodeJs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortUrl => $composableBuilder(
    column: $table.sortUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get singleUrl => $composableBuilder(
    column: $table.singleUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get articleStyle => $composableBuilder(
    column: $table.articleStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleArticles => $composableBuilder(
    column: $table.ruleArticles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleNextPage => $composableBuilder(
    column: $table.ruleNextPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleTitle => $composableBuilder(
    column: $table.ruleTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rulePubDate => $composableBuilder(
    column: $table.rulePubDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleDescription => $composableBuilder(
    column: $table.ruleDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleImage => $composableBuilder(
    column: $table.ruleImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleLink => $composableBuilder(
    column: $table.ruleLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleContent => $composableBuilder(
    column: $table.ruleContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentWhitelist => $composableBuilder(
    column: $table.contentWhitelist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentBlacklist => $composableBuilder(
    column: $table.contentBlacklist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shouldOverrideUrlLoading => $composableBuilder(
    column: $table.shouldOverrideUrlLoading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enableJs => $composableBuilder(
    column: $table.enableJs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loadWithBaseUrl => $composableBuilder(
    column: $table.loadWithBaseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get injectJs => $composableBuilder(
    column: $table.injectJs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RssSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $RssSourcesTable> {
  $$RssSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceIcon => $composableBuilder(
    column: $table.sourceIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceGroup => $composableBuilder(
    column: $table.sourceGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceComment => $composableBuilder(
    column: $table.sourceComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variableComment => $composableBuilder(
    column: $table.variableComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUi => $composableBuilder(
    column: $table.loginUi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverDecodeJs => $composableBuilder(
    column: $table.coverDecodeJs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortUrl => $composableBuilder(
    column: $table.sortUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get singleUrl => $composableBuilder(
    column: $table.singleUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get articleStyle => $composableBuilder(
    column: $table.articleStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleArticles => $composableBuilder(
    column: $table.ruleArticles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleNextPage => $composableBuilder(
    column: $table.ruleNextPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleTitle => $composableBuilder(
    column: $table.ruleTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rulePubDate => $composableBuilder(
    column: $table.rulePubDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleDescription => $composableBuilder(
    column: $table.ruleDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleImage => $composableBuilder(
    column: $table.ruleImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleLink => $composableBuilder(
    column: $table.ruleLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleContent => $composableBuilder(
    column: $table.ruleContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentWhitelist => $composableBuilder(
    column: $table.contentWhitelist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentBlacklist => $composableBuilder(
    column: $table.contentBlacklist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shouldOverrideUrlLoading => $composableBuilder(
    column: $table.shouldOverrideUrlLoading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enableJs => $composableBuilder(
    column: $table.enableJs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loadWithBaseUrl => $composableBuilder(
    column: $table.loadWithBaseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get injectJs => $composableBuilder(
    column: $table.injectJs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RssSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RssSourcesTable> {
  $$RssSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceIcon => $composableBuilder(
    column: $table.sourceIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceGroup => $composableBuilder(
    column: $table.sourceGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceComment => $composableBuilder(
    column: $table.sourceComment,
    builder: (column) => column,
  );

  GeneratedColumn<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get variableComment => $composableBuilder(
    column: $table.variableComment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsLib =>
      $composableBuilder(column: $table.jsLib, builder: (column) => column);

  GeneratedColumn<int> get enabledCookieJar => $composableBuilder(
    column: $table.enabledCookieJar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get header =>
      $composableBuilder(column: $table.header, builder: (column) => column);

  GeneratedColumn<String> get loginUrl =>
      $composableBuilder(column: $table.loginUrl, builder: (column) => column);

  GeneratedColumn<String> get loginUi =>
      $composableBuilder(column: $table.loginUi, builder: (column) => column);

  GeneratedColumn<String> get loginCheckJs => $composableBuilder(
    column: $table.loginCheckJs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverDecodeJs => $composableBuilder(
    column: $table.coverDecodeJs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sortUrl =>
      $composableBuilder(column: $table.sortUrl, builder: (column) => column);

  GeneratedColumn<int> get singleUrl =>
      $composableBuilder(column: $table.singleUrl, builder: (column) => column);

  GeneratedColumn<int> get articleStyle => $composableBuilder(
    column: $table.articleStyle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleArticles => $composableBuilder(
    column: $table.ruleArticles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleNextPage => $composableBuilder(
    column: $table.ruleNextPage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleTitle =>
      $composableBuilder(column: $table.ruleTitle, builder: (column) => column);

  GeneratedColumn<String> get rulePubDate => $composableBuilder(
    column: $table.rulePubDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleDescription => $composableBuilder(
    column: $table.ruleDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleImage =>
      $composableBuilder(column: $table.ruleImage, builder: (column) => column);

  GeneratedColumn<String> get ruleLink =>
      $composableBuilder(column: $table.ruleLink, builder: (column) => column);

  GeneratedColumn<String> get ruleContent => $composableBuilder(
    column: $table.ruleContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentWhitelist => $composableBuilder(
    column: $table.contentWhitelist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentBlacklist => $composableBuilder(
    column: $table.contentBlacklist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shouldOverrideUrlLoading => $composableBuilder(
    column: $table.shouldOverrideUrlLoading,
    builder: (column) => column,
  );

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<int> get enableJs =>
      $composableBuilder(column: $table.enableJs, builder: (column) => column);

  GeneratedColumn<int> get loadWithBaseUrl => $composableBuilder(
    column: $table.loadWithBaseUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get injectJs =>
      $composableBuilder(column: $table.injectJs, builder: (column) => column);

  GeneratedColumn<int> get lastUpdateTime => $composableBuilder(
    column: $table.lastUpdateTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => column,
  );
}

class $$RssSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RssSourcesTable,
          RssSourceRow,
          $$RssSourcesTableFilterComposer,
          $$RssSourcesTableOrderingComposer,
          $$RssSourcesTableAnnotationComposer,
          $$RssSourcesTableCreateCompanionBuilder,
          $$RssSourcesTableUpdateCompanionBuilder,
          (
            RssSourceRow,
            BaseReferences<_$AppDatabase, $RssSourcesTable, RssSourceRow>,
          ),
          RssSourceRow,
          PrefetchHooks Function()
        > {
  $$RssSourcesTableTableManager(_$AppDatabase db, $RssSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RssSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RssSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RssSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceUrl = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String?> sourceIcon = const Value.absent(),
                Value<String?> sourceGroup = const Value.absent(),
                Value<String?> sourceComment = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<String?> variableComment = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<int> enabledCookieJar = const Value.absent(),
                Value<String?> concurrentRate = const Value.absent(),
                Value<String?> header = const Value.absent(),
                Value<String?> loginUrl = const Value.absent(),
                Value<String?> loginUi = const Value.absent(),
                Value<String?> loginCheckJs = const Value.absent(),
                Value<String?> coverDecodeJs = const Value.absent(),
                Value<String?> sortUrl = const Value.absent(),
                Value<int> singleUrl = const Value.absent(),
                Value<int> articleStyle = const Value.absent(),
                Value<String?> ruleArticles = const Value.absent(),
                Value<String?> ruleNextPage = const Value.absent(),
                Value<String?> ruleTitle = const Value.absent(),
                Value<String?> rulePubDate = const Value.absent(),
                Value<String?> ruleDescription = const Value.absent(),
                Value<String?> ruleImage = const Value.absent(),
                Value<String?> ruleLink = const Value.absent(),
                Value<String?> ruleContent = const Value.absent(),
                Value<String?> contentWhitelist = const Value.absent(),
                Value<String?> contentBlacklist = const Value.absent(),
                Value<String?> shouldOverrideUrlLoading = const Value.absent(),
                Value<String?> style = const Value.absent(),
                Value<int> enableJs = const Value.absent(),
                Value<int> loadWithBaseUrl = const Value.absent(),
                Value<String?> injectJs = const Value.absent(),
                Value<int> lastUpdateTime = const Value.absent(),
                Value<int> customOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssSourcesCompanion(
                sourceUrl: sourceUrl,
                sourceName: sourceName,
                sourceIcon: sourceIcon,
                sourceGroup: sourceGroup,
                sourceComment: sourceComment,
                enabled: enabled,
                variableComment: variableComment,
                jsLib: jsLib,
                enabledCookieJar: enabledCookieJar,
                concurrentRate: concurrentRate,
                header: header,
                loginUrl: loginUrl,
                loginUi: loginUi,
                loginCheckJs: loginCheckJs,
                coverDecodeJs: coverDecodeJs,
                sortUrl: sortUrl,
                singleUrl: singleUrl,
                articleStyle: articleStyle,
                ruleArticles: ruleArticles,
                ruleNextPage: ruleNextPage,
                ruleTitle: ruleTitle,
                rulePubDate: rulePubDate,
                ruleDescription: ruleDescription,
                ruleImage: ruleImage,
                ruleLink: ruleLink,
                ruleContent: ruleContent,
                contentWhitelist: contentWhitelist,
                contentBlacklist: contentBlacklist,
                shouldOverrideUrlLoading: shouldOverrideUrlLoading,
                style: style,
                enableJs: enableJs,
                loadWithBaseUrl: loadWithBaseUrl,
                injectJs: injectJs,
                lastUpdateTime: lastUpdateTime,
                customOrder: customOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceUrl,
                required String sourceName,
                Value<String?> sourceIcon = const Value.absent(),
                Value<String?> sourceGroup = const Value.absent(),
                Value<String?> sourceComment = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<String?> variableComment = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<int> enabledCookieJar = const Value.absent(),
                Value<String?> concurrentRate = const Value.absent(),
                Value<String?> header = const Value.absent(),
                Value<String?> loginUrl = const Value.absent(),
                Value<String?> loginUi = const Value.absent(),
                Value<String?> loginCheckJs = const Value.absent(),
                Value<String?> coverDecodeJs = const Value.absent(),
                Value<String?> sortUrl = const Value.absent(),
                Value<int> singleUrl = const Value.absent(),
                Value<int> articleStyle = const Value.absent(),
                Value<String?> ruleArticles = const Value.absent(),
                Value<String?> ruleNextPage = const Value.absent(),
                Value<String?> ruleTitle = const Value.absent(),
                Value<String?> rulePubDate = const Value.absent(),
                Value<String?> ruleDescription = const Value.absent(),
                Value<String?> ruleImage = const Value.absent(),
                Value<String?> ruleLink = const Value.absent(),
                Value<String?> ruleContent = const Value.absent(),
                Value<String?> contentWhitelist = const Value.absent(),
                Value<String?> contentBlacklist = const Value.absent(),
                Value<String?> shouldOverrideUrlLoading = const Value.absent(),
                Value<String?> style = const Value.absent(),
                Value<int> enableJs = const Value.absent(),
                Value<int> loadWithBaseUrl = const Value.absent(),
                Value<String?> injectJs = const Value.absent(),
                Value<int> lastUpdateTime = const Value.absent(),
                Value<int> customOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssSourcesCompanion.insert(
                sourceUrl: sourceUrl,
                sourceName: sourceName,
                sourceIcon: sourceIcon,
                sourceGroup: sourceGroup,
                sourceComment: sourceComment,
                enabled: enabled,
                variableComment: variableComment,
                jsLib: jsLib,
                enabledCookieJar: enabledCookieJar,
                concurrentRate: concurrentRate,
                header: header,
                loginUrl: loginUrl,
                loginUi: loginUi,
                loginCheckJs: loginCheckJs,
                coverDecodeJs: coverDecodeJs,
                sortUrl: sortUrl,
                singleUrl: singleUrl,
                articleStyle: articleStyle,
                ruleArticles: ruleArticles,
                ruleNextPage: ruleNextPage,
                ruleTitle: ruleTitle,
                rulePubDate: rulePubDate,
                ruleDescription: ruleDescription,
                ruleImage: ruleImage,
                ruleLink: ruleLink,
                ruleContent: ruleContent,
                contentWhitelist: contentWhitelist,
                contentBlacklist: contentBlacklist,
                shouldOverrideUrlLoading: shouldOverrideUrlLoading,
                style: style,
                enableJs: enableJs,
                loadWithBaseUrl: loadWithBaseUrl,
                injectJs: injectJs,
                lastUpdateTime: lastUpdateTime,
                customOrder: customOrder,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RssSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RssSourcesTable,
      RssSourceRow,
      $$RssSourcesTableFilterComposer,
      $$RssSourcesTableOrderingComposer,
      $$RssSourcesTableAnnotationComposer,
      $$RssSourcesTableCreateCompanionBuilder,
      $$RssSourcesTableUpdateCompanionBuilder,
      (
        RssSourceRow,
        BaseReferences<_$AppDatabase, $RssSourcesTable, RssSourceRow>,
      ),
      RssSourceRow,
      PrefetchHooks Function()
    >;
typedef $$RssStarsTableCreateCompanionBuilder =
    RssStarsCompanion Function({
      required String link,
      required String origin,
      required String sort,
      required String title,
      Value<int> starTime,
      Value<String?> pubDate,
      Value<String?> description,
      Value<String?> content,
      Value<String?> image,
      Value<String?> group,
      Value<String?> variable,
      Value<int> rowid,
    });
typedef $$RssStarsTableUpdateCompanionBuilder =
    RssStarsCompanion Function({
      Value<String> link,
      Value<String> origin,
      Value<String> sort,
      Value<String> title,
      Value<int> starTime,
      Value<String?> pubDate,
      Value<String?> description,
      Value<String?> content,
      Value<String?> image,
      Value<String?> group,
      Value<String?> variable,
      Value<int> rowid,
    });

class $$RssStarsTableFilterComposer
    extends Composer<_$AppDatabase, $RssStarsTable> {
  $$RssStarsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get starTime => $composableBuilder(
    column: $table.starTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RssStarsTableOrderingComposer
    extends Composer<_$AppDatabase, $RssStarsTable> {
  $$RssStarsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get starTime => $composableBuilder(
    column: $table.starTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RssStarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RssStarsTable> {
  $$RssStarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get starTime =>
      $composableBuilder(column: $table.starTime, builder: (column) => column);

  GeneratedColumn<String> get pubDate =>
      $composableBuilder(column: $table.pubDate, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get group =>
      $composableBuilder(column: $table.group, builder: (column) => column);

  GeneratedColumn<String> get variable =>
      $composableBuilder(column: $table.variable, builder: (column) => column);
}

class $$RssStarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RssStarsTable,
          RssStarRow,
          $$RssStarsTableFilterComposer,
          $$RssStarsTableOrderingComposer,
          $$RssStarsTableAnnotationComposer,
          $$RssStarsTableCreateCompanionBuilder,
          $$RssStarsTableUpdateCompanionBuilder,
          (
            RssStarRow,
            BaseReferences<_$AppDatabase, $RssStarsTable, RssStarRow>,
          ),
          RssStarRow,
          PrefetchHooks Function()
        > {
  $$RssStarsTableTableManager(_$AppDatabase db, $RssStarsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RssStarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RssStarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RssStarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> link = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> sort = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> starTime = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<String?> group = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssStarsCompanion(
                link: link,
                origin: origin,
                sort: sort,
                title: title,
                starTime: starTime,
                pubDate: pubDate,
                description: description,
                content: content,
                image: image,
                group: group,
                variable: variable,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String link,
                required String origin,
                required String sort,
                required String title,
                Value<int> starTime = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<String?> group = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssStarsCompanion.insert(
                link: link,
                origin: origin,
                sort: sort,
                title: title,
                starTime: starTime,
                pubDate: pubDate,
                description: description,
                content: content,
                image: image,
                group: group,
                variable: variable,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RssStarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RssStarsTable,
      RssStarRow,
      $$RssStarsTableFilterComposer,
      $$RssStarsTableOrderingComposer,
      $$RssStarsTableAnnotationComposer,
      $$RssStarsTableCreateCompanionBuilder,
      $$RssStarsTableUpdateCompanionBuilder,
      (RssStarRow, BaseReferences<_$AppDatabase, $RssStarsTable, RssStarRow>),
      RssStarRow,
      PrefetchHooks Function()
    >;
typedef $$ServersTableCreateCompanionBuilder =
    ServersCompanion Function({
      Value<int> id,
      required String name,
      required String type,
      Value<String?> config,
      Value<int> sortNumber,
    });
typedef $$ServersTableUpdateCompanionBuilder =
    ServersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> type,
      Value<String?> config,
      Value<int> sortNumber,
    });

class $$ServersTableFilterComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortNumber => $composableBuilder(
    column: $table.sortNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServersTableOrderingComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortNumber => $composableBuilder(
    column: $table.sortNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<int> get sortNumber => $composableBuilder(
    column: $table.sortNumber,
    builder: (column) => column,
  );
}

class $$ServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServersTable,
          ServerRow,
          $$ServersTableFilterComposer,
          $$ServersTableOrderingComposer,
          $$ServersTableAnnotationComposer,
          $$ServersTableCreateCompanionBuilder,
          $$ServersTableUpdateCompanionBuilder,
          (ServerRow, BaseReferences<_$AppDatabase, $ServersTable, ServerRow>),
          ServerRow,
          PrefetchHooks Function()
        > {
  $$ServersTableTableManager(_$AppDatabase db, $ServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> config = const Value.absent(),
                Value<int> sortNumber = const Value.absent(),
              }) => ServersCompanion(
                id: id,
                name: name,
                type: type,
                config: config,
                sortNumber: sortNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                Value<String?> config = const Value.absent(),
                Value<int> sortNumber = const Value.absent(),
              }) => ServersCompanion.insert(
                id: id,
                name: name,
                type: type,
                config: config,
                sortNumber: sortNumber,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServersTable,
      ServerRow,
      $$ServersTableFilterComposer,
      $$ServersTableOrderingComposer,
      $$ServersTableAnnotationComposer,
      $$ServersTableCreateCompanionBuilder,
      $$ServersTableUpdateCompanionBuilder,
      (ServerRow, BaseReferences<_$AppDatabase, $ServersTable, ServerRow>),
      ServerRow,
      PrefetchHooks Function()
    >;
typedef $$TxtTocRulesTableCreateCompanionBuilder =
    TxtTocRulesCompanion Function({
      Value<int> id,
      required String name,
      required String rule,
      Value<String?> example,
      Value<int> serialNumber,
      Value<int> enable,
    });
typedef $$TxtTocRulesTableUpdateCompanionBuilder =
    TxtTocRulesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> rule,
      Value<String?> example,
      Value<int> serialNumber,
      Value<int> enable,
    });

class $$TxtTocRulesTableFilterComposer
    extends Composer<_$AppDatabase, $TxtTocRulesTable> {
  $$TxtTocRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enable => $composableBuilder(
    column: $table.enable,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TxtTocRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $TxtTocRulesTable> {
  $$TxtTocRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enable => $composableBuilder(
    column: $table.enable,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TxtTocRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TxtTocRulesTable> {
  $$TxtTocRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rule =>
      $composableBuilder(column: $table.rule, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<int> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get enable =>
      $composableBuilder(column: $table.enable, builder: (column) => column);
}

class $$TxtTocRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TxtTocRulesTable,
          TxtTocRuleRow,
          $$TxtTocRulesTableFilterComposer,
          $$TxtTocRulesTableOrderingComposer,
          $$TxtTocRulesTableAnnotationComposer,
          $$TxtTocRulesTableCreateCompanionBuilder,
          $$TxtTocRulesTableUpdateCompanionBuilder,
          (
            TxtTocRuleRow,
            BaseReferences<_$AppDatabase, $TxtTocRulesTable, TxtTocRuleRow>,
          ),
          TxtTocRuleRow,
          PrefetchHooks Function()
        > {
  $$TxtTocRulesTableTableManager(_$AppDatabase db, $TxtTocRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TxtTocRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TxtTocRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$TxtTocRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> rule = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<int> serialNumber = const Value.absent(),
                Value<int> enable = const Value.absent(),
              }) => TxtTocRulesCompanion(
                id: id,
                name: name,
                rule: rule,
                example: example,
                serialNumber: serialNumber,
                enable: enable,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String rule,
                Value<String?> example = const Value.absent(),
                Value<int> serialNumber = const Value.absent(),
                Value<int> enable = const Value.absent(),
              }) => TxtTocRulesCompanion.insert(
                id: id,
                name: name,
                rule: rule,
                example: example,
                serialNumber: serialNumber,
                enable: enable,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TxtTocRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TxtTocRulesTable,
      TxtTocRuleRow,
      $$TxtTocRulesTableFilterComposer,
      $$TxtTocRulesTableOrderingComposer,
      $$TxtTocRulesTableAnnotationComposer,
      $$TxtTocRulesTableCreateCompanionBuilder,
      $$TxtTocRulesTableUpdateCompanionBuilder,
      (
        TxtTocRuleRow,
        BaseReferences<_$AppDatabase, $TxtTocRulesTable, TxtTocRuleRow>,
      ),
      TxtTocRuleRow,
      PrefetchHooks Function()
    >;
typedef $$CacheTableCreateCompanionBuilder =
    CacheCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> deadline,
      Value<int> rowid,
    });
typedef $$CacheTableUpdateCompanionBuilder =
    CacheCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> deadline,
      Value<int> rowid,
    });

class $$CacheTableFilterComposer extends Composer<_$AppDatabase, $CacheTable> {
  $$CacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheTable> {
  $$CacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheTable> {
  $$CacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);
}

class $$CacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheTable,
          CacheRow,
          $$CacheTableFilterComposer,
          $$CacheTableOrderingComposer,
          $$CacheTableAnnotationComposer,
          $$CacheTableCreateCompanionBuilder,
          $$CacheTableUpdateCompanionBuilder,
          (CacheRow, BaseReferences<_$AppDatabase, $CacheTable, CacheRow>),
          CacheRow,
          PrefetchHooks Function()
        > {
  $$CacheTableTableManager(_$AppDatabase db, $CacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> deadline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheCompanion(
                key: key,
                value: value,
                deadline: deadline,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> deadline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheCompanion.insert(
                key: key,
                value: value,
                deadline: deadline,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheTable,
      CacheRow,
      $$CacheTableFilterComposer,
      $$CacheTableOrderingComposer,
      $$CacheTableAnnotationComposer,
      $$CacheTableCreateCompanionBuilder,
      $$CacheTableUpdateCompanionBuilder,
      (CacheRow, BaseReferences<_$AppDatabase, $CacheTable, CacheRow>),
      CacheRow,
      PrefetchHooks Function()
    >;
typedef $$KeyboardAssistsTableCreateCompanionBuilder =
    KeyboardAssistsCompanion Function({
      required String key,
      Value<int> type,
      Value<String?> value,
      Value<int> serialNo,
      Value<int> rowid,
    });
typedef $$KeyboardAssistsTableUpdateCompanionBuilder =
    KeyboardAssistsCompanion Function({
      Value<String> key,
      Value<int> type,
      Value<String?> value,
      Value<int> serialNo,
      Value<int> rowid,
    });

class $$KeyboardAssistsTableFilterComposer
    extends Composer<_$AppDatabase, $KeyboardAssistsTable> {
  $$KeyboardAssistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serialNo => $composableBuilder(
    column: $table.serialNo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyboardAssistsTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyboardAssistsTable> {
  $$KeyboardAssistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serialNo => $composableBuilder(
    column: $table.serialNo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyboardAssistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyboardAssistsTable> {
  $$KeyboardAssistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get serialNo =>
      $composableBuilder(column: $table.serialNo, builder: (column) => column);
}

class $$KeyboardAssistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyboardAssistsTable,
          KeyboardAssistRow,
          $$KeyboardAssistsTableFilterComposer,
          $$KeyboardAssistsTableOrderingComposer,
          $$KeyboardAssistsTableAnnotationComposer,
          $$KeyboardAssistsTableCreateCompanionBuilder,
          $$KeyboardAssistsTableUpdateCompanionBuilder,
          (
            KeyboardAssistRow,
            BaseReferences<
              _$AppDatabase,
              $KeyboardAssistsTable,
              KeyboardAssistRow
            >,
          ),
          KeyboardAssistRow,
          PrefetchHooks Function()
        > {
  $$KeyboardAssistsTableTableManager(
    _$AppDatabase db,
    $KeyboardAssistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$KeyboardAssistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$KeyboardAssistsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$KeyboardAssistsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> serialNo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyboardAssistsCompanion(
                key: key,
                type: type,
                value: value,
                serialNo: serialNo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<int> type = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> serialNo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyboardAssistsCompanion.insert(
                key: key,
                type: type,
                value: value,
                serialNo: serialNo,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyboardAssistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyboardAssistsTable,
      KeyboardAssistRow,
      $$KeyboardAssistsTableFilterComposer,
      $$KeyboardAssistsTableOrderingComposer,
      $$KeyboardAssistsTableAnnotationComposer,
      $$KeyboardAssistsTableCreateCompanionBuilder,
      $$KeyboardAssistsTableUpdateCompanionBuilder,
      (
        KeyboardAssistRow,
        BaseReferences<_$AppDatabase, $KeyboardAssistsTable, KeyboardAssistRow>,
      ),
      KeyboardAssistRow,
      PrefetchHooks Function()
    >;
typedef $$RssReadRecordsTableCreateCompanionBuilder =
    RssReadRecordsCompanion Function({
      required String record,
      Value<String?> title,
      Value<int> readTime,
      Value<int> read,
      Value<int> rowid,
    });
typedef $$RssReadRecordsTableUpdateCompanionBuilder =
    RssReadRecordsCompanion Function({
      Value<String> record,
      Value<String?> title,
      Value<int> readTime,
      Value<int> read,
      Value<int> rowid,
    });

class $$RssReadRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RssReadRecordsTable> {
  $$RssReadRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readTime => $composableBuilder(
    column: $table.readTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RssReadRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RssReadRecordsTable> {
  $$RssReadRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readTime => $composableBuilder(
    column: $table.readTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RssReadRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RssReadRecordsTable> {
  $$RssReadRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get record =>
      $composableBuilder(column: $table.record, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get readTime =>
      $composableBuilder(column: $table.readTime, builder: (column) => column);

  GeneratedColumn<int> get read =>
      $composableBuilder(column: $table.read, builder: (column) => column);
}

class $$RssReadRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RssReadRecordsTable,
          RssReadRecordRow,
          $$RssReadRecordsTableFilterComposer,
          $$RssReadRecordsTableOrderingComposer,
          $$RssReadRecordsTableAnnotationComposer,
          $$RssReadRecordsTableCreateCompanionBuilder,
          $$RssReadRecordsTableUpdateCompanionBuilder,
          (
            RssReadRecordRow,
            BaseReferences<
              _$AppDatabase,
              $RssReadRecordsTable,
              RssReadRecordRow
            >,
          ),
          RssReadRecordRow,
          PrefetchHooks Function()
        > {
  $$RssReadRecordsTableTableManager(
    _$AppDatabase db,
    $RssReadRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RssReadRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$RssReadRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RssReadRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> record = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int> readTime = const Value.absent(),
                Value<int> read = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssReadRecordsCompanion(
                record: record,
                title: title,
                readTime: readTime,
                read: read,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String record,
                Value<String?> title = const Value.absent(),
                Value<int> readTime = const Value.absent(),
                Value<int> read = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssReadRecordsCompanion.insert(
                record: record,
                title: title,
                readTime: readTime,
                read: read,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RssReadRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RssReadRecordsTable,
      RssReadRecordRow,
      $$RssReadRecordsTableFilterComposer,
      $$RssReadRecordsTableOrderingComposer,
      $$RssReadRecordsTableAnnotationComposer,
      $$RssReadRecordsTableCreateCompanionBuilder,
      $$RssReadRecordsTableUpdateCompanionBuilder,
      (
        RssReadRecordRow,
        BaseReferences<_$AppDatabase, $RssReadRecordsTable, RssReadRecordRow>,
      ),
      RssReadRecordRow,
      PrefetchHooks Function()
    >;
typedef $$RuleSubsTableCreateCompanionBuilder =
    RuleSubsCompanion Function({
      Value<int> id,
      required String name,
      required String url,
      Value<int> type,
      Value<int> enabled,
      Value<int> order,
    });
typedef $$RuleSubsTableUpdateCompanionBuilder =
    RuleSubsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> url,
      Value<int> type,
      Value<int> enabled,
      Value<int> order,
    });

class $$RuleSubsTableFilterComposer
    extends Composer<_$AppDatabase, $RuleSubsTable> {
  $$RuleSubsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RuleSubsTableOrderingComposer
    extends Composer<_$AppDatabase, $RuleSubsTable> {
  $$RuleSubsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RuleSubsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuleSubsTable> {
  $$RuleSubsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);
}

class $$RuleSubsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuleSubsTable,
          RuleSubRow,
          $$RuleSubsTableFilterComposer,
          $$RuleSubsTableOrderingComposer,
          $$RuleSubsTableAnnotationComposer,
          $$RuleSubsTableCreateCompanionBuilder,
          $$RuleSubsTableUpdateCompanionBuilder,
          (
            RuleSubRow,
            BaseReferences<_$AppDatabase, $RuleSubsTable, RuleSubRow>,
          ),
          RuleSubRow,
          PrefetchHooks Function()
        > {
  $$RuleSubsTableTableManager(_$AppDatabase db, $RuleSubsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RuleSubsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RuleSubsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RuleSubsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> order = const Value.absent(),
              }) => RuleSubsCompanion(
                id: id,
                name: name,
                url: url,
                type: type,
                enabled: enabled,
                order: order,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String url,
                Value<int> type = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> order = const Value.absent(),
              }) => RuleSubsCompanion.insert(
                id: id,
                name: name,
                url: url,
                type: type,
                enabled: enabled,
                order: order,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuleSubsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuleSubsTable,
      RuleSubRow,
      $$RuleSubsTableFilterComposer,
      $$RuleSubsTableOrderingComposer,
      $$RuleSubsTableAnnotationComposer,
      $$RuleSubsTableCreateCompanionBuilder,
      $$RuleSubsTableUpdateCompanionBuilder,
      (RuleSubRow, BaseReferences<_$AppDatabase, $RuleSubsTable, RuleSubRow>),
      RuleSubRow,
      PrefetchHooks Function()
    >;
typedef $$SourceSubscriptionsTableCreateCompanionBuilder =
    SourceSubscriptionsCompanion Function({
      required String url,
      required String name,
      Value<int> type,
      Value<int> enabled,
      Value<int> order,
      Value<int> rowid,
    });
typedef $$SourceSubscriptionsTableUpdateCompanionBuilder =
    SourceSubscriptionsCompanion Function({
      Value<String> url,
      Value<String> name,
      Value<int> type,
      Value<int> enabled,
      Value<int> order,
      Value<int> rowid,
    });

class $$SourceSubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SourceSubscriptionsTable> {
  $$SourceSubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourceSubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SourceSubscriptionsTable> {
  $$SourceSubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourceSubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourceSubscriptionsTable> {
  $$SourceSubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);
}

class $$SourceSubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourceSubscriptionsTable,
          SourceSubscriptionRow,
          $$SourceSubscriptionsTableFilterComposer,
          $$SourceSubscriptionsTableOrderingComposer,
          $$SourceSubscriptionsTableAnnotationComposer,
          $$SourceSubscriptionsTableCreateCompanionBuilder,
          $$SourceSubscriptionsTableUpdateCompanionBuilder,
          (
            SourceSubscriptionRow,
            BaseReferences<
              _$AppDatabase,
              $SourceSubscriptionsTable,
              SourceSubscriptionRow
            >,
          ),
          SourceSubscriptionRow,
          PrefetchHooks Function()
        > {
  $$SourceSubscriptionsTableTableManager(
    _$AppDatabase db,
    $SourceSubscriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SourceSubscriptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$SourceSubscriptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SourceSubscriptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceSubscriptionsCompanion(
                url: url,
                name: name,
                type: type,
                enabled: enabled,
                order: order,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required String name,
                Value<int> type = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceSubscriptionsCompanion.insert(
                url: url,
                name: name,
                type: type,
                enabled: enabled,
                order: order,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourceSubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourceSubscriptionsTable,
      SourceSubscriptionRow,
      $$SourceSubscriptionsTableFilterComposer,
      $$SourceSubscriptionsTableOrderingComposer,
      $$SourceSubscriptionsTableAnnotationComposer,
      $$SourceSubscriptionsTableCreateCompanionBuilder,
      $$SourceSubscriptionsTableUpdateCompanionBuilder,
      (
        SourceSubscriptionRow,
        BaseReferences<
          _$AppDatabase,
          $SourceSubscriptionsTable,
          SourceSubscriptionRow
        >,
      ),
      SourceSubscriptionRow,
      PrefetchHooks Function()
    >;
typedef $$SearchBooksTableCreateCompanionBuilder =
    SearchBooksCompanion Function({
      required String bookUrl,
      required String name,
      Value<String?> author,
      Value<String?> kind,
      Value<String?> coverUrl,
      Value<String?> intro,
      Value<String?> wordCount,
      Value<String?> latestChapterTitle,
      Value<String?> origin,
      Value<String?> originName,
      Value<int> originOrder,
      Value<int> type,
      Value<int> addTime,
      Value<String?> variable,
      Value<String?> tocUrl,
      Value<int> rowid,
    });
typedef $$SearchBooksTableUpdateCompanionBuilder =
    SearchBooksCompanion Function({
      Value<String> bookUrl,
      Value<String> name,
      Value<String?> author,
      Value<String?> kind,
      Value<String?> coverUrl,
      Value<String?> intro,
      Value<String?> wordCount,
      Value<String?> latestChapterTitle,
      Value<String?> origin,
      Value<String?> originName,
      Value<int> originOrder,
      Value<int> type,
      Value<int> addTime,
      Value<String?> variable,
      Value<String?> tocUrl,
      Value<int> rowid,
    });

class $$SearchBooksTableFilterComposer
    extends Composer<_$AppDatabase, $SearchBooksTable> {
  $$SearchBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intro => $composableBuilder(
    column: $table.intro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestChapterTitle => $composableBuilder(
    column: $table.latestChapterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originOrder => $composableBuilder(
    column: $table.originOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tocUrl => $composableBuilder(
    column: $table.tocUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchBooksTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchBooksTable> {
  $$SearchBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intro => $composableBuilder(
    column: $table.intro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestChapterTitle => $composableBuilder(
    column: $table.latestChapterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originOrder => $composableBuilder(
    column: $table.originOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variable => $composableBuilder(
    column: $table.variable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tocUrl => $composableBuilder(
    column: $table.tocUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchBooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchBooksTable> {
  $$SearchBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookUrl =>
      $composableBuilder(column: $table.bookUrl, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get intro =>
      $composableBuilder(column: $table.intro, builder: (column) => column);

  GeneratedColumn<String> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<String> get latestChapterTitle => $composableBuilder(
    column: $table.latestChapterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originOrder => $composableBuilder(
    column: $table.originOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get addTime =>
      $composableBuilder(column: $table.addTime, builder: (column) => column);

  GeneratedColumn<String> get variable =>
      $composableBuilder(column: $table.variable, builder: (column) => column);

  GeneratedColumn<String> get tocUrl =>
      $composableBuilder(column: $table.tocUrl, builder: (column) => column);
}

class $$SearchBooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchBooksTable,
          SearchBookRow,
          $$SearchBooksTableFilterComposer,
          $$SearchBooksTableOrderingComposer,
          $$SearchBooksTableAnnotationComposer,
          $$SearchBooksTableCreateCompanionBuilder,
          $$SearchBooksTableUpdateCompanionBuilder,
          (
            SearchBookRow,
            BaseReferences<_$AppDatabase, $SearchBooksTable, SearchBookRow>,
          ),
          SearchBookRow,
          PrefetchHooks Function()
        > {
  $$SearchBooksTableTableManager(_$AppDatabase db, $SearchBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SearchBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SearchBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$SearchBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookUrl = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> intro = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<String?> latestChapterTitle = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                Value<int> originOrder = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> addTime = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<String?> tocUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchBooksCompanion(
                bookUrl: bookUrl,
                name: name,
                author: author,
                kind: kind,
                coverUrl: coverUrl,
                intro: intro,
                wordCount: wordCount,
                latestChapterTitle: latestChapterTitle,
                origin: origin,
                originName: originName,
                originOrder: originOrder,
                type: type,
                addTime: addTime,
                variable: variable,
                tocUrl: tocUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookUrl,
                required String name,
                Value<String?> author = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> intro = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<String?> latestChapterTitle = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                Value<int> originOrder = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> addTime = const Value.absent(),
                Value<String?> variable = const Value.absent(),
                Value<String?> tocUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchBooksCompanion.insert(
                bookUrl: bookUrl,
                name: name,
                author: author,
                kind: kind,
                coverUrl: coverUrl,
                intro: intro,
                wordCount: wordCount,
                latestChapterTitle: latestChapterTitle,
                origin: origin,
                originName: originName,
                originOrder: originOrder,
                type: type,
                addTime: addTime,
                variable: variable,
                tocUrl: tocUrl,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchBooksTable,
      SearchBookRow,
      $$SearchBooksTableFilterComposer,
      $$SearchBooksTableOrderingComposer,
      $$SearchBooksTableAnnotationComposer,
      $$SearchBooksTableCreateCompanionBuilder,
      $$SearchBooksTableUpdateCompanionBuilder,
      (
        SearchBookRow,
        BaseReferences<_$AppDatabase, $SearchBooksTable, SearchBookRow>,
      ),
      SearchBookRow,
      PrefetchHooks Function()
    >;
typedef $$DownloadTasksTableCreateCompanionBuilder =
    DownloadTasksCompanion Function({
      required String bookUrl,
      required String bookName,
      Value<int> currentChapterIndex,
      Value<int> totalChapterCount,
      Value<int> status,
      Value<int> successCount,
      Value<int> errorCount,
      Value<int> addTime,
      Value<int> rowid,
    });
typedef $$DownloadTasksTableUpdateCompanionBuilder =
    DownloadTasksCompanion Function({
      Value<String> bookUrl,
      Value<String> bookName,
      Value<int> currentChapterIndex,
      Value<int> totalChapterCount,
      Value<int> status,
      Value<int> successCount,
      Value<int> errorCount,
      Value<int> addTime,
      Value<int> rowid,
    });

class $$DownloadTasksTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentChapterIndex => $composableBuilder(
    column: $table.currentChapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChapterCount => $composableBuilder(
    column: $table.totalChapterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get successCount => $composableBuilder(
    column: $table.successCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get errorCount => $composableBuilder(
    column: $table.errorCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookUrl => $composableBuilder(
    column: $table.bookUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentChapterIndex => $composableBuilder(
    column: $table.currentChapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChapterCount => $composableBuilder(
    column: $table.totalChapterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get successCount => $composableBuilder(
    column: $table.successCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get errorCount => $composableBuilder(
    column: $table.errorCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookUrl =>
      $composableBuilder(column: $table.bookUrl, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get currentChapterIndex => $composableBuilder(
    column: $table.currentChapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChapterCount => $composableBuilder(
    column: $table.totalChapterCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get successCount => $composableBuilder(
    column: $table.successCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get errorCount => $composableBuilder(
    column: $table.errorCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addTime =>
      $composableBuilder(column: $table.addTime, builder: (column) => column);
}

class $$DownloadTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadTasksTable,
          DownloadTaskRow,
          $$DownloadTasksTableFilterComposer,
          $$DownloadTasksTableOrderingComposer,
          $$DownloadTasksTableAnnotationComposer,
          $$DownloadTasksTableCreateCompanionBuilder,
          $$DownloadTasksTableUpdateCompanionBuilder,
          (
            DownloadTaskRow,
            BaseReferences<_$AppDatabase, $DownloadTasksTable, DownloadTaskRow>,
          ),
          DownloadTaskRow,
          PrefetchHooks Function()
        > {
  $$DownloadTasksTableTableManager(_$AppDatabase db, $DownloadTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DownloadTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$DownloadTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DownloadTasksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> bookUrl = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> currentChapterIndex = const Value.absent(),
                Value<int> totalChapterCount = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> successCount = const Value.absent(),
                Value<int> errorCount = const Value.absent(),
                Value<int> addTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadTasksCompanion(
                bookUrl: bookUrl,
                bookName: bookName,
                currentChapterIndex: currentChapterIndex,
                totalChapterCount: totalChapterCount,
                status: status,
                successCount: successCount,
                errorCount: errorCount,
                addTime: addTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookUrl,
                required String bookName,
                Value<int> currentChapterIndex = const Value.absent(),
                Value<int> totalChapterCount = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> successCount = const Value.absent(),
                Value<int> errorCount = const Value.absent(),
                Value<int> addTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadTasksCompanion.insert(
                bookUrl: bookUrl,
                bookName: bookName,
                currentChapterIndex: currentChapterIndex,
                totalChapterCount: totalChapterCount,
                status: status,
                successCount: successCount,
                errorCount: errorCount,
                addTime: addTime,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadTasksTable,
      DownloadTaskRow,
      $$DownloadTasksTableFilterComposer,
      $$DownloadTasksTableOrderingComposer,
      $$DownloadTasksTableAnnotationComposer,
      $$DownloadTasksTableCreateCompanionBuilder,
      $$DownloadTasksTableUpdateCompanionBuilder,
      (
        DownloadTaskRow,
        BaseReferences<_$AppDatabase, $DownloadTasksTable, DownloadTaskRow>,
      ),
      DownloadTaskRow,
      PrefetchHooks Function()
    >;
typedef $$SearchKeywordsTableCreateCompanionBuilder =
    SearchKeywordsCompanion Function({
      required String word,
      Value<int> usage,
      Value<int> lastUseTime,
      Value<int> rowid,
    });
typedef $$SearchKeywordsTableUpdateCompanionBuilder =
    SearchKeywordsCompanion Function({
      Value<String> word,
      Value<int> usage,
      Value<int> lastUseTime,
      Value<int> rowid,
    });

class $$SearchKeywordsTableFilterComposer
    extends Composer<_$AppDatabase, $SearchKeywordsTable> {
  $$SearchKeywordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUseTime => $composableBuilder(
    column: $table.lastUseTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchKeywordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchKeywordsTable> {
  $$SearchKeywordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUseTime => $composableBuilder(
    column: $table.lastUseTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchKeywordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchKeywordsTable> {
  $$SearchKeywordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<int> get usage =>
      $composableBuilder(column: $table.usage, builder: (column) => column);

  GeneratedColumn<int> get lastUseTime => $composableBuilder(
    column: $table.lastUseTime,
    builder: (column) => column,
  );
}

class $$SearchKeywordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchKeywordsTable,
          SearchKeywordRow,
          $$SearchKeywordsTableFilterComposer,
          $$SearchKeywordsTableOrderingComposer,
          $$SearchKeywordsTableAnnotationComposer,
          $$SearchKeywordsTableCreateCompanionBuilder,
          $$SearchKeywordsTableUpdateCompanionBuilder,
          (
            SearchKeywordRow,
            BaseReferences<
              _$AppDatabase,
              $SearchKeywordsTable,
              SearchKeywordRow
            >,
          ),
          SearchKeywordRow,
          PrefetchHooks Function()
        > {
  $$SearchKeywordsTableTableManager(
    _$AppDatabase db,
    $SearchKeywordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SearchKeywordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$SearchKeywordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SearchKeywordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<int> usage = const Value.absent(),
                Value<int> lastUseTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchKeywordsCompanion(
                word: word,
                usage: usage,
                lastUseTime: lastUseTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                Value<int> usage = const Value.absent(),
                Value<int> lastUseTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchKeywordsCompanion.insert(
                word: word,
                usage: usage,
                lastUseTime: lastUseTime,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchKeywordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchKeywordsTable,
      SearchKeywordRow,
      $$SearchKeywordsTableFilterComposer,
      $$SearchKeywordsTableOrderingComposer,
      $$SearchKeywordsTableAnnotationComposer,
      $$SearchKeywordsTableCreateCompanionBuilder,
      $$SearchKeywordsTableUpdateCompanionBuilder,
      (
        SearchKeywordRow,
        BaseReferences<_$AppDatabase, $SearchKeywordsTable, SearchKeywordRow>,
      ),
      SearchKeywordRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$BookSourcesTableTableManager get bookSources =>
      $$BookSourcesTableTableManager(_db, _db.bookSources);
  $$BookGroupsTableTableManager get bookGroups =>
      $$BookGroupsTableTableManager(_db, _db.bookGroups);
  $$SearchHistoryTableTableManager get searchHistory =>
      $$SearchHistoryTableTableManager(_db, _db.searchHistory);
  $$ReplaceRulesTableTableManager get replaceRules =>
      $$ReplaceRulesTableTableManager(_db, _db.replaceRules);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$CookiesTableTableManager get cookies =>
      $$CookiesTableTableManager(_db, _db.cookies);
  $$DictRulesTableTableManager get dictRules =>
      $$DictRulesTableTableManager(_db, _db.dictRules);
  $$HttpTtsTableTableManager get httpTts =>
      $$HttpTtsTableTableManager(_db, _db.httpTts);
  $$ReadRecordsTableTableManager get readRecords =>
      $$ReadRecordsTableTableManager(_db, _db.readRecords);
  $$RssArticlesTableTableManager get rssArticles =>
      $$RssArticlesTableTableManager(_db, _db.rssArticles);
  $$RssSourcesTableTableManager get rssSources =>
      $$RssSourcesTableTableManager(_db, _db.rssSources);
  $$RssStarsTableTableManager get rssStars =>
      $$RssStarsTableTableManager(_db, _db.rssStars);
  $$ServersTableTableManager get servers =>
      $$ServersTableTableManager(_db, _db.servers);
  $$TxtTocRulesTableTableManager get txtTocRules =>
      $$TxtTocRulesTableTableManager(_db, _db.txtTocRules);
  $$CacheTableTableManager get cache =>
      $$CacheTableTableManager(_db, _db.cache);
  $$KeyboardAssistsTableTableManager get keyboardAssists =>
      $$KeyboardAssistsTableTableManager(_db, _db.keyboardAssists);
  $$RssReadRecordsTableTableManager get rssReadRecords =>
      $$RssReadRecordsTableTableManager(_db, _db.rssReadRecords);
  $$RuleSubsTableTableManager get ruleSubs =>
      $$RuleSubsTableTableManager(_db, _db.ruleSubs);
  $$SourceSubscriptionsTableTableManager get sourceSubscriptions =>
      $$SourceSubscriptionsTableTableManager(_db, _db.sourceSubscriptions);
  $$SearchBooksTableTableManager get searchBooks =>
      $$SearchBooksTableTableManager(_db, _db.searchBooks);
  $$DownloadTasksTableTableManager get downloadTasks =>
      $$DownloadTasksTableTableManager(_db, _db.downloadTasks);
  $$SearchKeywordsTableTableManager get searchKeywords =>
      $$SearchKeywordsTableTableManager(_db, _db.searchKeywords);
}
