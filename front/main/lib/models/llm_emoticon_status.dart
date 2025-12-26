/// LLM 이모티콘 생성 상태
enum EmoticonStatus {
  /// 요청됨 - 대기 중
  requested,

  /// 처리 중 - LLM이 이미지 생성 중
  processing,

  /// 성공 - 이모티콘 생성 완료
  succeeded,

  /// 실패 - 생성 실패
  failed;

  /// API 문자열을 Enum으로 변환
  static EmoticonStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return EmoticonStatus.requested;
      case 'PROCESSING':
        return EmoticonStatus.processing;
      case 'SUCCEEDED':
        return EmoticonStatus.succeeded;
      case 'FAILED':
        return EmoticonStatus.failed;
      default:
        return EmoticonStatus.requested;
    }
  }

  /// Enum을 API 문자열로 변환
  String toApiString() {
    return name.toUpperCase();
  }

  /// 한글 표시 이름
  String get displayName {
    switch (this) {
      case EmoticonStatus.requested:
        return '대기 중';
      case EmoticonStatus.processing:
        return '생성 중';
      case EmoticonStatus.succeeded:
        return '완료';
      case EmoticonStatus.failed:
        return '실패';
    }
  }
}
