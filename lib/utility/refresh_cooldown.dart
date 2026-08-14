const Duration kRefreshCooldown = Duration(minutes: 2);
const Duration kRefreshCooldownBusyWait = Duration(seconds: 1);

/// Whether a user-initiated refresh may hit the network again.
bool hasRefreshCooldownElapsed({
  required DateTime now,
  int? lastRefreshMs,
  Duration cooldown = kRefreshCooldown,
}) {
  if (lastRefreshMs == null) return true;
  return now.difference(DateTime.fromMillisecondsSinceEpoch(lastRefreshMs)) >= cooldown;
}
