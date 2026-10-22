#!/usr/bin/env bash

set -euxo pipefail

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

#try "ComputerName main"
sudo scutil --set ComputerName "main"
#try "LocalHostName main"
sudo scutil --set LocalHostName "main"
#try "HostName main"
sudo scutil --set HostName "main"
echo "hostname now: ComputerName=$(scutil --get ComputerName) LocalHostName=$(scutil --get LocalHostName) HostName=$(scutil --get HostName 2>&1 || echo unset)"

sudo systemsetup -settimezone America/Chicago


#try "pmset displaysleep 0"
sudo pmset -a displaysleep 0
#try "pmset disksleep 0"
sudo pmset -a disksleep 0
#try "pmset sleep 0"
sudo pmset -a sleep 0
#try "pmset autorestart 1"
sudo pmset -a autorestart 1
#try "pmset womp 1"
sudo pmset -a womp 1

sudo sysadminctl -screenLock off -password admin

sudo sysadminctl -autologin set -userName admin -password admin

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





#
# defaults -currentHost write com.apple.screensaver idleTime 0 || true
# defaults write com.apple.screensaver loginWindowIdleTime 0 || true
# defaults write com.apple.screensaver askForPassword -int 0 || true
# defaults write -g KeyRepeat -int 1 || true
# defaults write -g InitialKeyRepeat -int 10 || true
# defaults write -g com.apple.mouse.scaling -float 3 || true
# defaults write -g com.apple.trackpad.scaling -float 3 || true
# defaults write -g AppleKeyboardUIMode -int 2 || true