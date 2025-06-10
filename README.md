# Reverse Shell en Assembleur x86-64

Ce projet est un reverse shell codé entièrement en assembleur 64 bits, qui se connecte automatiquement à une machine distante et ouvre un shell `/bin/sh` à travers cette connexion réseau.

---

## Fonctionnalités

- Connexion sortante vers une machine attaquante (IP/port donnés par l’utilisateur)
- Ouverture d’un shell `/bin/sh` via la connexion
- Lecture de l’IP et du port depuis l'entrée standard (`stdin`)
- Tentatives de reconnexion toutes les 5 secondes si l’attaquant n’est pas disponible
- Affichage d’un petit message de bienvenue une fois connecté

---

## Compilation

Pour compiler le programme :

```bash
nasm -f elf64 reverse_shell.asm -o reverse_shell.o
ld reverse_shell.o -o reverse_shell
```

---

## Utilisation

Sur la machine attaquante (listener) :

```bash
nc -lvnp 4444
```

Sur la machine victime :

```bash
./reverse_shell
```

On vous demandera de saisir l’adresse IP et le port de la machine à contacter.

---

## Détails techniques

Le programme utilise uniquement des appels systèmes (`syscall`), sans aucune fonction de la libc.  
L'IP et le port sont parsés manuellement, convertis, puis insérés dans une structure `sockaddr_in`.  
Une boucle de reconnexion est prévue si la machine attaquante n’est pas en écoute.

---

## Bonus ajoutés

- Lecture dynamique de l’IP/port depuis l’entrée standard
- Bannière en couleur affichée à la connexion
- Gestion simple des erreurs + reconnexion automatique

---

## À améliorer (futures idées)

- Ajouter la possibilité de lire un fichier `config.txt` en option
- Générer une version shellcode sans nullbytes
- Ajouter la prise en charge de variables d’environnement (pour `execve`)
- Rendre le shell plus interactif (terminal propre, etc.)

---

## Attention

Ce projet est à but uniquement éducatif.  
Il ne doit pas être utilisé sur des systèmes que vous ne possédez pas ou sans autorisation.
