import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/web_book/book_info_parser.dart';
import 'package:inkpage_reader/core/engine/web_book/book_list_parser.dart';
import 'package:inkpage_reader/core/engine/web_book/chapter_list_parser.dart';
import 'package:inkpage_reader/core/engine/web_book/content_parser.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import '../../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupTestDI();

  group('User Source Compatibility', () {
    test(
      'Legado-style BB source supports search to read flow with relative urls',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': 'BB成人小说',
          'bookSourceUrl': 'https://bbxxxx.com',
          'searchUrl': '/search/?q={{key}}&page={{page}}',
          'ruleSearch': {
            'bookList': 'class.novel-item',
            'name': 'class.info@tag.a@text',
            'bookUrl': 'class.info@tag.a@href',
            'author': 'class.meta@text',
            'coverUrl': 'tag.a@img@data-src',
            'intro': 'class.desc@text',
          },
          'ruleBookInfo': {
            'name': 'tag.h1@text',
            'author': 'tag.p.0@text',
            'coverUrl': 'class.cover@tag.img@src',
            'intro': 'class.desc@text',
            'kind': 'tag.p.2@text',
            'lastChapter': 'class.novel-list@a.-1@text',
          },
          'ruleToc': {
            'chapterList': 'class.novel-list@a',
            'chapterName': 'a@text',
            'chapterUrl': 'a@href',
          },
          'ruleContent': {'content': 'class.article@tag.p@html'},
        });

        const searchHtml = '''
        <html><body>
          <div class="novel-item">
            <a href="/novel/15786/"><img data-src="/data/cover/book.webp" /></a>
            <div class="info"><a href="/novel/15786/">我的情人，我的女婿</a></div>
            <div class="meta">湿身记</div>
            <div class="desc">我无论如何也想不到。</div>
          </div>
        </body></html>
        ''';

        final searchBooks = await BookListParser.parse(
          source: source,
          body: searchHtml,
          baseUrl: 'https://bbxxxx.com/search/?q=%E6%88%91%E7%9A%84&page=1',
          isSearch: true,
        );

        expect(searchBooks, hasLength(1));
        final selected = searchBooks.first;
        expect(selected.name, '我的情人，我的女婿');
        expect(selected.author, '湿身记');
        expect(selected.bookUrl, 'https://bbxxxx.com/novel/15786/');
        expect(selected.coverUrl, 'https://bbxxxx.com/data/cover/book.webp');

        const bookHtml = '''
        <html><body>
          <div class="cover"><img src="/data/cover/book.webp" /></div>
          <h1>我的情人，我的女婿</h1>
          <p>作者：湿身记</p>
          <p>状态：已完结</p>
          <p>分类：乱伦</p>
          <div class="desc">我无论如何也想不到。</div>
          <div class="novel-list">
            <a href="/novel/15786/1461060.html">第1章 林晓的第一次</a>
            <a href="/novel/15786/1461058.html">第2章 我的第一次</a>
          </div>
        </body></html>
        ''';

        final hydratedBook = await BookInfoParser.parse(
          source: source,
          book: selected.toBook(),
          body: bookHtml,
          baseUrl: selected.bookUrl,
        );

        expect(hydratedBook.name, '我的情人，我的女婿');
        expect(hydratedBook.author, '作者：湿身记');
        expect(
          hydratedBook.coverUrl,
          'https://bbxxxx.com/data/cover/book.webp',
        );
        expect(hydratedBook.tocUrl, 'https://bbxxxx.com/novel/15786/');
        expect(hydratedBook.latestChapterTitle, '第2章 我的第一次');

        final toc = await ChapterListParser.parse(
          source: source,
          book: hydratedBook,
          body: bookHtml,
          baseUrl: hydratedBook.tocUrl,
        );

        expect(toc.chapters, hasLength(2));
        expect(toc.chapters[0].title, '第1章 林晓的第一次');
        expect(
          toc.chapters[0].url,
          'https://bbxxxx.com/novel/15786/1461060.html',
        );
        expect(toc.chapters[1].title, '第2章 我的第一次');
        expect(
          toc.chapters[1].url,
          'https://bbxxxx.com/novel/15786/1461058.html',
        );

        const chapter1Html = '''
        <html><body>
          <section class="article">
            <p>我无论如何也想不到。</p>
            <p>这一切会这样开始。</p>
          </section>
        </body></html>
        ''';

        const chapter2Html = '''
        <html><body>
          <section class="article">
            <p>我看他很舒服，也感觉很自豪。</p>
            <p>我们的故事继续往前。</p>
          </section>
        </body></html>
        ''';

        final content1 = await ContentParser.parse(
          source: source,
          book: hydratedBook,
          chapter: toc.chapters[0],
          body: chapter1Html,
          baseUrl: toc.chapters[0].url,
        );
        final content2 = await ContentParser.parse(
          source: source,
          book: hydratedBook,
          chapter: toc.chapters[1],
          body: chapter2Html,
          baseUrl: toc.chapters[1].url,
        );

        expect(content1.content, contains('我无论如何也想不到'));
        expect(content2.content, contains('我看他很舒服，也感觉很自豪'));
        expect(content1.content, isNot(equals(content2.content)));
      },
    );

    test(
      'Legado-style :root search selectors parse Alice source results',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': '爱丽丝书屋',
          'bookSourceUrl': 'https://www.alicesw.com/',
          'searchUrl': '/search.html?q={{key}}&p={{page}}',
          'ruleSearch': {
            'bookList': '.list-group-item',
            'name': ':root@[0]@[0]@text##^\\d+\\.\\s*',
            'author': ':root@[1]@[0]@text',
            'bookUrl': ':root@[0]@[0]@href',
            'intro': '.content-txt@text',
          },
        });

        const searchHtml = '''
      <div class="list-group">
        <div class="list-group-item">
          <h5>
            <a href="/novel/40321.html" target="_blank">1. 萝莉保育</a>
            <small class="text-muted ms-2">[已完结]</small>
          </h5>
          <p class="mb-1 text-muted">
            作者：<a href="/search?q=%E7%9C%9F%E7%BA%A2%E4%B9%90%E7%AB%A0&f=author" target="_blank">真红乐章</a>
            字数：1.01万
          </p>
          <p class="content-txt">萝莉的保育工作已经刻不容缓。</p>
        </div>
      </div>
      ''';

        final results = await BookListParser.parse(
          source: source,
          body: searchHtml,
          baseUrl:
              'https://www.alicesw.com/search.html?q=%E8%90%9D%E8%8E%89&p=1',
          isSearch: true,
        );

        expect(results, hasLength(1));
        expect(results.first.name, '萝莉保育');
        expect(results.first.author, '真红乐章');
        expect(
          results.first.bookUrl,
          'https://www.alicesw.com/novel/40321.html',
        );
        expect(results.first.intro, '萝莉的保育工作已经刻不容缓。');
      },
    );

    test(
      'Legado-style regex extraction reads element outerHtml for Suixkan bookUrl',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': '随心看吧',
          'bookSourceUrl': 'https://m.suixkan.com#♤guaner',
          'searchUrl': 'https://m.suixkan.com/s/1.html?keyword={{key}}',
          'ruleSearch': {
            'bookList': '.v-list-item',
            'name': '.v-title@text',
            'author': '.v-author@text',
            'bookUrl': "##=\\\"newWebView\\('([^']+)'##\$1###",
          },
        });

        const searchHtml = '''
      <div class="v-list-item flex" onclick="newWebView('/b/27094.html', '', '')">
        <div class="v-title">神道帝尊</div>
        <div class="v-author">蜗牛狂奔</div>
      </div>
      ''';

        final results = await BookListParser.parse(
          source: source,
          body: searchHtml,
          baseUrl:
              'https://m.suixkan.com/s/1.html?keyword=%E7%A5%9E%E9%81%93%E5%B8%9D%E5%B0%8A',
          isSearch: true,
        );

        expect(results, hasLength(1));
        expect(results.first.name, '神道帝尊');
        expect(results.first.author, '蜗牛狂奔');
        expect(results.first.bookUrl, 'https://m.suixkan.com/b/27094.html');
      },
    );

    test(
      'Legado-style XPath search rules parse Bcshuku live-like results',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': '八叉书库',
          'bookSourceUrl': 'https://bcshuku.com/',
          'ruleSearch': {
            'bookList':
                '//div[@class="one-row"]/div[@class="col-md-3 col-sm-6 col-xs-6 home-truyendecu"]',
            'bookUrl': '//div[@class="each_truyen"]/a/@href',
            'coverUrl': '//div[@class="each_truyen"]/a/img/@src',
            'name': '//h3[@itemprop="name"]/text()',
          },
        });

        const searchHtml = '''
      <!DOCTYPE html>
      <html lang="en-US">
        <body>
          <div class="container" id="truyen-slide">
            <div class="main-home">
              <div class="col-xs-12 col-sm-12 col-md-9 col-truyen-main">
                <div class="row">
                  <div class="list list-thumbnail col-xs-12">
                    <div class="row">
                      <div class="one-row">
                        <div class="col-md-3 col-sm-6 col-xs-6 home-truyendecu" itemscope="" itemtype="http://schema.org/Book">
                          <div class="each_truyen">
                            <a href="/novel62406/" title="双燕归林">
                              <img src="https://img.8xsk.top/files/titlepic/bookimgalc50679.webp" alt="双燕归林"" itemprop="image" />
                            </a>
                          </div>
                          <div class="caption">
                            <a href="/novel62406/" title="T双燕归林" itemprop="url">
                              <h3 itemprop="name">双燕归林</h3>
                            </a>
                          </div>
                        </div>
                        <div class="col-md-3 col-sm-6 col-xs-6 home-truyendecu" itemscope="" itemtype="http://schema.org/Book">
                          <div class="each_truyen">
                            <a href="/novel2709/" title="黑骑双燕">
                              <img src="https://img.8xsk.top/files/novel/bookimg4003s.jpg" alt="黑骑双燕"" itemprop="image" />
                            </a>
                          </div>
                          <div class="caption">
                            <a href="/novel2709/" title="T黑骑双燕" itemprop="url">
                              <h3 itemprop="name">黑骑双燕</h3>
                            </a>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </body>
      </html>
      ''';

        final results = await BookListParser.parse(
          source: source,
          body: searchHtml,
          baseUrl:
              'https://bcshuku.com/e/search/result/?searchid=187204&page=1',
          isSearch: true,
        );

        expect(results, hasLength(2));
        expect(results.first.name, '双燕归林');
        expect(results.first.bookUrl, 'https://bcshuku.com/novel62406/');
        expect(
          results.first.coverUrl,
          'https://img.8xsk.top/files/titlepic/bookimgalc50679.webp',
        );
        expect(results[1].name, '黑骑双燕');
        expect(results[1].bookUrl, 'https://bcshuku.com/novel2709/');
      },
    );

    test(
      'Legado-style Alice tocUrl and toc list parse from detail pages',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': '爱丽丝书屋',
          'bookSourceUrl': 'https://www.alicesw.com/',
          'ruleBookInfo': {'tocUrl': '.book_newchap > .tabtitle@.0@href'},
          'ruleToc': {
            'chapterList': '.mulu_list a',
            'chapterName': ':root@text',
            'chapterUrl': ':root@href',
            'isVolume': 'false',
            'isVip': 'false',
            'isPay': 'false',
          },
        });

        const detailHtml = '''
      <div class="book_newchap">
        <div class="tit tabtitle">
          最新章节：全1章
          <a href="/other/chapters/id/40321.html">查看所有章节</a>
        </div>
      </div>
      ''';

        final hydratedBook = await BookInfoParser.parse(
          source: source,
          book: Book(
            bookUrl: 'https://www.alicesw.com/novel/40321.html',
            origin: 'https://www.alicesw.com/',
            name: '萝莉保育',
          ),
          body: detailHtml,
          baseUrl: 'https://www.alicesw.com/novel/40321.html',
        );

        expect(
          hydratedBook.tocUrl,
          'https://www.alicesw.com/other/chapters/id/40321.html',
        );

        const tocHtml = '''
      <ul class="mulu_list">
        <li><a href="/book/41828/85a73a6d71bd9.html" target="_blank">全1章</a></li>
      </ul>
      ''';

        final toc = await ChapterListParser.parse(
          source: source,
          book: hydratedBook,
          body: tocHtml,
          baseUrl: hydratedBook.tocUrl,
        );

        expect(toc.chapters, hasLength(1));
        expect(toc.chapters.first.title, '全1章');
        expect(
          toc.chapters.first.url,
          'https://www.alicesw.com/book/41828/85a73a6d71bd9.html',
        );
        expect(toc.chapters.first.isVolume, isFalse);
      },
    );

    test('Legado-style bare JSON item fields parse Kujiang search results', () async {
      final source = BookSource.fromJson({
        'bookSourceName': '酷匠阅读',
        'bookSourceUrl': 'https://app.kujiang.com',
        'ruleSearch': {
          'bookList': r'$.body.list',
          'name': 'v_book',
          'author': 'penname',
          'bookUrl':
              r'https://app.kujiang.com/v1/book/get_book_infos?from=search&subsite=m&book={{$.book}}',
          'lastChapter': 'v_u_chapter',
          'wordCount': 'public_size',
        },
      });

      const searchJson = '''
      {
        "body": {
          "list": [
            {
              "book": "66226",
              "v_book": "天龙殿",
              "penname": "疯狂小牛",
              "v_u_chapter": "第1651章 龙浩恪守之道（终）",
              "public_size": "3570395"
            }
          ]
        }
      }
      ''';

      final results = await BookListParser.parse(
        source: source,
        body: searchJson,
        baseUrl:
            'https://app.kujiang.com/v1/book/search202107?keyword=%E9%BE%99%E7%8E%8B%E6%AE%BF',
        isSearch: true,
      );

      expect(results, hasLength(1));
      expect(results.first.name, '天龙殿');
      expect(results.first.author, '疯狂小牛');
      expect(
        results.first.bookUrl,
        'https://app.kujiang.com/v1/book/get_book_infos?from=search&subsite=m&book=66226',
      );
      expect(results.first.latestChapterTitle, '第1651章 龙浩恪守之道（终）');
      expect(results.first.wordCount, isNotEmpty);
    });

    test(
      'Legado-style bare JSON list rules parse from raw JSON strings',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': '七猫小说',
          'bookSourceUrl': 'https://api-bc.wtzw.com',
          'ruleSearch': {
            'bookList': 'data.books',
            'name': 'original_title',
            'author': 'original_author',
            'bookUrl': r'https://api.example.com/book/{{$.id}}',
          },
        });

        const searchJson = '''
      {
        "data": {
          "books": [
            {
              "id": "1885648",
              "original_title": "我的吊带裙",
              "original_author": "作者A"
            }
          ]
        }
      }
      ''';

        final results = await BookListParser.parse(
          source: source,
          body: searchJson,
          baseUrl: 'https://api-bc.wtzw.com/api/v5/search/words',
          isSearch: true,
        );

        expect(results, hasLength(1));
        expect(results.first.name, '我的吊带裙');
        expect(results.first.author, '作者A');
        expect(results.first.bookUrl, 'https://api.example.com/book/1885648');
      },
    );

    test(
      'Search parsing keeps valid items when optional metadata rules are unusable',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': 'Optional metadata failure source',
          'bookSourceUrl': 'https://example.com',
          'ruleSearch': {
            'bookList': '.item',
            'name': '.title@text',
            'bookUrl': '.title@href',
            'kind': '@js:throw new Error("boom")',
            'intro': '@js:throw new Error("boom")',
          },
        });

        const searchHtml = '''
      <div class="item">
        <a class="title" href="/book/42">可保留的書</a>
      </div>
      ''';

        final results = await BookListParser.parse(
          source: source,
          body: searchHtml,
          baseUrl: 'https://example.com/search?q=test',
          isSearch: true,
        );

        expect(results, hasLength(1));
        expect(results.first.name, '可保留的書');
        expect(results.first.bookUrl, 'https://example.com/book/42');
      },
    );

    test(
      'Legado-style Suixkan content keeps multi-section chapter text',
      () async {
        final source = BookSource.fromJson({
          'bookSourceName': '随心看吧',
          'bookSourceUrl': 'https://m.suixkan.com#♤guaner',
          'ruleContent': {
            'content': 'class.con@html',
            'replaceRegex': '##\\s*.*?本章.*?完.*\\s*',
          },
        });

        const chapterHtml = '''
      <div class="section">
        <div class="con">
          <p>第一段内容。</p>
          <p>（本章未完，请翻页）</p>
        </div>
      </div>
      <div class="section none">
        <div class="con">
          <p>第二段内容。</p>
          <p>（本章未完，请翻页）</p>
        </div>
      </div>
      <div class="section none">
        <div class="con">
          <p>第三段内容。</p>
          <p>（本章完）</p>
        </div>
      </div>
      ''';

        final parsed = await ContentParser.parse(
          source: source,
          book: Book(
            bookUrl: 'https://m.suixkan.com/b/28654.html',
            origin: 'https://m.suixkan.com#♤guaner',
            name: '此生不负你情深',
          ),
          chapter: BookChapter(
            title: '第1章',
            url: 'https://m.suixkan.com/r/28654/33046.html',
            bookUrl: 'https://m.suixkan.com/b/28654.html',
          ),
          body: chapterHtml,
          baseUrl: 'https://m.suixkan.com/r/28654/33046.html',
        );

        final finalized = await ContentParser.finalizeContent(
          source: source,
          book: Book(
            bookUrl: 'https://m.suixkan.com/b/28654.html',
            origin: 'https://m.suixkan.com#♤guaner',
            name: '此生不负你情深',
          ),
          chapter: BookChapter(
            title: '第1章',
            url: 'https://m.suixkan.com/r/28654/33046.html',
            bookUrl: 'https://m.suixkan.com/b/28654.html',
          ),
          contentStr: parsed.content,
          baseUrl: 'https://m.suixkan.com/r/28654/33046.html',
        );

        expect(finalized, contains('第一段内容'));
        expect(finalized, contains('第二段内容'));
        expect(finalized, contains('第三段内容'));
        expect(finalized, isNot(contains('本章未完')));
        expect(finalized, isNot(contains('本章完')));
      },
    );
  });
}
