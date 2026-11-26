# Bac à sable Mergify

Un petit projet PHP pour **voir** ce que fait une merge queue, plutôt que de le lire.
Quatre scénarios scriptés ouvrent de vraies PR sur ton repo et les envoient dans la file Mergify.

## Mise en route

Prérequis : `gh` authentifié (`gh auth login`), `git`, `perl`.

```bash
./scripts/00-init.sh mergify-playground        # crée le repo (public par défaut) et pousse main
```

Ensuite, à la main :

1. Installe l'app Mergify sur ce repo : <https://github.com/apps/mergify>.
   Mergify est gratuit pour les projets open source, d'où le repo public par défaut.
2. Ne coche pas « Require branches to be up to date before merging » sur `main` : ça bloque les merges de batch.
3. Ouvre <https://dashboard.mergify.com> à côté : c'est là qu'on voit la file vivre.

## Le projet

- `src/Cart.php`, `src/Shipping.php` : un panier et des frais de port (gratuits dès 50 €).
- `tests/Unit` : tests rapides.
- `tests/Integration` : tests « lents » (un `sleep` de 45 s simule une vraie suite).

La CI est en deux étapes (`.github/workflows/ci.yml`) :

| Job | Quand | Contenu |
|---|---|---|
| `preliminary-tests` | à chaque push sur une PR | tests unitaires |
| `pre-merge-tests` | seulement sur les branches `mergify/merge-queue/…` (et sur `main`) | unitaires + intégration |

Et `.mergify.yml` fait le lien : une PR **entre** dans la file quand `preliminary-tests` passe,
elle n'est **mergée** qu'après `pre-merge-tests`, joué sur « main + les PR devant elle ».
Les batches font 3 PR, deux batches sont testés en parallèle, et le label `urgent` fait passer devant.

## Les scénarios

À lancer dans cet ordre, en laissant la file se vider entre deux scénarios.

| Script | Ce qu'il fait | Ce qu'on doit observer |
|---|---|---|
| `01-conflit-semantique.sh --sans-queue` | PR A renomme `Cart::total()`, PR B ajoute une facture qui l'appelle encore. Chacune est verte seule. Merge direct des deux. | La CI de `main` passe au rouge. Répare avec `./scripts/reparer-main.sh`. |
| `01-conflit-semantique.sh` | Les deux mêmes PR, cette fois via la file. | Mergify teste A+B ensemble, le batch casse, B est éjectée avec un commentaire, A est mergée. `main` reste vert. |
| `02-batch.sh [N]` | N PR inoffensives (6 par défaut) mises en file d'un coup. | Des draft PR de batch de 3 PR. Compte les runs `pre-merge-tests` dans l'onglet Actions : un par batch, pas un par PR. |
| `03-bisection.sh` | 5 PR, dont une qui monte discrètement le seuil de livraison gratuite. Les tests unitaires ne la voient pas. | Elle entre dans la file, son batch casse sur les tests d'intégration, Mergify passe en *bisecting*, l'éjecte, merge les 4 autres. |
| `04-priorite.sh` | 4 PR en file, puis un hotfix avec le label `urgent` 90 s plus tard. | Les checks en cours sont interrompus et le hotfix est mergé en premier. |

Le scénario 1 peut être rejoué : il renomme dans un sens ou dans l'autre selon l'état de `main`.

## Pour aller plus loin

Modifie `.mergify.yml` et rejoue `02-batch.sh` pour sentir les compromis :

- `batch_size: 1` : plus de batch, un run par PR. Ou `batch_size: {min: 1, max: 5}` pour une taille dynamique.
- `max_parallel_checks: 1` : la file redevient séquentielle, le débit s'effondre.
- `batch_max_wait_time` : plus long, des batches plus pleins et moins de CI ; plus court, des merges plus rapides.
- `SLOW_TESTS_SECONDS` dans le workflow : allonge la CI pour voir la file s'empiler.

En vrai, on ajouterait aussi un ruleset sur `main` (« Require status checks to pass » + Mergify en *bypass*)
pour que personne ne puisse cliquer sur Merge en contournant la file. Ici on s'en passe exprès,
pour que le mode `--sans-queue` du scénario 1 reste possible.

## Nettoyage

```bash
git ls-remote --heads origin 'demo/*' | awk '{print $2}' | sed 's#refs/heads/##' | xargs -r git push origin --delete
```

Il n'y a pas de `composer.lock` : la CI résout PHPUnit au premier `composer install`.
