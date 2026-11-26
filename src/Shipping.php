<?php

declare(strict_types=1);

namespace App;

final class Shipping
{
    public const FREE_SHIPPING_THRESHOLD = 50000;

    public const FLAT_RATE = 490;

    public function cost(Cart $cart): int
    {
        return $cart->total() >= self::FREE_SHIPPING_THRESHOLD ? 0 : self::FLAT_RATE;
    }
}
