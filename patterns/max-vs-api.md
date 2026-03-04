# Max Plan vs API : quand c'est rentable ?

## Notre analyse (février 2026)

### Données
- Janvier 2026 : $12.29 en équivalent API (usage léger, Haiku + Sonnet)
- Février 2026 (15 jours) : $73.35 (usage intensif, Opus + Sonnet + Haiku)
- Projection février : ~$137

### Verdict
- **Usage léger** (< $50/mois equiv. API) : l'API est moins chère
- **Usage intensif** (> $200/mois equiv. API) : Max est rentable (breakeven sur le plan $200/mo)
- **Point de bascule** : quand on passe à Opus et qu'on utilise les subagents/sessions parallèles

### Facteurs qui font grimper l'usage
- Modèle Opus (le plus cher en tokens)
- Sessions longues (> 30 min)
- Subagents parallèles
- Extended thinking activé
- Sessions de travail quotidiennes

### Outil de suivi
`npx ccusage monthly` pour voir l'usage mensuel en équivalent API.
`npx ccusage daily` pour le détail jour par jour.
