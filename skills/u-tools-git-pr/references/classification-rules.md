# classification-rules — File-to-Group Classification (Step 2)

Reference for **Step 2** of `/u-tools-git-pr`. Defines the 5 rules used to classify each changed file into a logical group. Rules are evaluated **in order** — the first match wins.

## Rule 1: u-maker output directory structure

For files under `.u-maker/output/{app}/{phase}/{doc}/`:

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `output/{app}/plan/srs/` | `{app}-plan-srs` | {app} Plan SRS |
| `output/{app}/plan/ia.*` | `{app}-plan-ia` | {app} Plan IA |
| `output/{app}/design/erd/` | `{app}-design-erd` | {app} Design ERD |
| `output/{app}/design/api/` | `{app}-design-api` | {app} Design API |
| `output/{app}/design/screens/` | `{app}-design-screens` | {app} Design Screens |
| `output/{app}/design/design-system.*` | `{app}-design-ds` | {app} Design System |
| `output/{app}/gatekeeping/testcases/` | `{app}-gatekeeping-tc` | {app} Gatekeeping TestCases |
| `output/{app}/gatekeeping/test-results.*` | `{app}-gatekeeping-tr` | {app} Gatekeeping TestResults |
| `output/{app}/index.html` | `{app}-nav` | {app} Navigation |
| `output/index.html` | `root-nav` | Root Navigation |

## Rule 2: u-maker docs directory structure

For files under `.u-maker/docs/{app}/{phase}/`:

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `docs/{app}/plan/*` | `{app}-docs-plan` | {app} Plan Docs |
| `docs/{app}/design/*` | `{app}-docs-design` | {app} Design Docs |
| `docs/{app}/gatekeeping/*` | `{app}-docs-gatekeeping` | {app} Gatekeeping Docs |
| `docs/common/*` | `common-docs` | Common Docs |

## Rule 3: Source code by directory

For application source code:

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `src/app/**` or `app/**` | `app-{nearest-dir}` | App {NearestDir} |
| `src/components/**` | `components` | Components |
| `src/lib/**` or `lib/**` | `lib` | Library |
| `prisma/**` | `db-schema` | DB Schema |
| `src/api/**` or `api/**` | `api` | API |

## Rule 4: Config and CI

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `*.config.*`, `.*rc`, `package.json` | `config` | Config |
| `.github/**`, `.gitlab-ci*` | `ci` | CI/CD |

## Rule 5: Fallback

Files that don't match any pattern: group as `misc` (Miscellaneous).
