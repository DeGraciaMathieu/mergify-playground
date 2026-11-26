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
