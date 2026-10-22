#!/usr/bin/env bash
set -euxo pipefail

USER_NAME=${USER_NAME:-admin}
USER_PASS=${USER_PASS:-admin}

tmutil localsnapshot /


#log() { echo "[homelab-bootstrap $(date '+%Y-%m-%dT%H:%M:%S%z')] $*"; }
#try() {
#  local label="$1"; shift
#  set +e
#  "$@"
#  local rc=$?
#  set -e
#  if [[ $rc -ne 0 ]]; then
#    log "WARN: ${label} failed exit=${rc} cmd: $*"
#  else
#    log "ok: ${label}"
#  fi
#  return 0
#}


UT="/Library/User Template"
mkdir -p "${UT}/Non_localized"
touch "${UT}/Non_localized/.skipbuddy"
chmod 644 "${UT}/Non_localized/.skipbuddy"
for d in "${UT}"/*.lproj; do
  [[ -d "$d" ]] || continue
  touch "${d}/.skipbuddy"
  chmod 644 "${d}/.skipbuddy"
done


touch /var/db/.AppleSetupDone
#log "ok: touched /var/db/.AppleSetupDone"
#try "AppleDiagnosticsSetupDone"
touch /var/db/.AppleDiagnosticsSetupDone
SA="/Library/Preferences/com.apple.SetupAssistant"
for key in DidSeeCloudSetup DidSeePrivacy DidSeeAccessibility DidSeeAppearanceSetup \
           DidSeeScreenTime DidSeeSiriSetup DidSeeAvatarSetup DidSeeIntelligence \
           SkipCloudSetup SkipPrivacySetup SkipAppearanceSetup SkipScreenTime \
           SkipSiriSetup SkipTouchIDSetup SkipTrueToneEnable SkipAccessibility; do
  try "SA ${key}" defaults write "${SA}" "${key}" -bool true

done


sysadminctl -addUser "$USER_NAME" -password "$USER_PASS" -admin

if [[ -f /System/Library/LaunchDaemons/ssh.plist ]]; then
#  try "launchctl enable sshd"
  launchctl enable system/com.openssh.sshd
#  try "launchctl bootstrap sshd"
  launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
#  try "launchctl load sshd"
#  launchctl load -w /System/Library/LaunchDaemons/ssh.plist
fi


USER_SUDOERS_PATH=/etc/sudoers.d/"$USER_NAME"

cat > "$USER_SUDOERS_PATH" <<SUDO
${USER_NAME} ALL=(ALL) NOPASSWD: ALL
SUDO

chmod 440 "$USER_SUDOERS_PATH"
if visudo -cf "$USER_SUDOERS_PATH"; then
  log "ok: passwordless sudo for ${USER_NAME}"
else
  log "WARN: sudoers.d/${USER_NAME} failed visudo; removing"
  rm -f "$USER_SUDOERS_PATH"
fi

USER_NAME=$USER_NAME USER_PASS=$USER_PASS sudo -u admin -g admin -E "${TARGET_DIR}"/_configure.sh

#
# defaults -currentHost write com.apple.screensaver idleTime 0 || true
# defaults write com.apple.screensaver loginWindowIdleTime 0 || true
# defaults write com.apple.screensaver askForPassword -int 0 || true
# defaults write -g KeyRepeat -int 1 || true
# defaults write -g InitialKeyRepeat -int 10 || true
# defaults write -g com.apple.mouse.scaling -float 3 || true
# defaults write -g com.apple.trackpad.scaling -float 3 || true
# defaults write -g AppleKeyboardUIMode -int 2 || true