# nginx virtualhost SSL for: {$VHOST}
server {
        listen {$SERVER_IP}:443 ssl;
        server_name {$VHOST_HOSTNAME}{$VHOST_HOSTNAME_ALIASES};
        error_log  /usr/home/www/{$VHOST}/logs/error-nginx.log error;
        ssl_certificate     /usr/local/etc/letsencrypt/live/{$VHOST}/cert.pem;
        ssl_certificate_key /usr/local/etc/letsencrypt/live/{$VHOST}/privkey.pem;
        ssl_trusted_certificate /usr/local/etc/letsencrypt/live/{$VHOST}/fullchain.pem;
        include /usr/local/etc/nginx/ssl_common.conf;

        location / {
            proxy_pass https://{$VHOST_HOSTNAME}:{$APACHE_HTTPS};
            include /usr/local/etc/nginx/proxy.conf;
            # include /usr/local/etc/nginx/proxy_cache.conf;
            location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|tif|tiff|css|js|htm|html|ttf|otf|webp|woff|txt|csv|rtf|doc|docx|xls|xlsx|ppt|pptx|odf|odp|ods|odt|pdf|psd|ai|eot|eps|ps|zip|tar|tgz|gz|rar|bz2|7z|aac|m4a|mp3|mp4|ogg|wav|wma|3gp|avi|flv|m4v|mkv|mov|mp4|mpeg|mpg|wmv|exe|iso|dmg|swf)$ {
                root {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR}
                access_log {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/access-nginx.log main;
                expires        max;
                try_files      $uri @fallback;
            }
            location ~ /.well-known {
                allow all;
            }
        }

        location @fallback {
            proxy_pass https://{$VHOST_HOSTNAME}:{$APACHE_HTTPS};
            include /usr/local/etc/nginx/proxy.conf;
            # include /usr/local/etc/nginx/proxy_cache.conf;
        }

        location ~ /\.ht    {return 404;}
        location ~ /\.svn/  {return 404;}
        location ~ /\.git/  {return 404;}
        location ~ /\.hg/   {return 404;}
        location ~ /\.bzr/  {return 404;}
}
