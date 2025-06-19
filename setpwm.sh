# activate the PWM.
echo 0 > /sys/class/pwm/pwmchip0/export
#Wait for export to settle
sleep 2
# set period to 10ms
echo 10000000 > /sys/class/pwm/pwmchip0/pwm0/period
# set normal polarity. needs to be reset explicitly. Bug?
echo "inversed" > /sys/class/pwm/pwmchip0/pwm0/polarity
echo "normal" > /sys/class/pwm/pwmchip0/pwm0/polarity
# enable the PWM
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
# set duty cycle to 1ms
if [ -n "$FANPWM" ]; then
 echo "$FANPWM" > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
else
 echo 3000000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
fi
