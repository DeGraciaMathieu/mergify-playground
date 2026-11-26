<?php

declare(strict_types=1);

namespace App;

final class Cart
{
    /** @var list<array{name: string, price: int, quantity: int}> */
    private array $lines = [];

    public function add(string $name, int $priceInCents, int $quantity = 1): self
    {
        $this->lines[] = [
            'name' => $name,
            'price' => $priceInCents,
            'quantity' => $quantity,
        ];

        return $this;
    }

    public function subtotal(): int
    {
        return array_sum(array_map(
            fn (array $line): int => $line['price'] * $line['quantity'],
            $this->lines,
        ));
    }

    public function count(): int
    {
        return array_sum(array_column($this->lines, 'quantity'));
    }
}
