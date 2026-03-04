# Settings expliqués

Notre `~/.claude/settings.json` et pourquoi chaque choix.

## Privacy
```json
"env": {
  "DISABLE_TELEMETRY": "1",
  "DISABLE_ERROR_REPORTING": "1",
  "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1"
}
```
Inspiré de Trail of Bits. Claude Code fonctionne pareil, mais n'envoie plus de données d'usage à Anthropic.

## Agent Teams
```json
"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
```
Active les équipes d'agents (subagents en parallèle).

## Deny rules (minimalistes)

### Philosophie
On bloque seulement les commandes **irréversibles** qu'aucun agent ne devrait jamais exécuter : formatage disque, exécution de scripts distants non vérifiés, force push, lecture de credentials système.

Tout le reste est géré par la séparation `claude` (avec permissions interactives) vs `clauded` (bypass) pour le controle quotidien.

## Statusline
```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/scripts/statusline.sh"
}
```
Affiche : [Modèle] dossier | branche + barre contexte % | $cout | durée | cache% | +lignes/-lignes

## Historique
```json
"cleanupPeriodDays": 365
```
Garde les conversations 1 an au lieu de 30 jours par défaut.

## Thinking
```json
"alwaysThinkingEnabled": true
```
Extended thinking activé en permanence pour de meilleures réponses.
