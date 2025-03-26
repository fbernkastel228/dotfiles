#!/usr/local/bin/bash

# Параметры
MAX_LENGTH=20
SCROLL_SPEED=1.8
PAUSE_SECONDS=1.2
CACHE_FILE="/tmp/polybar_player_cache"  # Единый файл для всех процессов
LOCK_FILE="/tmp/polybar_player.lock"

# Атомарные операции через lock
exec 9>"$LOCK_FILE"
flock -x 9 || exit 0

# Получаем статус плеера
player_status=$(playerctl status 2>/dev/null)

# Если плеер не активен
if [[ "$player_status" != "Playing" && "$player_status" != "Paused" ]]; then
    rm -f "$CACHE_FILE"
    echo " No player"
    flock -u 9
    exit 0
fi

# Получаем метаданные
current_id=$(playerctl metadata mpris:trackid 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null || echo "")
title=$(playerctl metadata title 2>/dev/null || echo "")

# Формируем текст
text="${artist:+$artist - }$title"
clean_text=$(echo "$text" | sed 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g')
text_length=${#clean_text}

# Если текст короткий - выводим без скролла
if (( text_length <= MAX_LENGTH )); then
    icon=$([[ "$player_status" == "Playing" ]] && echo "" || echo "")
    echo "$icon $clean_text"
    flock -u 9
    exit 0
fi

# Синхронизированный скроллинг
now=$(date +%s.%N)
if [[ -f "$CACHE_FILE" ]]; then
    read cache_id cache_pos cache_time < "$CACHE_FILE"
    if [[ "$cache_id" != "$current_id" ]]; then
        # Новый трек - сбрасываем позицию
        cache_pos=0
        cache_time=$now
    fi
else
    # Первый запуск
    cache_id="$current_id"
    cache_pos=0
    cache_time=$now
fi

# Рассчитываем новую позицию
elapsed=$(echo "$now - $cache_time" | bc)
new_pos=$(echo "$cache_pos + ($elapsed * $SCROLL_SPEED)" | bc)
cycle_length=$(echo "$text_length + $PAUSE_SECONDS * 2" | bc)

if (( $(echo "$new_pos >= $cycle_length" | bc -l) )); then
    new_pos=$(echo "$new_pos % $cycle_length" | bc)
fi

# Определяем отображаемый текст
if (( $(echo "$new_pos < $PAUSE_SECONDS" | bc -l) )); then
    # Начальная пауза
    display_text="${clean_text:0:$MAX_LENGTH}"
elif (( $(echo "$new_pos > $cycle_length - $PAUSE_SECONDS" | bc -l) )); then
    # Конечная пауза
    display_text="${clean_text: -$MAX_LENGTH}"
else
    # Скроллинг
    pos=$(echo "$new_pos - $PAUSE_SECONDS" | bc)
    pos=${pos%.*} # Округляем до целого
    display_text="${clean_text:$pos:$MAX_LENGTH}"
fi

# Обновляем кэш
echo "$current_id $new_pos $now" > "$CACHE_FILE"

# Выводим результат
icon=$([[ "$player_status" == "Playing" ]] && echo "" || echo "")
echo "$icon $display_text"

# Снимаем блокировку
flock -u 9
