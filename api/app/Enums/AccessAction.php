<?php

namespace App\Enums;

enum AccessAction: string
{
    case View = 'view';
    case Download = 'download';
    case Create = 'create';
    case Update = 'update';
    case Export = 'export';
}
