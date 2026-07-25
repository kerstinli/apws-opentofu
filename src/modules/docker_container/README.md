# docker_container

Generisches Grundgerüst für einen einzelnen `docker_container`. Aktuell noch nicht von
`main.tf` referenziert — `opensearch`, `opensearch-dashboards` und `logstash` definieren ihre
Container derzeit direkt (siehe [`../opensearch`](../opensearch/README.md) bzw. `src/main.tf`).

## Inputs

| Name                | Beschreibung                     | Typ      | Default |
|---------------------|------------------------------------|----------|---------|
| `container_name`    | Name des Docker-Containers         | `string` | –       |
| `container_restart` | Restart-Policy des Containers      | `string` | –       |

## Ausbaustand

Deckt bisher nur Name + Restart-Policy ab — kein `image`, `env`, `ports`, `volumes` oder
`networks_advanced`. Bevor bestehende Container (z. B. `logstash` aus `src/main.tf`) hierhin
migriert werden, muss das Modul um diese Argumente erweitert werden.
