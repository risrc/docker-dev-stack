<!DOCTYPE html>
<html>
    <head>
        <title>Docker Boxes</title>
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    </head>
    <body>
        <nav>
            <ul>
            {{ range $host, $containers := groupByMulti $ "Env.VIRTUAL_HOST" "," }}
            <li><a href="https://{{ $host }}">{{ $host }}</a></li>
            {{ end }}
            </ul>
        </nav>
    </body>
</html>