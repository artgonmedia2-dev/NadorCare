@php
    $icons = [
        'shield' => '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
        'file' => '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4M9 13h6M9 17h4"/>',
        'clock' => '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
        'check' => '<path d="M20 6 9 17l-5-5"/>',
    ];
@endphp
<x-filament-widgets::widget>
    <x-filament::section :heading="__('admin.dashboard.watch.title')">
        <div class="nc-list">
            @forelse ($items as $item)
                <a href="{{ $item['url'] }}" class="nc-item">
                    <span class="nc-pict nc-pict-{{ $item['tone'] }}"><svg viewBox="0 0 24 24" aria-hidden="true">{!! $icons[$item['icon']] !!}</svg></span>
                    <span class="nc-item-body">
                        <span class="nc-item-title">{{ $item['title'] }}</span>
                        <span class="nc-item-sub">{{ $item['hint'] }}</span>
                    </span>
                </a>
            @empty
                <div class="nc-item">
                    <span class="nc-pict nc-pict-success"><svg viewBox="0 0 24 24" aria-hidden="true">{!! $icons['check'] !!}</svg></span>
                    <span class="nc-item-body"><span class="nc-item-title">{{ __('admin.dashboard.watch.nothing') }}</span></span>
                </div>
            @endforelse
        </div>
    </x-filament::section>
</x-filament-widgets::widget>
