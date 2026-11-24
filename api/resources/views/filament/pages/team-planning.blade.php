<x-filament-panels::page>
    @php
        $locale = app()->getLocale();
        $initials = function (string $name): string {
            $parts = array_values(array_filter(preg_split('/\s+/u', trim($name)) ?: [], fn ($p) => $p !== '' && mb_strtolower($p) !== 'dr'));
            $letters = array_map(fn ($p) => mb_strtoupper(mb_substr($p, 0, 1)), array_slice($parts, 0, 2));

            return $letters === [] ? '—' : implode('', $letters);
        };
    @endphp

    <div class="nc-legend">
        <span><i style="background:#eaf1ef"></i>{{ __('admin.planning.legend_hours') }}</span>
        <span><i style="background:#d5f2ec;box-shadow:inset 3px 0 0 #0f766e"></i>{{ __('admin.planning.legend_mission') }}</span>
        <span><i style="background:#fef0c7;box-shadow:inset 3px 0 0 #92400e"></i>{{ __('admin.planning.legend_pending') }}</span>
        <span><i style="background:#fde8e6;box-shadow:inset 3px 0 0 #b42318"></i>{{ __('admin.planning.legend_off') }}</span>
    </div>

    <x-filament::section>
        <x-slot name="heading">
            {{ __('admin.planning.week_of', ['date' => $days[0]->locale($locale)->isoFormat('LL')]) }}
        </x-slot>

        @if ($rows === [])
            <p class="nc-empty">{{ __('admin.planning.empty') }}</p>
        @else
            <div style="overflow-x: auto;">
                <table class="nc-planning">
                    <thead>
                        <tr>
                            <th scope="col" style="min-width: 13rem;">{{ __('admin.planning.caregiver') }}</th>
                            @foreach ($days as $day)
                                <th scope="col" @class(['nc-today' => $day->format('Y-m-d') === $today])>
                                    {{ ucfirst($day->locale($locale)->isoFormat('ddd')) }}
                                    <span class="nc-day-num" dir="ltr">{{ $day->format('j') }}</span>
                                </th>
                            @endforeach
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($rows as $row)
                            <tr wire:key="planning-{{ $row['id'] }}">
                                <th scope="row">
                                    <div class="nc-who">
                                        <span class="nc-avatar">{{ $initials($row['name']) }}</span>
                                        <div>
                                            <a href="{{ \App\Filament\Resources\Professionals\ProfessionalResource::getUrl('view', ['record' => $row['id']]) }}" class="nc-item-title">
                                                {{ $row['name'] !== '' ? $row['name'] : '—' }}
                                            </a>
                                            <div class="nc-item-sub">{{ $row['category'] }}</div>
                                            @if ($row['zones'] !== [])
                                                <div class="nc-item-sub">{{ implode(', ', $row['zones']) }}</div>
                                            @endif
                                        </div>
                                    </div>
                                </th>
                                @foreach ($row['days'] as $date => $cell)
                                    <td @class(['nc-today' => $date === $today])>
                                        @if ($cell['off'])
                                            <span class="nc-slot nc-slot-off"><b>{{ __('admin.planning.off') }}</b></span>
                                        @elseif ($cell['hours'] === [])
                                            <span style="color: #a4b2af;">{{ __('admin.planning.not_working') }}</span>
                                        @else
                                            @foreach ($cell['hours'] as $hours)
                                                <span class="nc-slot nc-slot-hours" dir="ltr" style="text-align: start;">{{ $hours }}</span>
                                            @endforeach
                                        @endif

                                        @foreach ($cell['missions'] as $mission)
                                            <span @class(['nc-slot', 'nc-slot-pending' => $mission['awaiting'], 'nc-slot-mission' => ! $mission['awaiting']])>
                                                <b dir="ltr" style="text-align: start;">{{ $mission['time'] }}</b>
                                                {{ $mission['service'] }}
                                                @if ($mission['zone'])
                                                    · {{ $mission['zone'] }}
                                                @endif
                                                <br>{{ $mission['awaiting'] ? __('admin.bookings.assignment.waiting') : __('admin.bookings.statuses.'.$mission['status']) }}
                                            </span>
                                        @endforeach
                                    </td>
                                @endforeach
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </x-filament::section>
</x-filament-panels::page>
