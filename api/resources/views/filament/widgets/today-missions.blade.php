<x-filament-widgets::widget>
    <x-filament::section :heading="__('admin.dashboard.today.title')">
        @if ($missions === [])
            <p class="nc-empty">{{ __('admin.dashboard.today.empty') }}</p>
        @else
            <div class="nc-list">
                @foreach ($missions as $mission)
                    <div class="nc-item">
                        <span class="nc-time" dir="ltr">{{ $mission['time'] }}</span>
                        <div class="nc-item-body">
                            <span class="nc-item-title">{{ $mission['who'] ?? __('admin.dashboard.today.to_assign') }}</span>
                            <span class="nc-item-sub">{{ $mission['what'] }}</span>
                            <div><x-filament::badge :color="$mission['color']">{{ $mission['label'] }}</x-filament::badge></div>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </x-filament::section>
</x-filament-widgets::widget>
