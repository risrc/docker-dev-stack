{{/* default nginx configuration template
   * Generate a configuration file based on the containers mandatory VIRTUAL_HOST environment variable
   * and the exposed ports. If multiple ports are exposed, the first one is used, unless set with VIRTUAL_PORT
   */}}
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      '';
}
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    http2  on;

    server_name localhost;

    ssl_certificate /etc/nginx/certs/localhost.pem;
    ssl_certificate_key /etc/nginx/certs/localhost-key.pem;

    root /usr/share/nginx/html/;

    if ($host != $server_name) {
        return 404;
    }
}

{{ range $host, $containers := groupByMulti $ "Env.VIRTUAL_HOST" "," }}
upstream {{ $host }} {
    zone upstreams 64K;
{{ range $index, $value := $containers }}

	{{ $addrLen := len $value.Addresses }}
	{{ $network := index $value.Networks 0 }}

	{{ range sortObjectsByKeysAsc $value.Networks "Name" }}
	    {{ if eq "default" ( split .Name "_" | last ) }}
	        {{/* skip default networks */}}
	        {{ continue }}
	    {{ end }}
	    {{ if eq "dev_proxy" .Name }}
	        {{/* use 'dev_proxy' network */}}
	        {{ $network = . }}
	        {{ break }}
	    {{ end }}
	    {{ $network = . }}
	{{ end }}

	{{ if $value.State.Health.Status }}
		{{ if ne $value.State.Health.Status "healthy" }}
			{{ continue }}
		{{ end }}
	{{ end }}

    # {{$value.Name}}
	{{/* If only 1 port exposed, use that */}}
	{{ if eq $addrLen 1 }}
    {{ with $address := index $value.Addresses 0 }}
    server {{ $network.IP }}:{{ $address.Port }} max_fails=1 fail_timeout=2s;
    {{ end }}
	{{/* If more than one port exposed, use the one matching VIRTUAL_PORT env var */}}
	{{ else if $value.Env.VIRTUAL_PORT }}
	server {{ $network.IP }}:{{ $value.Env.VIRTUAL_PORT }} max_fails=1 fail_timeout=2s;
	{{/* Else default to standard web port 80 */}}
	{{ else }}
	server {{ $network.IP }}:80 max_fails=1 fail_timeout=2s;
	{{ end }}
{{ end }}
    keepalive 2;
}

server {
	gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    listen 443 ssl;
    {{ $container := index $containers 0 }}
    {{ if not $container.Env.DISABLE_HTTP2 }}http2 on;{{ end }}

	server_name {{ $host }};
	# proxy_buffering off; # Disabled, for reason see https://www.f5.com/company/blog/nginx/avoiding-top-10-nginx-configuration-mistakes#proxy_buffering-off
	error_log /proc/self/fd/2;
	access_log /proc/self/fd/1;

	ssl_certificate /etc/nginx/certs/{{$host}}.pem;
    ssl_certificate_key /etc/nginx/certs/{{$host}}-key.pem;

	location / {
		proxy_pass http://{{ trim $host }};
		proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
		proxy_set_header X-Forwarded-Host $server_name;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_next_upstream error timeout http_500;

        # websocket support
		proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        # extend timeouts
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_connect_timeout 60s;

        # adjust buffer for performance
        proxy_buffer_size 16k;
        proxy_buffers 4 32k;
    }
}
{{ end }}