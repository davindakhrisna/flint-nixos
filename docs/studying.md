# Studying with OhMyPi

Run:

```bash
omp-study
```

The first run asks for an Obsidian vault and stores that path in
`$XDG_CONFIG_HOME/omp-study/vault`. Change it with `omp-study --set-vault`.

OhMyPi opens in the vault, starts `/study`, shows unfinished and due reviews, and
waits for a tagged Markdown note. It creates five adaptive questions in a separate
session note. Answer them in Obsidian, then ask OhMyPi for a hint or say `turn in`.

Sessions live under `Study Sessions/<source path>/`. The source note receives a
managed, collapsible embed at its bottom. Completed sessions retain their questions,
answers, feedback, score, and next review date. Unfinished sessions resume
automatically.
