# UML-диаграммы
## Тема: "Разработка проекта SecCrate с использованием ИИ"

| Шаг | Файл | Что показывает |
|---|---|---|
| 1.1 | `01-usecase.png` | Прецеденты |
| 1.2 | `02-activity.png` | Деятельность |
| 1.3 | `03-class.png` | Классов |
| 1.4 | `04-sequence.png` | Последовательности |

Пересобрать картинки: `./render.sh`.

## Как они вытекают друг из друга

| Класс на схеме | Где в проекте |
|---|---|
| `Gateway.handleRepository`, `streamBlob` | `gateway/cmd/gateway/main.go` |
| `ResolveAPI.resolve`, `_user_from_token`, `_reject`, `stream_blob` | `backend/seccrate/api/routers/internal.py` |
| `AccessControl.can_gateway_read`, `can_gateway_read_path` | `backend/seccrate/services/access.py` |
| `ArtifactIndex.find_artifact`, `ensure_pending_scan`, `wait_ready`, `decision_for_get`, `effective_sync_wait` | `backend/seccrate/services/gateway.py` |
| `UpstreamClient.fetch_miss`, `fetch_upstream` | `backend/seccrate/services/upstream.py` |
| `SsrfGuard.assert_safe_http_url` | `backend/seccrate/security/ssrf.py` |
| `BlobStore.put_bytes`, `download_to` | `backend/seccrate/services/blobs.py` |
| `Worker.process_job`, `run` | `backend/seccrate/worker/main.py` |
| `ScanQueue.claim_queued_scan` | `backend/seccrate/services/scan_lanes.py` |
| `ScanEngine.run_all`, `worst`, `Scanner.scan` | `backend/seccrate/scanners/engines.py` |
| `Findings.sync_findings` | `backend/seccrate/services/artifact_view.py` |

Имена в таблице — классы и методы в коде. У классов на Python методы статические: сессия базы, настройки и клиент хранилища передаются аргументами. `Scanner` — базовый класс, `GrypeScanner`, `TrivyScanner` и `OsvScanner` переопределяют `scan`.

## Описание простыми словами

Разработчик запрашивает артефакт/файл -> `Gateway` вызывает `resolve`.

`ResolveAPI` идентифицирует пользователя (`_user_from_token`) и дважды спрашивает `AccessControl`. Если хотя бы один ответ `false`, фрагмент **break** обрывает сценарий: 403 HTTP.

Дальше `find_artifact`. Пакета нет, поэтому `fetch_miss` → `fetch_upstream`. Перед скачиванием `assert_safe_http_url` проверяет адрес. Байты кладёт `put_bytes`. Появляется объект `Artifact` со статусом `pending` и объект `ScanJob` с `origin=proxy`.

Если `effective_sync_wait` больше нуля, фрагмент **opt** включает ожидание. Фрагмент **par** показывает, что в это же время воркер делает своё: `claim_queued_scan`, `process_job`, `download_to`, `run_all`. Фрагмент **loop** — по одному `scan` на каждый включённый сканер. `worst` выбирает самый строгий итог: `PASS` ставит `available`, `FAIL` вызывает `sync_findings` и ставит `blocked`, `ERROR` ставит `quarantine`.

Потом `decision_for_get`. Фрагмент **alt**: либо `stream_blob` и байты клиенту, либо карточка блокировки без файла.

Диаграмма классов, заметка: <<boundary>> принимает запрос, <<control>> выполняет шаг, <<entity>> хранит данные

## BPMN 2.0

- `bpmn/diagram.bpmn`: процесс «Скачать артефакт» на уровне ролей и шагов.
- `bpmn/methods.bpmn` и `bpmn/methods.svg`: тот же процесс на уровне методов. Каждая дорожка — класс с диаграммы 1.3, каждая задача — вызов его метода, как в диаграмме 1.4. Пересобрать: `python3 bpmn/render_methods.py`. Файл открывается в Camunda Modeler или на [demo.bpmn.io](https://demo.bpmn.io).
