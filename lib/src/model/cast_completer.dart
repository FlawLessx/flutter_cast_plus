import 'dart:async';

class CastCompleter {
  final int requestId;
  final Completer completer;

  CastCompleter(this.requestId, this.completer);
}
