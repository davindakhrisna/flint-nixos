# Studying in Obsidian

Open your AI coding assistant (e.g. Antigravity or Codex) within your Obsidian vault and run:

```text
/study
```

The agent opens the study session, shows unfinished and due reviews, and
waits for a tagged Markdown note. It creates five adaptive questions in a separate
session note. Answer them in Obsidian, then ask the agent for a hint or say `turn in`.

Sessions live under `Study Sessions/<source path>/`. The source note receives a
managed, collapsible embed at its bottom. Completed sessions retain their questions,
answers, feedback, score, and next review date. Unfinished sessions resume
automatically.
