# Structure CLAUDE.md

Notre CLAUDE.md global (`~/.claude/CLAUDE.md`) contient :

## Sections

### Identité
- Profil, pratiques, méthodologie
- Vision de l'IA (référence vers soul.md)

### Workflows obligatoires
- `/interview` avant tout projet dev (20-30 questions techniques)
- `/pitch` avant tout projet créatif (15-25 questions créatives)
- Plan mode (Shift+Tab x2) pour l'implémentation

### Règles de qualité (7 règles)
1. **Anti-hallucination** : jamais de données simulées
2. **Retour plan mode** : si un fix échoue, STOP et re-plan
3. **Scrap and redo** : repartir de zéro > patcher
4. **Self-update** : mettre à jour ses propres règles après chaque erreur
5. **Subagents** : utiliser des sous-agents pour les taches complexes
6. **Vérification** : toujours vérifier son travail avant de dire "c'est fait"
7. **Mode confrontation** : challenger les choix, pas juste exécuter

## Fichiers complémentaires
- `soul.md` : philosophie et personnalité de l'agent
- `MEMORY.md` : mémoire persistante entre sessions
- `memory/YYYY-MM-DD.md` : logs quotidiens

## Source
Règles construites itérativement depuis janvier 2026, inspirées de :
- Boris Cherny (créateur de Claude Code) - tips de l'équipe CC
- gmoney.eth - 25 lessons thread (fév 2026)
- Trail of Bits - opinionated config pour audits sécu
