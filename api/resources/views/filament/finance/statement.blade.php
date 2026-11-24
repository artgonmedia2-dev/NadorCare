@php
    $money = fn (int $centimes) => \App\Filament\Resources\CaregiverAccounts\CaregiverAccountResource::money($centimes);
    $border = '1px solid rgb(229 231 235)';
    $cell = 'padding: 0.375rem 0.5rem; border-bottom: '.$border.';';
@endphp

<div style="display: grid; gap: 1.25rem; font-size: 0.875rem;">
    <dl style="display: grid; grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr)); gap: 0.75rem;">
        @foreach ([
            'missions_value' => $money($summary['missions_value']),
            'collected' => $money($summary['collected']),
            'uncollected' => $money($summary['uncollected']),
            'handed_over' => $money($summary['handed_over']),
            'balance' => $money($summary['balance']),
            'remuneration' => $summary['remuneration'] === null ? __('admin.finance.not_set') : $money($summary['remuneration']),
        ] as $key => $value)
            <div style="padding: 0.5rem 0.75rem; border: {{ $border }}; border-radius: 0.5rem;">
                <dt style="color: rgb(75 85 99);">{{ __('admin.finance.'.$key) }}</dt>
                <dd dir="ltr" style="font-weight: 600; font-size: 1rem; text-align: start; unicode-bidi: isolate;">{{ $value }}</dd>
            </div>
        @endforeach
    </dl>

    <section>
        <h3 style="font-weight: 600; margin-bottom: 0.375rem;">
            {{ __('admin.finance.missions') }} ({{ count($missions) }})
        </h3>
        @if ($missions === [])
            <p style="color: rgb(75 85 99);">{{ __('admin.finance.no_mission') }}</p>
        @else
            <div style="overflow-x: auto;">
                <table style="width: 100%; border-collapse: collapse;">
                    <thead>
                        <tr>
                            <th scope="col" style="text-align: start; {{ $cell }}">{{ __('admin.finance.date') }}</th>
                            <th scope="col" style="text-align: start; {{ $cell }}">{{ __('admin.bookings.reference') }}</th>
                            <th scope="col" style="text-align: start; {{ $cell }}">{{ __('admin.bookings.service') }}</th>
                            <th scope="col" style="text-align: end; {{ $cell }}">{{ __('admin.finance.amount') }}</th>
                            <th scope="col" style="text-align: start; {{ $cell }}">{{ __('admin.finance.payment') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($missions as $mission)
                            <tr>
                                <td dir="ltr" style="text-align: start; {{ $cell }}">{{ $mission['date'] }} {{ $mission['time'] }}</td>
                                <td dir="ltr" style="text-align: start; {{ $cell }}">{{ $mission['reference'] }}</td>
                                <td style="{{ $cell }}">{{ $mission['service'] }}</td>
                                <td dir="ltr" style="text-align: end; {{ $cell }}">{{ $money($mission['amount']) }}</td>
                                <td style="{{ $cell }}">{{ __('admin.finance.payments.'.$mission['payment']) }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </section>

    <section>
        <h3 style="font-weight: 600; margin-bottom: 0.375rem;">{{ __('admin.finance.handovers') }}</h3>
        @if ($handovers === [])
            <p style="color: rgb(75 85 99);">{{ __('admin.finance.no_handover') }}</p>
        @else
            <table style="width: 100%; border-collapse: collapse;">
                <tbody>
                    @foreach ($handovers as $handover)
                        <tr>
                            <td dir="ltr" style="text-align: start; {{ $cell }}">{{ $handover['date'] }}</td>
                            <td dir="ltr" style="text-align: end; {{ $cell }}">{{ $money($handover['amount']) }}</td>
                            <td style="{{ $cell }}">{{ $handover['note'] }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        @endif
    </section>
</div>
