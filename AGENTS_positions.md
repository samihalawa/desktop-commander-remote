INDEX
2026-07-19 16:40 Europe/Madrid | menubar "disconnected" + freeze | do check launchd disabled-state and external reapers before touching device code | don't diagnose from the menubar UI, and don't use `KeepAlive.SuccessfulExit=false` for a SIGTERM-able daemon | verify `launchctl print-disabled`, reaper PATTERN match, and main-thread cost of any timer
2026-06-24 00:00 Europe/Madrid | remote-device identity drift | do resolve active account from session/config and rebind on mismatch | don't hardcode alias email in reconnect/device selection | verify `remoteChannel.user.email`, persisted config, and device ownership before retrying
2026-06-03 19:15 Europe/Madrid | remote-device rerun/reconnect | do runtime+session proof before reconnect patches | don't diagnose reconnect from README/UI alone | verify launchctl state, device.log, device.json session, account identity

## 2026-07-19 16:40 Europe/Madrid - CURRENT
- surface/workflow: menu bar app status ("disconnected") and UI freezes; `com.desktopcommander.remote-device` LaunchAgent
- mistaken/regressive approach: treat "disconnected" as a reconnect/UI defect; also my first-pass plist used `KeepAlive.SuccessfulExit=false`, which never restarts a daemon that exits 0 after a graceful SIGTERM
- superior approach: the menubar was reporting truthfully. Three independent layers were broken: (1) the LaunchAgent plist did not exist and the service was `disabled` in launchd (persistent override, survives reboot; makes `bootstrap` fail with errno 5); (2) `~/bin/reap-orphan-mcp.sh` matched `desktop-commander` and its `PPID==1` orphan heuristic is ALWAYS true for a launchd daemon, so it SIGTERMed the device every 30 min; (3) the freeze was `loadLogs()` reading the whole 70MB `device.log` on the main thread every 2s
- evidence: `launchctl print-disabled gui/501` showed `=> disabled`; manual boot logged `Device marked as online` proving device code was fine; measured log read at 0.71s/refresh vs 0.0014s after tailing 64KB; reaper run left PID unchanged after adding a KEEP exclusion
- trigger terms/symptoms: `disconnected`, `offline`, `frozen`, `beachball`, `Bootstrap failed: 5`, SIGTERM with exit 0, device dies ~every 30 min
- required verification before reuse: prove the daemon boots by hand FIRST; then check `launchctl print-disabled`, then grep external reaper/cleanup scripts for a matching PATTERN; only then look at reconnect code
- do: treat repeating ~30-min death as an external killer until proven otherwise
- don't: swallow `launchctl` stderr with `try?` — that hid errno 5 and made a failed Start look identical to a successful one

## 2026-06-24 00:00 Europe/Madrid - CURRENT
- surface/workflow: `/Users/samihalawa/git/PROJECTS_CODING/desktop-commander-remote` remote-device account binding and device selection
- mistaken/regressive approach: patch only the visible email alias in one place when the real failure is stale account identity flowing through persisted session, device lookup, or launcher state
- superior approach: derive active identity from the authenticated Supabase session and persisted config, then reconcile or reset stale device/session state when the session email or owner no longer matches the intended account
- evidence: current code reads `this.remoteChannel.user!.email`, persists `deviceId` plus optional session in `~/.desktop-commander-device/device.json`, and routes device lookup through `findDevice(currentDeviceId)`; the repo search found no live `autoclient.art` source binding in `src/`
- trigger terms/symptoms: `No devices available for sami@autoclient.art`, `offline-device`, alias drift, wrong account, reconnect succeeds but device list is empty
- required verification before reuse: inspect the live session email, persisted config, and device ownership together; if they disagree, clear or rebind the stale session instead of changing a display string
- do: make account identity a resolved state, not a literal
- don't: paper over identity drift with a single-email patch

## 2026-06-03 19:15 Europe/Madrid - CURRENT
- surface/workflow: `/Users/samihalawa/git/PROJECTS_CODING/desktop-commander-remote` remote device LaunchAgent rerun/reconnect
- mistaken/regressive approach: assume reconnect logic is broken and start patching `remote-channel.ts` or menu-bar restart flow before proving the daemon can boot and the persisted session belongs to the intended account
- superior approach: verify the lowest failing layer first: `launchctl print gui/501/com.desktopcommander.remote-device`, `~/.desktop-commander-device/device.log`, `~/.desktop-commander-device/device.json`, then only change reconnect code if those surfaces show a real reconnect defect
- evidence: 2026-06-03 live proof showed repeated `ERR_MODULE_NOT_FOUND` for `@supabase/supabase-js`, then after `npm install` the daemon started, authenticated, persisted `session`, and a fresh restart logged `✅ Session restored`
- trigger terms/symptoms: `rerun`, `reconnect`, `daemon`, `wrong account`, `persist-session`, `launchctl`, `device.json`, `device.log`
- required verification before reuse: quote the exact log lines for boot/auth/reconnect, confirm LaunchAgent is pointing at this repo's `dist/remote-device/device.js`, and inspect token/account identity instead of trusting one label
- do: treat reconnect as a runtime-session proof chain
- don't: add wrapper restarts, UI toggles, or backoff patches when the daemon is crash-looping or bound to the wrong persisted session
