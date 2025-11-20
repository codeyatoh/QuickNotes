/// Utility function for unawaited futures
/// Prevents "unawaited future" warnings when intentionally not awaiting
void unawaited(Future<void> future) {
  // Ignore errors in background tasks
  future.catchError((_) {});
}

