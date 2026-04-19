import 'package:inkpage_reader/shared/widgets/source_option_tile.dart';

class ChangeSourceItem extends SourceOptionTile {
  const ChangeSourceItem({
    super.key,
    required super.searchBook,
    super.isCurrent = false,
    super.onTap,
  });
}
