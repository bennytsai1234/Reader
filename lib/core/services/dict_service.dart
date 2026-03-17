import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';
import 'package:legado_reader/core/models/dict_rule.dart';
import 'package:legado_reader/core/database/dao/dict_rule_dao.dart';

class DictService {
  final DictRuleDao _dao = getIt<DictRuleDao>();

  Future<List<DictRule>> getEnabledRules() async {
    final all = await _dao.getAll();
    return all.where((r) => r.enabled).toList();
  }

  Future<List<DictRule>> getAllRules() async {
    return await _dao.getAll();
  }

  Future<String> search(DictRule rule, String word) async {
    var url = rule.urlRule;
    if (url.contains('{{key}}')) {
      url = url.replaceAll('{{key}}', word);
    } else {
      // 深度還原：如果沒有標籤，則嘗試附加到末尾 (某些簡易規則)
      if (url.contains('?')) {
        url += word;
      } else {
        url += '/$word';
      }
    }

    final analyzeUrl = AnalyzeUrl(url, key: word);
    final body = await analyzeUrl.getResponseBody();
    
    if (rule.showRule.isEmpty) {
      return body;
    }
    
    final analyzeRule = AnalyzeRule().setContent(body);
    return analyzeRule.getString(rule.showRule);
  }

  Future<void> saveRule(DictRule rule) async {
    await _dao.upsert(rule);
  }

  Future<void> deleteRule(String name) async {
    await _dao.deleteByName(name);
  }
}

