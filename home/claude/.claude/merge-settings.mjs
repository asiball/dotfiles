// Claude Code の settings.json に settings.shared*.json を合成して標準出力に出す(ファイルは書き換えない)。
//   node merge-settings.mjs <settings.json> [shared.json...]
// 同名キーはオブジェクトなら再帰的に合成、配列や値は shared 側で置き換える。settings.json が無ければ空として扱う。
// shared を渡さなければ整形だけするので、合成前後の比較(変更の有無)にも使う。
import { existsSync, readFileSync } from 'node:fs'

const read = path => (existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : {})
const isObject = v => v !== null && typeof v === 'object' && !Array.isArray(v)
const merge = (base, over) => {
  for (const [key, value] of Object.entries(over)) {
    base[key] = isObject(value) && isObject(base[key]) ? merge(base[key], value) : value
  }
  return base
}

const [settings, ...shared] = process.argv.slice(2)
process.stdout.write(JSON.stringify(shared.map(read).reduce(merge, read(settings)), null, 2) + '\n')
