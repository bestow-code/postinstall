#!/usr/bin/env bash

set -euxo pipefail

USER_NAME=${USER_NAME:-admin}
USER_PASS=${USER_PASS:-admin}

sudo systemsetup -settimezone America/Chicago

sudo scutil --set ComputerName "main"
sudo scutil --set LocalHostName "main"
sudo scutil --set HostName "main"


sudo pmset -a displaysleep 0
sudo pmset -a disksleep 0
sudo pmset -a sleep 0
sudo pmset -a autorestart 1
sudo pmset -a womp 1

sudo sysadminctl -screenLock off -password admin

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

sudo sysadminctl -autologin set -userName admin -password admin




#
# defaults -currentHost write com.apple.screensaver idleTime 0 || true
# defaults write com.apple.screensaver loginWindowIdleTime 0 || true
# defaults write com.apple.screensaver askForPassword -int 0 || true
# defaults write -g KeyRepeat -int 1 || true
# defaults write -g InitialKeyRepeat -int 10 || true
# defaults write -g com.apple.mouse.scaling -float 3 || true
# defaults write -g com.apple.trackpad.scaling -float 3 || true
# defaults write -g AppleKeyboardUIMode -int 2 || true