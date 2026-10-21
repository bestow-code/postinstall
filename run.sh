#!/usr/bin/env bash
echo "hello world"
echo $USER_NAME

tmutil localsnapshot /


log() { echo "[homelab-bootstrap $(date '+%Y-%m-%dT%H:%M:%S%z')] $*"; }
try() {
  local label="$1"; shift
  set +e
  "$@"
  local rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    log "WARN: ${label} failed exit=${rc} cmd: $*"
  else
    log "ok: ${label}"
  fi
  return 0
}


UT="/Library/User Template"
mkdir -p "${UT}/Non_localized"
touch "${UT}/Non_localized/.skipbuddy"
chmod 644 "${UT}/Non_localized/.skipbuddy"
for d in "${UT}"/*.lproj; do
  [[ -d "$d" ]] || continue
  touch "${d}/.skipbuddy"
  chmod 644 "${d}/.skipbuddy"
done

sysadminctl -addUser $USER_NAME -password $USER_PASS -admin
sysadminctl -autologin set -userName $USER_NAME -password $USER_PASS
sysadminctl -screenLock off -password $USER_PASS


touch /var/db/.AppleSetupDone
log "ok: touched /var/db/.AppleSetupDone"
try "AppleDiagnosticsSetupDone" touch /var/db/.AppleDiagnosticsSetupDone
SA="/Library/Preferences/com.apple.SetupAssistant"
for key in DidSeeCloudSetup DidSeePrivacy DidSeeAccessibility DidSeeAppearanceSetup \
           DidSeeScreenTime DidSeeSiriSetup DidSeeAvatarSetup DidSeeIntelligence \
           SkipCloudSetup SkipPrivacySetup SkipAppearanceSetup SkipScreenTime \
           SkipSiriSetup SkipTouchIDSetup SkipTrueToneEnable SkipAccessibility; do
  try "SA ${key}" defaults write "${SA}" "${key}" -bool true

done


if [[ -f /System/Library/LaunchDaemons/ssh.plist ]]; then
  try "launchctl enable sshd" launchctl enable system/com.openssh.sshd
  try "launchctl bootstrap sshd" launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
#  try "launchctl load sshd" launchctl load -w /System/Library/LaunchDaemons/ssh.plist
fi

try "ComputerName main" scutil --set ComputerName "main"
try "LocalHostName main" scutil --set LocalHostName "main"
try "HostName main" scutil --set HostName "main"
log "hostname now: ComputerName=$(scutil --get ComputerName) LocalHostName=$(scutil --get LocalHostName) HostName=$(scutil --get HostName 2>&1 || echo unset)"

systemsetup -settimezone America/Chicago


try "pmset sleep 0" pmset -a sleep 0
try "pmset displaysleep 0" pmset -a displaysleep 0
try "pmset disksleep 0" pmset -a disksleep 0
try "pmset autorestart 1" pmset -a autorestart 1
try "pmset womp 1" pmset -a womp 1

if perl -e '
  my $password = $ARGV[0];
  my @magic = (125,137,82,171,133,68,207,190,109,134,212,232);
  my @bytes = map { ord($_) } split //, $password;
  push @bytes, 0;
  my @out;
  for my $i (0..$#bytes) { push @out, $bytes[$i] ^ $magic[$i % @magic]; }
  while (@out % @magic != 0) { push @out, 0 ^ $magic[@out % @magic]; }
  open my $fh, ">", "/etc/kcpassword" or die $!;
  print $fh pack("C*", @out);
  close $fh;
' "${USER_PASS}"
then
  chmod 600 /etc/kcpassword
  log "ok: kcpassword written"
else
  log "WARN: kcpassword encode failed; auto-login may not work"
fi


cat > /etc/sudoers.d/${USER_NAME} <<SUDO
# Homelab CI: passwordless sudo for local admin
${USER_NAME} ALL=(ALL) NOPASSWD: ALL
SUDO
chmod 440 /etc/sudoers.d/${USER_NAME}
if visudo -cf /etc/sudoers.d/${USER_NAME}; then
  log "ok: passwordless sudo for ${USER_NAME}"
else
  log "WARN: sudoers.d/${USER_NAME} failed visudo; removing"
  rm -f /etc/sudoers.d/${USER_NAME}
fi

#
# defaults -currentHost write com.apple.screensaver idleTime 0 || true
# defaults write com.apple.screensaver loginWindowIdleTime 0 || true
# defaults write com.apple.screensaver askForPassword -int 0 || true
# defaults write -g KeyRepeat -int 1 || true
# defaults write -g InitialKeyRepeat -int 10 || true
# defaults write -g com.apple.mouse.scaling -float 3 || true
# defaults write -g com.apple.trackpad.scaling -float 3 || true
# defaults write -g AppleKeyboardUIMode -int 2 || true