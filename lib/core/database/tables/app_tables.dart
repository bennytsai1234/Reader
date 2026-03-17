import 'package:drift/drift.dart';

// ───────────── Books ─────────────
@DataClassName('BookRow')
class Books extends Table {
  TextColumn get bookUrl => text().named('bookUrl')();
  TextColumn get tocUrl => text().named('tocUrl').nullable()();
  TextColumn get origin => text().nullable()();
  TextColumn get originName => text().named('originName').nullable()();
  TextColumn get name => text()();
  TextColumn get author => text().nullable()();
  TextColumn get kind => text().nullable()();
  TextColumn get customTag => text().named('customTag').nullable()();
  TextColumn get coverUrl => text().named('coverUrl').nullable()();
  TextColumn get customCoverUrl => text().named('customCoverUrl').nullable()();
  TextColumn get intro => text().nullable()();
  TextColumn get customIntro => text().named('customIntro').nullable()();
  TextColumn get charset => text().nullable()();
  IntColumn get type => integer().named('type').withDefault(const Constant(0))();
  IntColumn get group => integer().named('group').withDefault(const Constant(0))();
  TextColumn get latestChapterTitle => text().named('latestChapterTitle').nullable()();
  IntColumn get latestChapterTime => integer().named('latestChapterTime').withDefault(const Constant(0))();
  IntColumn get lastCheckTime => integer().named('lastCheckTime').withDefault(const Constant(0))();
  IntColumn get lastCheckCount => integer().named('lastCheckCount').withDefault(const Constant(0))();
  IntColumn get totalChapterNum => integer().named('totalChapterNum').withDefault(const Constant(0))();
  TextColumn get durChapterTitle => text().named('durChapterTitle').nullable()();
  IntColumn get durChapterIndex => integer().named('durChapterIndex').withDefault(const Constant(0))();
  IntColumn get durChapterPos => integer().named('durChapterPos').withDefault(const Constant(0))();
  IntColumn get durChapterTime => integer().named('durChapterTime').withDefault(const Constant(0))();
  TextColumn get wordCount => text().named('wordCount').nullable()();
  IntColumn get canUpdate => integer().named('canUpdate').withDefault(const Constant(1))();
  IntColumn get order => integer().named('order').withDefault(const Constant(0))();
  IntColumn get originOrder => integer().named('originOrder').withDefault(const Constant(0))();
  TextColumn get variable => text().nullable()();
  TextColumn get readConfig => text().named('readConfig').nullable()();
  IntColumn get syncTime => integer().named('syncTime').withDefault(const Constant(0))();
  IntColumn get isInBookshelf => integer().named('isInBookshelf').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {bookUrl};
}

// ───────────── Chapters ─────────────
@DataClassName('ChapterRow')
class Chapters extends Table {
  TextColumn get url => text()();
  TextColumn get title => text()();
  IntColumn get isVolume => integer().named('isVolume').withDefault(const Constant(0))();
  TextColumn get baseUrl => text().named('baseUrl').nullable()();
  TextColumn get bookUrl => text().named('bookUrl')();
  IntColumn get index => integer().named('index')();
  IntColumn get isVip => integer().named('isVip').withDefault(const Constant(0))();
  IntColumn get isPay => integer().named('isPay').withDefault(const Constant(0))();
  TextColumn get resourceUrl => text().named('resourceUrl').nullable()();
  TextColumn get tag => text().nullable()();
  TextColumn get wordCount => text().named('wordCount').nullable()();
  IntColumn get start => integer().nullable()();
  IntColumn get end => integer().named('end').nullable()();
  TextColumn get startFragmentId => text().named('startFragmentId').nullable()();
  TextColumn get endFragmentId => text().named('endFragmentId').nullable()();
  TextColumn get variable => text().nullable()();
  TextColumn get content => text().nullable()();

  @override
  Set<Column> get primaryKey => {url};
}

// ───────────── BookSources ─────────────
@DataClassName('BookSourceRow')
class BookSources extends Table {
  TextColumn get bookSourceUrl => text().named('bookSourceUrl')();
  TextColumn get bookSourceName => text().named('bookSourceName')();
  IntColumn get bookSourceType => integer().named('bookSourceType').withDefault(const Constant(0))();
  TextColumn get bookSourceGroup => text().named('bookSourceGroup').nullable()();
  TextColumn get bookSourceComment => text().named('bookSourceComment').nullable()();
  TextColumn get loginUrl => text().named('loginUrl').nullable()();
  TextColumn get loginUi => text().named('loginUi').nullable()();
  TextColumn get loginCheckJs => text().named('loginCheckJs').nullable()();
  TextColumn get coverDecodeJs => text().named('coverDecodeJs').nullable()();
  TextColumn get bookUrlPattern => text().named('bookUrlPattern').nullable()();
  TextColumn get header => text().nullable()();
  TextColumn get variableComment => text().named('variableComment').nullable()();
  IntColumn get customOrder => integer().named('customOrder').withDefault(const Constant(0))();
  IntColumn get weight => integer().withDefault(const Constant(0))();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
  IntColumn get enabledExplore => integer().named('enabledExplore').withDefault(const Constant(1))();
  IntColumn get enabledCookieJar => integer().named('enabledCookieJar').withDefault(const Constant(1))();
  IntColumn get lastUpdateTime => integer().named('lastUpdateTime').withDefault(const Constant(0))();
  IntColumn get respondTime => integer().named('respondTime').withDefault(const Constant(180000))();
  TextColumn get jsLib => text().named('jsLib').nullable()();
  TextColumn get concurrentRate => text().named('concurrentRate').nullable()();
  TextColumn get exploreUrl => text().named('exploreUrl').nullable()();
  TextColumn get exploreScreen => text().named('exploreScreen').nullable()();
  TextColumn get searchUrl => text().named('searchUrl').nullable()();
  TextColumn get ruleSearch => text().named('ruleSearch').nullable()();
  TextColumn get ruleExplore => text().named('ruleExplore').nullable()();
  TextColumn get ruleBookInfo => text().named('ruleBookInfo').nullable()();
  TextColumn get ruleToc => text().named('ruleToc').nullable()();
  TextColumn get ruleContent => text().named('ruleContent').nullable()();
  TextColumn get ruleReview => text().named('ruleReview').nullable()();

  @override
  Set<Column> get primaryKey => {bookSourceUrl};
}

// ───────────── BookGroups ─────────────
@DataClassName('BookGroupRow')
class BookGroups extends Table {
  IntColumn get groupId => integer().named('groupId')();
  TextColumn get groupName => text().named('groupName')();
  IntColumn get order => integer().named('order').withDefault(const Constant(0))();
  IntColumn get show => integer().withDefault(const Constant(1))();
  TextColumn get coverPath => text().named('coverPath').nullable()();
  IntColumn get enableRefresh => integer().named('enableRefresh').withDefault(const Constant(1))();
  IntColumn get bookSort => integer().named('bookSort').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {groupId};
}

// ───────────── SearchHistory ─────────────
@DataClassName('SearchHistoryRow')
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text()();
  IntColumn get searchTime => integer().named('searchTime')();
}

// ───────────── ReplaceRules ─────────────
@DataClassName('ReplaceRuleRow')
class ReplaceRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get pattern => text()();
  TextColumn get replacement => text().nullable()();
  TextColumn get scope => text().nullable()();
  IntColumn get scopeTitle => integer().named('scopeTitle').withDefault(const Constant(0))();
  IntColumn get scopeContent => integer().named('scopeContent').withDefault(const Constant(1))();
  TextColumn get excludeScope => text().named('excludeScope').nullable()();
  IntColumn get isEnabled => integer().named('isEnabled').withDefault(const Constant(1))();
  IntColumn get isRegex => integer().named('isRegex').withDefault(const Constant(1))();
  IntColumn get timeoutMillisecond => integer().named('timeoutMillisecond').withDefault(const Constant(3000))();
  TextColumn get group => text().named('group').nullable()();
  IntColumn get order => integer().named('order').withDefault(const Constant(0))();
}

// ───────────── Bookmarks ─────────────
@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get time => integer()();
  TextColumn get bookName => text().named('bookName')();
  TextColumn get bookAuthor => text().named('bookAuthor').nullable()();
  IntColumn get chapterIndex => integer().named('chapterIndex').withDefault(const Constant(0))();
  IntColumn get chapterPos => integer().named('chapterPos').withDefault(const Constant(0))();
  TextColumn get chapterName => text().named('chapterName').nullable()();
  TextColumn get bookUrl => text().named('bookUrl')();
  TextColumn get bookText => text().named('bookText').nullable()();
  TextColumn get content => text().nullable()();
}

// ───────────── Cookies ─────────────
@DataClassName('CookieRow')
class Cookies extends Table {
  TextColumn get url => text()();
  TextColumn get cookie => text()();

  @override
  Set<Column> get primaryKey => {url};
}

// ───────────── DictRules ─────────────
@DataClassName('DictRuleRow')
class DictRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get urlRule => text().named('urlRule').nullable()();
  TextColumn get showRule => text().named('showRule').nullable()();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
  IntColumn get sortNumber => integer().named('sortNumber').withDefault(const Constant(0))();
}

// ───────────── HttpTts ─────────────
@DataClassName('HttpTtsRow')
class HttpTts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  TextColumn get contentType => text().named('contentType').nullable()();
  TextColumn get concurrentRate => text().named('concurrentRate').nullable()();
  TextColumn get loginUrl => text().named('loginUrl').nullable()();
  TextColumn get loginUi => text().named('loginUi').nullable()();
  TextColumn get header => text().nullable()();
  TextColumn get jsLib => text().named('jsLib').nullable()();
  IntColumn get enabledCookieJar => integer().named('enabledCookieJar').withDefault(const Constant(0))();
  TextColumn get loginCheckJs => text().named('loginCheckJs').nullable()();
  IntColumn get lastUpdateTime => integer().named('lastUpdateTime').withDefault(const Constant(0))();
}

// ───────────── ReadRecords ─────────────
@DataClassName('ReadRecordRow')
class ReadRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookName => text().named('bookName')();
  TextColumn get deviceId => text().named('deviceId')();
  IntColumn get readTime => integer().named('readTime').withDefault(const Constant(0))();
  IntColumn get lastRead => integer().named('lastRead').withDefault(const Constant(0))();
}

// ───────────── Servers ─────────────
@DataClassName('ServerRow')
class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get config => text().nullable()();
  IntColumn get sortNumber => integer().named('sortNumber').withDefault(const Constant(0))();
}

// ───────────── TxtTocRules ─────────────
@DataClassName('TxtTocRuleRow')
class TxtTocRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get rule => text()();
  TextColumn get example => text().nullable()();
  IntColumn get serialNumber => integer().named('serialNumber').withDefault(const Constant(-1))();
  IntColumn get enable => integer().withDefault(const Constant(1))();
}

// ───────────── Cache ─────────────
@DataClassName('CacheRow')
class Cache extends Table {
  TextColumn get key => text().named('key')();
  TextColumn get value => text().named('value').nullable()();
  IntColumn get deadline => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}

// ───────────── KeyboardAssists ─────────────
@DataClassName('KeyboardAssistRow')
class KeyboardAssists extends Table {
  TextColumn get key => text().named('key')();
  IntColumn get type => integer().withDefault(const Constant(0))();
  TextColumn get value => text().named('value').nullable()();
  IntColumn get serialNo => integer().named('serialNo').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}

// ───────────── RuleSubs ─────────────
@DataClassName('RuleSubRow')
class RuleSubs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
  IntColumn get order => integer().named('order').withDefault(const Constant(0))();
}

// ───────────── SourceSubscriptions ─────────────
@DataClassName('SourceSubscriptionRow')
class SourceSubscriptions extends Table {
  TextColumn get url => text()();
  TextColumn get name => text()();
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
  IntColumn get order => integer().named('order').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {url};
}

// ───────────── SearchBooks ─────────────
@DataClassName('SearchBookRow')
class SearchBooks extends Table {
  TextColumn get bookUrl => text().named('bookUrl')();
  TextColumn get name => text()();
  TextColumn get author => text().nullable()();
  TextColumn get kind => text().nullable()();
  TextColumn get coverUrl => text().named('coverUrl').nullable()();
  TextColumn get intro => text().nullable()();
  TextColumn get wordCount => text().named('wordCount').nullable()();
  TextColumn get latestChapterTitle => text().named('latestChapterTitle').nullable()();
  TextColumn get origin => text().nullable()();
  TextColumn get originName => text().named('originName').nullable()();
  IntColumn get originOrder => integer().named('originOrder').withDefault(const Constant(0))();
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get addTime => integer().named('addTime').withDefault(const Constant(0))();
  TextColumn get variable => text().nullable()();
  TextColumn get tocUrl => text().named('tocUrl').nullable()();

  @override
  Set<Column> get primaryKey => {bookUrl};
}

// ───────────── DownloadTasks ─────────────
@DataClassName('DownloadTaskRow')
class DownloadTasks extends Table {
  TextColumn get bookUrl => text().named('bookUrl')();
  TextColumn get bookName => text().named('bookName')();
  IntColumn get currentChapterIndex => integer().named('currentChapterIndex').withDefault(const Constant(0))();
  IntColumn get totalChapterCount => integer().named('totalChapterCount').withDefault(const Constant(0))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get successCount => integer().named('successCount').withDefault(const Constant(0))();
  IntColumn get errorCount => integer().named('errorCount').withDefault(const Constant(0))();
  IntColumn get addTime => integer().named('addTime').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {bookUrl};
}

// ───────────── SearchKeywords ─────────────
@DataClassName('SearchKeywordRow')
class SearchKeywords extends Table {
  TextColumn get word => text()();
  IntColumn get usage => integer().withDefault(const Constant(0))();
  IntColumn get lastUseTime => integer().named('lastUseTime').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {word};
}
