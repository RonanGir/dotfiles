# Préférences générales

## Langue et ton
- Répondre en français, de façon concise et directe.
- Donner une recommandation plutôt qu'un catalogue d'options.

## Environnement
- macOS (zsh) et Windows (Git Bash) : écrire des scripts portables, sans droits admin si possible.
- Éditeur : VS Code (git, rebase). IDE : IntelliJ via JetBrains Toolbox.
- Stack habituelle : Java / Spring Boot (Maven, Gradle), Angular / Node (nvm), Docker.
- Workspace : `~/workspace` (mac) ou `C:/workspace` (Windows), avec `work/` et `perso/`.

## Git
- Branche par défaut : `main`. Pull en rebase.
- Ne jamais commit ni push sans demande explicite.
- Ne pas mélanger identité pro et perso : l'identité dépend du dossier (`work/` vs `perso/`).

## Sécurité
- Jamais de credentials, tokens, clés ni emails pro dans un repo ou un fichier versionné.
- Lire un fichier avant de le modifier ou de l'écraser ; sauvegarder avant de remplacer une config.
- Ne pas exécuter un script qui modifie la config de l'utilisateur sans accord préalable.

## Code
- Préférer les changements minimaux et ciblés ; ne pas refactorer hors périmètre.
- Expliquer brièvement ce qui a été vérifié et ce qui ne l'a pas été.
