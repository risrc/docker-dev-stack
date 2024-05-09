<!DOCTYPE html>
<html>
    <head>
        <title>Dev Proxy - Project Overview</title>
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        <link rel="stylesheet" href="main.css">
    </head>
    <body>
        <header>
            <h1>Dev Proxy - Project Overview</h1>
        </header>
        <nav>
        {{ range $project, $containers := groupByLabel $ "com.docker.compose.project" }}
            <article>
                <h3>{{ $project }}</h3>
                <ul>
                {{ range $host, $projectContainers := groupByMulti $containers "Env.VIRTUAL_HOST" "," }}
                    <li><a href="https://{{ $host }}">{{ $host }}</a></li>
                {{ end }}
                </ul>
            </article>
        {{ end }}
        </nav>
        <footer>
            Powered by <a href="https://gitlab.com/risrc/dev-proxy">RiSrc DevProxy</a>
        </footer>
    </body>
</html>