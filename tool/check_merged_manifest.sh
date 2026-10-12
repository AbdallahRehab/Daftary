#!/usr/bin/env bash
# 023 Bank SMS Import (T105, FR-008a, FR-073, CHK013): checks the merged
# Android manifest of the last Gradle build against the SMS rules.
#
#   tool/check_merged_manifest.sh [debug|release|profile] [--expect-read-sms|--expect-no-read-sms]
#
# Run it after `flutter build apk` or `./gradlew :app:process<Variant>MainManifest`.
# The variant defaults to `release`. Whether READ_SMS is expected follows the
# capability switch: DAFTARY_SMS_IMPORT=true expects it, anything else
# expects no SMS permission at all. A build made with the Gradle-property
# fallback (-Pdaftary.smsImport=true) passes --expect-read-sms explicitly.
#
# Asserts:
#   1. READ_SMS is declared exactly when the capability switch is on.
#   2. RECEIVE_SMS, SEND_SMS, RECEIVE_MMS, RECEIVE_WAP_PUSH, WRITE_SMS and
#      READ_PHONE_STATE are never declared.
#   3. No SMS_RECEIVED, SMS_DELIVER, WAP_PUSH_DELIVER or WAP_PUSH_RECEIVED
#      intent action anywhere.
#   4. No receiver or service is declared by the app's own code
#      (com.daftary.*). Library receivers and services (for example the
#      flutter_local_notifications ones) are allowed and listed.
#   5. The ACTION_SEND text/plain filter is on ShareTargetActivity, and on
#      no other component (never on MainActivity).
#
# The merged manifest is located under the variant's merged_manifest
# directory instead of a hard-coded AGP path, so a layout change fails
# loudly ("not found") rather than passing silently.
set -euo pipefail

variant="release"
expect=""
for arg in "$@"; do
  case "$arg" in
    debug | release | profile) variant="$arg" ;;
    --expect-read-sms) expect="yes" ;;
    --expect-no-read-sms) expect="no" ;;
    *)
      echo "usage: $0 [debug|release|profile] [--expect-read-sms|--expect-no-read-sms]" >&2
      exit 2
      ;;
  esac
done
if [ -z "$expect" ]; then
  if [ "${DAFTARY_SMS_IMPORT:-}" = "true" ]; then expect="yes"; else expect="no"; fi
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
search_dir="$root/build/app/intermediates/merged_manifest/$variant"
cap_variant="$(printf '%s' "${variant:0:1}" | tr '[:lower:]' '[:upper:]')${variant:1}"
manifest=""
if [ -d "$search_dir" ]; then
  manifest="$(find "$search_dir" -path "*process${cap_variant}MainManifest*" -name AndroidManifest.xml | head -n 1)"
fi
if [ -z "$manifest" ] || [ ! -f "$manifest" ]; then
  echo "FAIL: merged manifest for '$variant' not found under $search_dir" >&2
  echo "      (build first: flutter build apk --$variant, or ./gradlew :app:process${cap_variant}MainManifest)" >&2
  exit 1
fi

echo "Checking $manifest (READ_SMS expected: $expect)"
python3 - "$manifest" "$expect" <<'PY'
import sys
import xml.etree.ElementTree as ET

path, expect = sys.argv[1], sys.argv[2]
A = "{http://schemas.android.com/apk/res/android}"
root = ET.parse(path).getroot()
package = root.get("package") or "com.daftary.daftary"
failures = []

def name(el):
    return el.get(A + "name") or ""

def full(component):
    n = name(component)
    return package + n if n.startswith(".") else n

# 1 and 2: permissions.
permissions = {
    name(el)
    for tag in ("uses-permission", "uses-permission-sdk-23")
    for el in root.iter(tag)
}
read_sms = "android.permission.READ_SMS" in permissions
if expect == "yes" and not read_sms:
    failures.append("READ_SMS is missing although the capability switch is on")
if expect == "no" and read_sms:
    failures.append("READ_SMS is declared although the capability switch is off")
for forbidden in (
    "RECEIVE_SMS",
    "SEND_SMS",
    "RECEIVE_MMS",
    "RECEIVE_WAP_PUSH",
    "WRITE_SMS",
    "READ_PHONE_STATE",
):
    if "android.permission." + forbidden in permissions:
        failures.append(forbidden + " is declared")

# 3: SMS broadcast actions anywhere.
for action in root.iter("action"):
    n = name(action)
    if any(
        n.endswith(s)
        for s in ("SMS_RECEIVED", "SMS_DELIVER", "WAP_PUSH_DELIVER", "WAP_PUSH_RECEIVED")
    ):
        failures.append("intent action " + n + " is declared")

app = root.find("application")
components = [] if app is None else list(app)

# 4: no receiver or service from the app's own code.
library = []
for comp in components:
    if comp.tag not in ("receiver", "service"):
        continue
    n = full(comp)
    if n.startswith("com.daftary."):
        failures.append(comp.tag + " " + n + " is declared by the app")
    else:
        library.append(comp.tag + " " + n)

# 5: the share filter is on ShareTargetActivity only.
share_target = package + ".ShareTargetActivity"
send_on = set()
for comp in components:
    for flt in comp.iter("intent-filter"):
        actions = {name(a) for a in flt.iter("action")}
        mimes = {d.get(A + "mimeType") for d in flt.iter("data")}
        if "android.intent.action.SEND" in actions:
            send_on.add((full(comp), "text/plain" in mimes))
if (share_target, True) not in send_on:
    failures.append("ACTION_SEND text/plain filter missing on ShareTargetActivity")
for comp_name, _ in send_on:
    if comp_name != share_target:
        failures.append("ACTION_SEND filter on " + comp_name)

print("READ_SMS declared: " + ("yes" if read_sms else "no"))
print("Library receivers/services (allowed): " + str(len(library)))
for item in sorted(library):
    print("  " + item)
if failures:
    for f in failures:
        print("FAIL: " + f)
    sys.exit(1)
print("OK: merged manifest satisfies the SMS rules")
PY
