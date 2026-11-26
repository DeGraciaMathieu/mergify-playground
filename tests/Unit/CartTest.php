<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Cart;
use PHPUnit\Framework\TestCase;

final class CartTest extends TestCase
{
    public function test_an_empty_cart_costs_nothing(): void
    {
        $this->assertSame(0, (new Cart())->subtotal());
    }

    public function test_the_total_sums_every_line(): void
    {
        $cart = (new Cart())
            ->add('Clavier', 4990)
            ->add('Câble', 790, 2);

        $this->assertSame(6570, $cart->subtotal());
        $this->assertSame(3, $cart->count());
    }
}
