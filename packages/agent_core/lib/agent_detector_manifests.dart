/// Manifiestos portados de herdr (Apache-2.0) — subset plano de opencode.toml.
/// Fuente original: https://github.com/herdrdev/herdr `src/detect/manifests/opencode.toml`
/// (reglas permission_required / interrupt_hint_working / progress_bar_working,
/// aplanadas a matchers contains/regex/line_regex por nuestra API).
const String opencodeManifestToml = '''
[rule.permission_required]
state = "blocked"
priority = 300
contains = ["? Permission required", "password:", "permission required"]

[rule.interrupt_hint_working]
state = "working"
priority = 110
contains = ["esc to interrupt", "ctrl+c to interrupt", "press esc to interrupt"]
line_regex = ["(?i).*opencode.*esc (again to )?interrupt"]

[rule.waiting_user_input]
state = "idle"
priority = 90
contains = ["waiting for user input", "esc to cancel", "esc to dismiss"]
''';
