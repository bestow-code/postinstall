#!/usr/bin/env bash
echo "hello world" > /var/root/install.log
echo $USER_NAME
#sudo sysadminctl -screenLock off -password $USER_PASS
#sudo sysadminctl -autologin set -userName $USER_NAME -password $USER_PASS

#
# defaults -currentHost write com.apple.screensaver idleTime 0 || true
# defaults write com.apple.screensaver loginWindowIdleTime 0 || true
# defaults write com.apple.screensaver askForPassword -int 0 || true
# defaults write -g KeyRepeat -int 1 || true
# defaults write -g InitialKeyRepeat -int 10 || true
# defaults write -g com.apple.mouse.scaling -float 3 || true
# defaults write -g com.apple.trackpad.scaling -float 3 || true
# defaults write -g AppleKeyboardUIMode -int 2 || true