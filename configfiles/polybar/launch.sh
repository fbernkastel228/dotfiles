#!/usr/bin/env bash

# Ждем готовности системы (критично для i3)
sleep 2

# Убиваем все предыдущие процессы polybar
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# Ваши конкретные мониторы
MONITORS=("DVI-I-0" "HDMI-0" "HDMI-1")

# Запускаем на каждом мониторе
for monitor in "${MONITORS[@]}"; do
    # Проверяем подключен ли монитор
    if xrandr | grep -q "^$monitor connected"; then
        echo "Запуск Polybar на $monitor"
        MONITOR=$monitor polybar -c ~/.config/polybar/config.ini main &> "/tmp/polybar-$monitor.log" &
        sleep 0.5  # Важная задержка между запусками
    fi
done
