#!/usr/bin/env bash
# Scénario 1 — deux PR vertes séparément, rouges ensemble.
#   A renomme Cart::total() en Cart::subtotal().
#   B ajoute une classe Invoice qui appelle encore Cart::total().
# Aucun conflit git, chaque CI est verte… et main casse si on merge les deux.
#
# Usage :
#   ./scripts/01-conflit-semantique.sh --sans-queue   # merge direct : main devient rouge
#   ./scripts/01-conflit-semantique.sh                # via Mergify : B est éjectée, main reste vert
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mode="${1:-queue}"
preflight

if [[ -e src/Invoice.php ]]; then
    echo "src/Invoice.php existe déjà sur main : supprime-le (ou lance reparer-main.sh) avant de rejouer."
    exit 1
fi

# Le scénario peut être rejoué : on renomme dans un sens ou dans l'autre selon l'état de main.
if grep -q 'function total()' src/Cart.php; then
    old=total new=subtotal
else
    old=subtotal new=total
fi

say "PR A : renommer $old() en $new()"
new_branch "demo/$STAMP-renommer-$old"
perl -pi -e "s/\\b$old\\(\\)/$new()/g" src/Cart.php src/Shipping.php tests/Unit/CartTest.php
pr_a="$(commit_and_open_pr "Renomme Cart::$old() en $new()")"
note "PR #$pr_a"

say "PR B : ajouter une facture qui utilise $old()"
new_branch "demo/$STAMP-ajout-facture"
cat > src/Invoice.php <<PHP
<?php

declare(strict_types=1);

namespace App;

final class Invoice
{
    public function __construct(
        private readonly Cart \$cart,
        private readonly Shipping \$shipping = new Shipping(),
    ) {
    }

    public function amountDue(): int
    {
        return \$this->cart->$old() + \$this->shipping->cost(\$this->cart);
    }
}
PHP
cat > tests/Unit/InvoiceTest.php <<'PHP'
<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Cart;
use App\Invoice;
use PHPUnit\Framework\TestCase;

final class InvoiceTest extends TestCase
{
    public function test_the_amount_due_includes_shipping(): void
    {
        $invoice = new Invoice((new Cart())->add('Câble', 790));

        $this->assertSame(1280, $invoice->amountDue());
    }
}
PHP
pr_b="$(commit_and_open_pr "Ajoute le calcul du montant de facture")"
note "PR #$pr_b"

say "Attente de la CI des deux PR (chacune testée seule)"
wait_for_check "$pr_a" preliminary-tests
wait_for_check "$pr_b" preliminary-tests
note "Les deux PR sont vertes. Aucune ne voit l'autre."

if [[ "$mode" == "--sans-queue" ]]; then
    say "Merge direct, sans merge queue"
    gh pr merge "$pr_a" --squash --delete-branch >/dev/null
    gh pr merge "$pr_b" --squash --delete-branch >/dev/null
    note "Les deux PR sont mergées. Regarde la CI de main : elle va passer au rouge."
    note "$(repo_url)/actions?query=branch%3Amain"
    note "Pour réparer main ensuite : ./scripts/reparer-main.sh"
else
    say "Mise en file via Mergify (A puis B)"
    queue "$pr_a"
    queue "$pr_b"
    note "Mergify teste A+B ensemble sur une branche mergify/merge-queue/…"
    note "Le batch casse, Mergify le découpe, éjecte B et merge A. main reste vert."
    note "Suis ça sur https://dashboard.mergify.com et dans l'onglet Pull requests (draft PR)."
fi
