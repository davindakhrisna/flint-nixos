# Study Protocol

## Opening

Treat the current working directory as the study root. If the user launched `/study`
elsewhere by mistake, tell them to restart with `omp-study`.

When no note is selected:

1. Scan `Study Sessions/**/*.md` for `status: in-progress` and completed sessions
   whose `review_due` is today or earlier.
2. Show at most three in-progress and three due source notes, prioritizing the
   oldest due date.
3. Ask the user to tag a Markdown source note. Do not create files yet.

Treat an attached or tagged Markdown file as the source selection. Resolve it to a
vault-relative path and reject paths outside the vault or inside `Study Sessions/`.

## Start or Resume

Find sessions whose frontmatter `source_path` exactly matches the selected source.
If an in-progress session exists, open the newest one, summarize unanswered
questions, and resume it. Create a new session only when none exists or the user
asks to start fresh; a fresh start changes the old session to `status: archived`.
Also update the old session's source-note callout title to `Archived`.

For a new session:

1. Read the full source note, including frontmatter.
2. Resolve wikilinks from the source. Normalize aliases and headings such as
   `[[Note|Alias]]` and `[[Note#Heading]]`. Read no more than five linked notes,
   selecting those most relevant to dependencies, contrasts, and prior gaps.
3. Read earlier completed sessions for the source and identify weak or
   hint-assisted concepts.
4. Generate five questions by default. Mix direct recall, explanation, transfer,
   linked-concept synthesis, and a boundary or counterexample. Prioritize earlier
   gaps and vary previously used wording. Use three questions for `quick` and eight
   for `deep`; honor conversational difficulty requests.
5. Create the session note and add its managed embed to the source note.

Do not present a mode menu. Tell the user where the session note is and ask them to
answer there, then return to OhMyPi for hints or turn-in.

## Storage

For source `<source-path>.md`, store sessions at:

```text
Study Sessions/<source-path>/<YYYY-MM-DD-HHmmss>.md
```

Create this frontmatter:

```yaml
---
type: study-session
source: "[[<source-path>]]"
source_path: "<source-path>.md"
started: <ISO-8601 timestamp>
completed:
status: in-progress
score:
interval_days: 0
review_due:
hints_used: []
---
```

Write questions in this form:

```markdown
# Study Session: [[<source-path>]]

## Questions

> [!QUESTION] 1. <Short concept label>
> <Question>
>
> **Your answer:**
>
```

Add all session embeds at the absolute bottom of the source note inside one managed
block. Preserve everything outside the markers.

```markdown
<!-- omp-study:start -->
## Study History

> [!note]- <date> - In progress
> ![[Study Sessions/<source-path>/<timestamp>]]
<!-- omp-study:end -->
```

Insert later entries immediately before the end marker. On completion, update that
session's callout title with its score and next review date.

## Hints

For a hint request, re-read the relevant question and source context. Give one
progressive cue in the terminal: first point toward the governing concept, then a
relationship or constraint if asked again. Do not reveal the complete answer.
Immediately add the question number to the session's `hints_used` frontmatter so it
survives a resumed OhMyPi conversation. Do not write the hint itself into the note.

## Turn-in

On `turn in`, `submit`, or an equivalent request:

1. Re-read the session note from disk.
2. If any answer is blank, identify the unanswered question and do not grade yet.
3. Score every answer against the note evidence:
   - `0` - missing or incorrect
   - `1` - partial recall with a major gap
   - `2` - correct explanation
   - `3` - correct explanation with transfer, synthesis, or boundary awareness
4. Do not deduct points merely because a hint was used.
5. Compute `score` as the rounded percentage of earned points over available
   points.
6. Append a Results section containing the per-question score and one concise
   feedback sentence, strengths, gaps, hints used, and the next review date.
7. Update frontmatter to `status: complete`, set `completed`, `score`,
   `interval_days`, and `review_due`. Update the source embed title.

Choose the interval from the score and prior completed interval:

- Below 50: 1 day
- 50-69: 3 days
- 70-84: 7 days
- 85 or above with no prior interval: 14 days
- 85 or above thereafter: double the prior interval, capped at 90 days

If any question scored below 2 or used a hint, cap the interval at 7 days. This
changes scheduling, not the score.

End with the score, strongest concept, main gap, and next review date. Preserve the
entire session record.
