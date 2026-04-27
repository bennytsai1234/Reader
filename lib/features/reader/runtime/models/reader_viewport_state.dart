class ReaderViewportState {
  final bool showLoading;
  final String? message;

  const ReaderViewportState._({required this.showLoading, this.message});

  static const ready = ReaderViewportState._(showLoading: false);

  const ReaderViewportState.loading({String message = '正在載入內容'})
    : this._(showLoading: true, message: message);

  const ReaderViewportState.message(String message)
    : this._(showLoading: false, message: message);
}
