i3lock &
(while pidof i3lock; do
  if (fprintd-verify | grep verify-match); then 
    killall i3lock
  fi
done) &

