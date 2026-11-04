// Claude Code のステータスライン(Node)。settings.shared.json の statusLine から呼ばれる。
// stdin で受け取るセッションの JSON から 2 行出す:
//   1 行目: ディレクトリ・git・model・effort・advisor・output style
//   2 行目: コンテキスト・5h/7d・コスト
// 環境変数 STATUSLINE_USAGE_FILE があれば rate_limits をそのファイルにも書く(別のセッションが使用量を読むため)
import { spawnSync } from 'node:child_process'
import { closeSync, fstatSync, openSync, readFileSync, readSync, renameSync, writeFileSync } from 'node:fs'
import { basename } from 'node:path'

const s = JSON.parse(readFileSync(0, 'utf8').trim() || '{}')

const color = (code, text) => `\x1b[${code}m${text}\x1b[0m`
const dim = text => color(2, text)
// 256 色で指定し、テーマの紫や黄が暗くても暗い背景で読めるようにする
const fg = (n, text) => color(`38;5;${n}`, text)
const SEP = dim(' │ ')

// 天気はトークンウェザーと同じ閾値
const weather = p => (p < 25 ? '☀' : p < 50 ? '☁' : p < 75 ? '☂' : p < 90 ? '☇' : '↯')
const kTokens = n =>
  n >= 1_000_000
    ? `${+(n / 1_000_000).toFixed(1)}M`
    : n >= 1000
      ? `${(n / 1000).toFixed(n >= 100000 ? 0 : 1)}k`
      : `${n}`
const hhmm = epoch => {
  const d = new Date(epoch * 1000)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

// ブランチ・未コミット数・ahead/behind は stdin に無いので git に聞く
function git(cwd) {
  const r = spawnSync('git', ['-C', cwd, 'status', '--porcelain=v2', '--branch'], { encoding: 'utf8', timeout: 1000 })
  if (r.status !== 0) return undefined
  const lines = r.stdout.split('\n').filter(Boolean)
  const header = key => lines.find(l => l.startsWith(`# branch.${key} `))?.slice(`# branch.${key} `.length)
  const head = header('head')
  const [ahead = 0, behind = 0] = (header('ab') ?? '').match(/\d+/g)?.map(Number) ?? []
  const parts = [fg(141, head === '(detached)' ? header('oid').slice(0, 7) : head)]
  const changed = lines.filter(l => !l.startsWith('#')).length
  if (changed) parts.push(fg(221, `●${changed}`))
  if (ahead || behind) parts.push(fg(117, `${ahead ? `↑${ahead}` : ''}${behind ? `↓${behind}` : ''}`))
  return parts.join(' ')
}

// advisor は stdin に無いので transcript を見る。最後の返答の行に advisorModel があれば使っている。
// 長いセッションでも重くならないよう末尾だけ読む
function advisor(path) {
  if (!path) return undefined
  try {
    const fd = openSync(path, 'r')
    const size = fstatSync(fd).size
    const buf = Buffer.alloc(Math.min(size, 256 * 1024))
    readSync(fd, buf, 0, buf.length, size - buf.length)
    closeSync(fd)
    for (const line of buf.toString('utf8').split('\n').reverse()) {
      if (!line.includes('"type":"assistant"')) continue
      try {
        const id = JSON.parse(line).advisorModel
        return id ? `advisor ${id.match(/^claude-([a-z]+)/)?.[1] ?? id}` : undefined
      } catch {}
    }
  } catch {}
  return undefined
}

const cwd = s.workspace?.current_dir ?? s.cwd ?? process.cwd()
const first = [[color(1, basename(cwd)), git(cwd)].filter(Boolean).join('  ')]
first.push([s.model?.display_name, s.effort?.level, advisor(s.transcript_path)].filter(Boolean).join(dim(' · ')))
if (s.output_style?.name && s.output_style.name !== 'default') first.push(s.output_style.name)

const second = []
const ctx = s.context_window
if (ctx?.used_percentage != null) {
  const u = ctx.current_usage
  const tokens = u
    ? u.input_tokens + u.cache_creation_input_tokens + u.cache_read_input_tokens
    : Math.round((ctx.used_percentage / 100) * ctx.context_window_size)
  const p = Math.round(ctx.used_percentage)
  second.push(`${weather(p)} ${p}% ${kTokens(tokens)}/${kTokens(ctx.context_window_size)}`)
}
const five = s.rate_limits?.five_hour
const seven = s.rate_limits?.seven_day
if (five) second.push(`5h ${Math.round(five.used_percentage)}%${five.resets_at ? `→${hhmm(five.resets_at)}` : ''}`)
if (seven) second.push(`7d ${Math.round(seven.used_percentage)}%`)
if (s.cost?.total_cost_usd) second.push(`$${s.cost.total_cost_usd.toFixed(2)}`)

console.log(first.filter(Boolean).join(SEP))
if (second.length) console.log(second.join(SEP))

const usageFile = process.env.STATUSLINE_USAGE_FILE
if (usageFile && s.rate_limits) {
  try {
    writeFileSync(usageFile + '.tmp', JSON.stringify({ at: new Date().toISOString(), ...s.rate_limits }))
    renameSync(usageFile + '.tmp', usageFile)
  } catch {}
}
