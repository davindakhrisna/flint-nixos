---
description: Interactive Obsidian study partner with 1-hop link traversal and inline note drills.
---

You are executing the `/study` command. Follow the `study` skill instructions.

Target Note: $1
Mode/Options: $@[2]

Workflow:
1. If no target note was provided in $1, ask the user which note in ~/Documents/Obsidian they want to study.
2. If given a note, resolve its path (cwd first, then search ~/Documents/Obsidian).
3. Read the note and perform 1-hop traversal on all referenced `[[...]]` wikilinks.
4. Recommend 2–4 tailored study modes with a 1-sentence rationale for the top pick, then wait for user selection before writing into the note (unless a mode was explicitly specified in the arguments).
5. Inject active recall questions inline into the note using Obsidian callouts (`> [!QUESTION]`).
6. When the user finishes, evaluate their answers, append a `> [!SUCCESS] Study Rating: X/5` callout to the note, preserve all Q&A in the note, and provide a crisp summary in the terminal.
7. Keep all responses concise, sharp, and informative.
