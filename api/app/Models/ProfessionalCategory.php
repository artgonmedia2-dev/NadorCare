<?php

namespace App\Models;

use Database\Factories\ProfessionalCategoryFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @property string $id
 * @property string $code
 * @property array<string, string> $name
 * @property bool $has_order
 * @property array<int|string, string>|null $required_document_types tableau JSON saisi dans le back-office, pas forcément indexé à partir de zéro
 */
class ProfessionalCategory extends Model
{
    /** @use HasFactory<ProfessionalCategoryFactory> */
    use HasFactory, HasUlids;

    protected $fillable = ['code', 'name', 'has_order', 'required_document_types', 'is_active'];

    protected function casts(): array
    {
        return [
            'name' => 'array',
            'has_order' => 'boolean',
            'required_document_types' => 'array',
            'is_active' => 'boolean',
        ];
    }
}
