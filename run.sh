#!/usr/bin/env bash
set -euxo pipefail

USER_NAME=${USER_NAME:-admin}
USER_PASS=${USER_PASS:-admin}


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
touch /var/db/.AppleDiagnosticsSetupDone
SA="/Library/Preferences/com.apple.SetupAssistant"
for key in DidSeeCloudSetup DidSeePrivacy DidSeeAccessibility DidSeeAppearanceSetup \
           DidSeeScreenTime DidSeeSiriSetup DidSeeAvatarSetup DidSeeIntelligence \
           SkipCloudSetup SkipPrivacySetup SkipAppearanceSetup SkipScreenTime \
           SkipSiriSetup SkipTouchIDSetup SkipTrueToneEnable SkipAccessibility; do
  defaults write "${SA}" "${key}" -bool true
done


sysadminctl -addUser "$USER_NAME" -password "$USER_PASS" -admin

if [[ -f /System/Library/LaunchDaemons/ssh.plist ]]; then
  launchctl enable system/com.openssh.sshd
  launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
#  launchctl load -w /System/Library/LaunchDaemons/ssh.plist
fi


systemsetup -settimezone America/Chicago

scutil --set ComputerName "main"
scutil --set LocalHostName "main"
scutil --set HostName "main"


pmset -a displaysleep 0
pmset -a disksleep 0
pmset -a sleep 0
pmset -a autorestart 1
pmset -a womp 1

sysadminctl -screenLock off -password admin

USER_PASS="admin"
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
  echo "ok: kcpassword written"
else
  echo "WARN: kcpassword encode failed; auto-login may not work"
fi

sysadminctl -autologin set -userName admin -password admin


USER_SUDOERS_PATH=/etc/sudoers.d/"$USER_NAME"

cat > "$USER_SUDOERS_PATH" <<SUDO
${USER_NAME} ALL=(ALL) NOPASSWD: ALL
SUDO

chmod 440 "$USER_SUDOERS_PATH"
if visudo -cf "$USER_SUDOERS_PATH"; then
  echo "ok: passwordless sudo for ${USER_NAME}"
else
  echo "WARN: sudoers.d/${USER_NAME} failed visudo; removing"
  rm -f "$USER_SUDOERS_PATH"
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