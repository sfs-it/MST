# nginx virtualhost SSL for: {$VHOST}
server {
        listen {$SERVER_IP}:443 ssl;
        server_name {$VHOST}.local {$VHOST_HOSTNAME}{$VHOST_HOSTNAME_ALIASES};
        error_log {$VHOSTS_DIR}/{$VHOST}/logs/error-nginx.log error;
        ssl_certificate     /usr/local/etc/letsencrypt/live/{$VHOST}/fullchain.pem;
        ssl_certificate_key /usr/local/etc/letsencrypt/live/{$VHOST}/privkey.pem;
        ssl_trusted_certificate /usr/local/etc/letsencrypt/live/{$VHOST}/chain.pem;
        include /usr/local/etc/nginx/ssl_common.conf;
        gzip              on;
        gzip_static       on;
        gzip_comp_level   2;
        gzip_http_version 1.0;
        gzip_proxied      any;
        gzip_buffers      16 8k;
        gzip_types        text/plain text/css application/javascript application/x-javascript text/javascript text/xml application/xml application/xml+rss text/x-sass text/x-scss;
#        gzip_proxied      no-cache no-store private expired auth;
        gzip_min_length   1000;
        gzip_disable      "MSIE [1-6].(?!.*SV1)";
        gzip_vary         on;

        location / {
            root {$VHOSTS_DIR}/{$VHOST}/{$HTTPDOCS_DIR};
            proxy_pass https://{$VHOST_HOSTNAME}:{$APACHE_HTTPS};
            include /usr/local/etc/nginx/proxy.conf;
            # include /usr/local/etc/nginx/proxy_cache.conf;

            location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|tif|tiff|ttf|otf|webp|woff|pdf|psd|ai|eot|eps|ps|zip|tar|tgz|gz|rar|bz2|7z|aac|m4a|mp3|mp4|ogg|wav|wma|3gp|avi|flv|m4v|mkv|mov|mp4|mpeg|mpg|wmv|exe|iso|dmg|swf)$ {
                access_log {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/access-nginx.log main;
                expires        max;
                try_files      $uri @fallback;
            }

            location ~* ^.+\.(js|json|htm|html|txt|css|scss|csv|rtf|doc|docx|xls|xlsx|ppt|pptx|odf|odp|ods|odt)$ {
                access_log {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/access-nginx.log main;
                gzip              on;
                gzip_static       on;
                expires        max;
                try_files      $uri @fallback;
            }


            location ~ /.well-known {
                allow all;
                access_log {$VHOSTS_DIR}/{$VHOST}/{$HTTPLOGS_DIR}/access-nginx.log main;
                try_files $uri =404;
            }
        }

        location @fallback {
            proxy_pass https://{$VHOST}.local:{$APACHE_HTTPS};
            include /usr/local/etc/nginx/proxy.conf;
            # include /usr/local/etc/nginx/proxy_cache.conf;
        }

        location ~ /\.ht    {return 404;}
        location ~ /\.svn/  {return 404;}
        location ~ /\.git/  {return 404;}
        location ~ /\.hg/   {return 404;}
        location ~ /\.bzr/  {return 404;}
}
