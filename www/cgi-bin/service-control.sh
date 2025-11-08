#!/bin/sh

echo "Content-Type: text/plain"
echo ""

# Получаем действие
if [ "$REQUEST_METHOD" = "POST" ]; then
    read POST_DATA
    ACTION=$(echo "$POST_DATA" | sed 's/action=//')
else
    ACTION=$(echo "$QUERY_STRING" | sed 's/action=//')
fi

# 🔧 ЗАМЕНИ ЭТО на свою службу!
SERVICE_NAME="zapret"

case "$ACTION" in
    "start")
        /etc/init.d/$SERVICE_NAME start >/dev/null 2>&1
        echo "Служба $SERVICE_NAME запущена"
        ;;
    "stop") 
        /etc/init.d/$SERVICE_NAME stop >/dev/null 2>&1
        echo "Служба $SERVICE_NAME остановлена"
        ;;
    "status")
        if /etc/init.d/$SERVICE_NAME status >/dev/null 2>&1; then
            echo "running"
        else
            echo "stopped"
        fi
        ;;
    *)
        echo "Неизвестное действие"
        ;;
esac
