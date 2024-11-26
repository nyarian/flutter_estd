extension ReceiverExtension<R extends Object> on R {
  T let<T>(T Function(R) handler) => handler(this);
}
