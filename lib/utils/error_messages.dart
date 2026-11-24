import '../services/api_service.dart';

/// Converts technical exceptions into plain, actionable Brazilian Portuguese messages.
String friendlyErrorMessage(
  Object error, {
  String fallback = 'Não foi possível concluir a solicitação. Tente novamente.',
}) {
  if (error is ApiException) {
    final msg = error.message.trim();
    if (msg.isNotEmpty &&
        !msg.startsWith('Exception:') &&
        !msg.contains('SocketException') &&
        !msg.contains('ClientException')) {
      return msg;
    }
  }

  final raw = error.toString();
  if (raw.contains('SocketException') ||
      raw.contains('ClientException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Connection refused') ||
      raw.contains('Network is unreachable')) {
    return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
  }
  if (raw.contains('TimeoutException')) {
    return 'A conexão demorou mais do que o esperado. Tente novamente em instantes.';
  }
  if (error is FormatException) {
    return 'Recebemos uma resposta inesperada do servidor. Tente novamente.';
  }
  return fallback;
}
