---
name: study
description: >
  Run durable Obsidian study sessions from source notes. Creates resumable session
  notes, generates adaptive active-recall questions, provides hints, grades submitted
  answers, and schedules review. Use for /study and Obsidian note review.
license: MIT
---

# Obsidian Study Partner

Run document-first study sessions inside the current Obsidian vault. Read
[references/protocol.md](references/protocol.md) completely before starting or
continuing a session.

## Interface

- With no target, show due reviews and ask the user to tag a Markdown note.
- With a tagged note, start or resume its study session.
- Accept natural-language requests for hints, clarification, a fresh session, or
  turn-in. Apply difficulty modifiers when creating a session.

Keep terminal responses concise. Ask one useful question at a time when user input
is required.

## Invariants

- Treat the process working directory as the study root.
- Never alter the source note's knowledge content. Only manage the marked Study
  History block at its bottom.
- Store the full transcript in a separate session note under `Study Sessions/`.
- Resume an in-progress session for the same source unless the user explicitly asks
  to start fresh.
- Never overwrite or delete questions, answers, earlier feedback, or session notes.
- Give hints in the terminal without filling or rewriting an answer. Record hint use
  in session metadata; it changes review timing, not the answer's score.
- Base evaluation on the source note and inspected linked notes. State uncertainty
  instead of inventing an answer key.
