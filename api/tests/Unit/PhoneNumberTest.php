<?php

namespace Tests\Unit;

use App\Support\PhoneNumber;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

class PhoneNumberTest extends TestCase
{
    #[DataProvider('validNumbers')]
    public function test_it_normalises_valid_numbers(string $input, string $expected): void
    {
        $this->assertSame($expected, PhoneNumber::normalize($input));
    }

    public static function validNumbers(): array
    {
        return [
            'local mobile' => ['0612345678', '+212612345678'],
            'local avec espaces' => ['06 12 34 56 78', '+212612345678'],
            'local fixe' => ['0536123456', '+212536123456'],
            'international' => ['+212712345678', '+212712345678'],
            'préfixe 00' => ['00212612345678', '+212612345678'],
            'zéro en trop' => ['+2120612345678', '+212612345678'],
            'diaspora France' => ['+33612345678', '+33612345678'],
            'diaspora Espagne' => ['+34 612 34 56 78', '+34612345678'],
            'diaspora Pays-Bas' => ['+31-6-12345678', '+31612345678'],
        ];
    }

    #[DataProvider('invalidNumbers')]
    public function test_it_rejects_invalid_numbers(?string $input): void
    {
        $this->assertNull(PhoneNumber::normalize($input));
    }

    public static function invalidNumbers(): array
    {
        return [
            'vide' => [''],
            'nul' => [null],
            'trop court' => ['12345'],
            'lettres' => ['06abc45678'],
            'étranger sans indicatif' => ['612345678'],
            'marocain trop court' => ['+21261234567'],
            'marocain mauvais préfixe' => ['+212112345678'],
            'trop long' => ['+1234567890123456'],
        ];
    }

    public function test_it_masks_a_number_for_logs(): void
    {
        $masked = PhoneNumber::mask('+212612345678');

        $this->assertStringStartsWith('+2126', $masked);
        $this->assertStringEndsWith('678', $masked);
        $this->assertStringNotContainsString('12345', $masked);
    }
}
