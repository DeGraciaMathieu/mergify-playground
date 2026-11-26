<?php

declare(strict_types=1);

namespace App;

final class Invoice
{
    public function __construct(
        private readonly Cart $cart,
        private readonly Shipping $shipping = new Shipping(),
    ) {
    }

    public function amountDue(): int
    {
        return $this->cart->subtotal() + $this->shipping->cost($this->cart);
    }
}
