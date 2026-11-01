import '../router/routes.dart';

/// Maps an OS-level URI onto a go_router location.
abstract final class IncomingLink {
  static String? locationOf(Uri uri) {
    final kind = _kind(uri);
    if (kind == null) return null;
    final token = uri.queryParameters['token'] ?? _tokenFromPath(uri);
    final encoded = token == null || token.isEmpty
        ? ''
        : '?token=${Uri.encodeQueryComponent(token)}';
    return switch (kind) {
      _LinkKind.invitation => '${Routes.invitation}$encoded',
      _LinkKind.task => '${Routes.taskResult}$encoded',
    };
  }

  static _LinkKind? _kind(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    if (uri.scheme == 'diealog') {
      if (host == 'invitation' || path.contains('invitation')) {
        return _LinkKind.invitation;
      }
      if (host == 'task' || path.contains('task')) return _LinkKind.task;
    }
    if (path.contains('/invitation')) return _LinkKind.invitation;
    if (path.contains('/task-result') || path.contains('/task')) {
      return _LinkKind.task;
    }
    return null;
  }

  static String? _tokenFromPath(Uri uri) {
    final parts = uri.path.split('/')..removeWhere((part) => part.isEmpty);
    if (parts.length >= 2 &&
        (parts.first == 'invitation' || parts.first == 'task')) {
      return parts[1];
    }
    return null;
  }
}

enum _LinkKind { invitation, task }
