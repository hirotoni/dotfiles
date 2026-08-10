
<!-- BACKLOG.MD GUIDELINES START -->
<!-- backlog.md-instructions-version: 1.48.0 -->
<CRITICAL_INSTRUCTION>

## Backlog.md Workflow

This project uses Backlog.md for task and project management.

**For every user request in this project, run `backlog instructions overview` before answering or taking action.**

Use the overview to decide whether to search, read, create, or update Backlog tasks.

Before task lifecycle actions, read the matching detailed guide:
- `backlog instructions task-creation` before creating or splitting tasks
- `backlog instructions task-execution` before planning, changing status or assignee, adding a plan or implementation notes, or implementing task work
- `backlog instructions task-finalization` before checking acceptance criteria, writing final summaries, or moving tasks to terminal statuses

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

</CRITICAL_INSTRUCTION>
<!-- BACKLOG.MD GUIDELINES END -->

## コードコメントの方針

この節は backlog.md の管理ブロックの外にある。`backlog` CLI が上のブロックを
再生成しても消えない位置に置いてある。移動しないこと。

コードコメントは既定で書かない。次のどれかに当てはまるときだけ書く。

- コードからは読み取れない外部の制約を記録するとき。他のツールの挙動、OS や
  ハードウェアの差、ライブラリのバグへの回避策など
- なぜその書き方にしたかを記録するとき。特に、素直な書き方をあえて避けた理由
- コード上に現れないファイル間の依存を記録するとき。読み込み順や、別ファイルの
  設定に依存していることなど

次のコメントは書かない。既にあるものは見つけしだい削除してよい。

- 直下のコードを言い換えただけのもの（`-- lsp`、`# ls`、`-- auto-format on save`）
- 識別子・オプション名・ファイル名・パッケージの URL から用途が読み取れる見出し
- 何をしているかを述べるだけで、なぜそうしたかを書いていないもの

迷ったら、そのコメントを消してもコードだけで同じ結論に辿り着けるかで決める。
辿り着けるなら消す。それでも決まらないなら残し、判断が必要な点として報告する。

コメントを残すときは、記述が失効していないか確認する。参照先のパスや関数名は
リファクタで変わる。現状と食い違うコメントは、無いより悪い。

コメントを削除する変更では、コメント以外を 1 文字も変えない。
