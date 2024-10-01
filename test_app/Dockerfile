# Используйте конкретный тег версии для большей стабильности и предсказуемости
FROM nginx:1.21-alpine 

# Скопируйте конфигурационный файл nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Скопируйте статические файлы в директорию Nginx
COPY html/ /usr/share/nginx/html/

# Откройте порт для Nginx
EXPOSE 80

# Используйте переменные окружения для гибкости (если требуется)
ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

# Добавьте команду запуска
CMD ["nginx", "-g", "daemon off;"]
