/// Performance telemetry service for opt-in anonymous metrics.
///
/// Collects coarse performance data (no PII) to help identify
/// performance regressions in production. All events are opt-in
/// and use bucketed values to preserve privacy.
class PerformanceTelemetry {
  PerformanceTelemetry._();

  static final PerformanceTelemetry instance = PerformanceTelemetry._();

  /// Whether telemetry is enabled (opt-in).
  bool _enabled = false;

  /// Enable or disable telemetry.
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Records a journal render event with bucketed milliseconds.
  ///
  /// Buckets: <100ms, 100-200ms, 200-500ms, >500ms
  void recordJournalRender(int milliseconds) {
    if (!_enabled) return;

    final bucket = _bucketRenderTime(milliseconds);
    _logEvent('perf_journal_render', {'bucket': bucket});
  }

  /// Records a database query event with bucketed milliseconds.
  ///
  /// Buckets: <50ms, 50-100ms, 100-200ms, >200ms
  void recordDatabaseQuery(String queryType, int milliseconds) {
    if (!_enabled) return;

    final bucket = _bucketQueryTime(milliseconds);
    _logEvent('perf_db_query', {
      'query_type': queryType,
      'bucket': bucket,
    });
  }

  /// Records app startup time with bucketed milliseconds.
  void recordAppStartup(int milliseconds) {
    if (!_enabled) return;

    final bucket = _bucketStartupTime(milliseconds);
    _logEvent('perf_app_startup', {'bucket': bucket});
  }

  String _bucketRenderTime(int ms) {
    if (ms < 100) return '<100ms';
    if (ms < 200) return '100-200ms';
    if (ms < 500) return '200-500ms';
    return '>500ms';
  }

  String _bucketQueryTime(int ms) {
    if (ms < 50) return '<50ms';
    if (ms < 100) return '50-100ms';
    if (ms < 200) return '100-200ms';
    return '>200ms';
  }

  String _bucketStartupTime(int ms) {
    if (ms < 500) return '<500ms';
    if (ms < 1000) return '500-1000ms';
    if (ms < 2000) return '1-2s';
    return '>2s';
  }

  void _logEvent(String eventName, Map<String, String> properties) {
    // In production, send to analytics service (Firebase, Mixpanel, etc.)
    // For now, just log locally
    // ignore: avoid_print
    print('[Telemetry] $eventName: $properties');
  }

  /// Measures and records the execution time of a function.
  Future<T> measure<T>(
    String eventType,
    Future<T> Function() fn,
  ) async {
    if (!_enabled) return fn();

    final stopwatch = Stopwatch()..start();
    try {
      return await fn();
    } finally {
      stopwatch.stop();
      switch (eventType) {
        case 'journal_render':
          recordJournalRender(stopwatch.elapsedMilliseconds);
        case 'db_query':
          recordDatabaseQuery('generic', stopwatch.elapsedMilliseconds);
        case 'app_startup':
          recordAppStartup(stopwatch.elapsedMilliseconds);
      }
    }
  }
}
