// Lets a USB-connected Android phone reach the local backend at http://127.0.0.1:4100/api.
// Finds adb even when Android platform-tools is not on PATH.
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const port = process.argv[2] || '4100';
const exe = process.platform === 'win32' ? 'adb.exe' : 'adb';
const sdkRoots = [process.env.ANDROID_HOME, process.env.ANDROID_SDK_ROOT,
  process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, 'Android', 'Sdk'),
  process.env.HOME && join(process.env.HOME, 'Library', 'Android', 'sdk'),
  process.env.HOME && join(process.env.HOME, 'Android', 'Sdk')].filter(Boolean);
const adb = sdkRoots.map(root => join(root, 'platform-tools', exe)).find(existsSync) || 'adb';

const run = args => spawnSync(adb, args, { stdio: 'inherit' });
const devices = spawnSync(adb, ['devices'], { encoding: 'utf8' });
if (devices.error) {
  console.error(`Could not run adb (${devices.error.message}). Install Android platform-tools or set ANDROID_HOME.`);
  process.exit(1);
}
const connected = devices.stdout.split('\n').slice(1).map(l => l.trim()).filter(l => /\tdevice$/.test(l));
if (!connected.length) {
  console.error('No Android device connected. Plug in the phone, enable USB debugging, accept the prompt, then retry.\n' + devices.stdout);
  process.exit(1);
}
const result = run(['reverse', `tcp:${port}`, `tcp:${port}`]);
if (result.status !== 0) process.exit(result.status ?? 1);
console.log(`Phone port ${port} now forwards to this PC. Run the app with:  flutter run --dart-define-from-file=env/usb.json`);
