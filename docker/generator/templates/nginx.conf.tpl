{{/* default nginx configuration template */}}
{{/* Generate a configuration file based on the containers mandatory */}}
{{/* VIRTUAL_HOST environment variable and the exposed ports. If multiple */}}
{{/* ports are exposed, the first one is used, unless set with VIRTUAL_PORT */}}

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

{{ range $index, $value := $containers }}

	{{ $addrLen := len $value.Addresses }}
	{{ $network := index $value.Networks 0 }}

	{{ if $value.State.Health.Status }}
		{{ if ne $value.State.Health.Status "healthy" }}
			{{ continue }}
		{{ end }}
	{{ end }}

	{{/* If only 1 port exposed, use that */}}
	{{ if eq $addrLen 1 }}
		{{ with $address := index $value.Addresses 0 }}
			# {{$value.Name}}
			server {{ $network.IP }}:{{ $address.Port }};
		{{ end }}

	{{/* If more than one port exposed, use the one matching VIRTUAL_PORT env var */}}
	{{ else if $value.Env.VIRTUAL_PORT }}
		{{ range $i, $address := $value.Addresses }}
			{{ if eq $address.Port $value.Env.VIRTUAL_PORT }}
			# {{$value.Name}}
			server {{ $network.IP }}:{{ $address.Port }};
			{{ end }}
		{{ end }}

	{{/* Else default to standard web port 80 */}}
	{{ else }}
		{{ range $i, $address := $value.Addresses }}
			{{ if eq $address.Port "80" }}
			# {{$value.Name}}
			server {{ $network.IP }}:{{ $address.Port }};
			{{ end }}
		{{ end }}
	{{ end }}
{{ end }}
}

server {
	gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    listen 443 ssl;
    http2 on;

	server_name {{ $host }};
	proxy_buffering off;
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
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

		# HTTP 1.1 support
		proxy_http_version 1.1;
		#proxy_set_header Connection "";
	}
}
{{ end }}