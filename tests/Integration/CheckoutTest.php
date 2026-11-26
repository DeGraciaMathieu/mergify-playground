<?php

declare(strict_types=1);

namespace Tests\Integration;

use App\Cart;
use App\Shipping;
use PHPUnit\Framework\TestCase;

/**
 * Tests « lents » : ils ne tournent que dans la merge queue.
 * Le sleep simule une vraie suite d'intégration, pour que la file ait le temps de se remplir.
 */
final class CheckoutTest extends TestCase
{
    protected function setUp(): void
    {
        sleep((int) (getenv('SLOW_TESTS_SECONDS') ?: 0));
    }

    public function test_a_small_order_pays_shipping(): void
    {
        $cart = (new Cart())->add('Câble', 790);

        $this->assertSame(490, (new Shipping())->cost($cart));
    }

    public function test_shipping_is_free_from_fifty_euros(): void
    {
        $cart = (new Cart())->add('Clavier', 4990)->add('Câble', 790);

        $this->assertSame(0, (new Shipping())->cost($cart));
    }
}
