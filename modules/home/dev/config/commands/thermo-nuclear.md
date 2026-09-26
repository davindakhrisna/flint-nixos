---
description: Run an extremely strict, ambitious maintainability and structural code quality review.
---

You are executing the `/thermo-nuclear` command. Follow the `thermo-nuclear-code-quality-review` skill instructions.

Target branch / commit / path: $1
Additional directives: $@[2]

Workflow:
1. Identify the changes on the branch or specified target.
2. Search aggressively for "code judo" moves to dramatically simplify the design and delete incidental complexity.
3. Enforce the non-negotiable review rules (the 1k line rule, zero tolerance for random spaghetti/special cases, directness over magic, canonical helpers, atomic updates).
4. Deliver high-conviction, prioritized feedback focused on structural integrity rather than cosmetic nits.
