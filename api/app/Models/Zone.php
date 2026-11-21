<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

class Zone extends Model
{
    use HasUlids;

    protected $fillable = ['name', 'slug', 'is_active', 'sort'];

    // Le polygone n'est jamais chargé par défaut : il est lourd et ne sert qu'aux requêtes spatiales.
    protected $hidden = ['boundary'];

    protected function casts(): array
    {
        return [
            'name' => 'array',
            'is_active' => 'boolean',
        ];
    }
}
