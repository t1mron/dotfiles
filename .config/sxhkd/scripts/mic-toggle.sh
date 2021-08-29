###---MICROPHONE---###
MIC=$(amixer sget Capture | awk -F"[][]" '/Front Left:/ {print $2}')

case "$MIC" in
  25%)
    amixer set Capture 0% ;;
  0%)
    amixer set Capture 25% ;;
esac
