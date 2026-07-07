<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>Visitor Log Report</title>
    <style>
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 11px;
            color: #111827;
        }
        .header {
            margin-bottom: 16px;
            border-bottom: 1px solid #d1d5db;
            padding-bottom: 10px;
        }
        .title {
            font-size: 18px;
            font-weight: bold;
            margin: 0;
        }
        .meta {
            margin-top: 4px;
            color: #4b5563;
            font-size: 10px;
        }
        .stats {
            margin: 10px 0 14px;
            width: 100%;
        }
        .stats td {
            border: 1px solid #d1d5db;
            padding: 6px 8px;
            width: 25%;
        }
        .filters {
            margin-bottom: 12px;
            font-size: 10px;
            color: #374151;
        }
        table.logs {
            width: 100%;
            border-collapse: collapse;
        }
        table.logs th,
        table.logs td {
            border: 1px solid #d1d5db;
            padding: 5px 6px;
            vertical-align: top;
        }
        table.logs th {
            background: #f3f4f6;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }
        .muted {
            color: #6b7280;
            font-size: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <p class="title">Visitor Log Detailed Report</p>
        <p class="meta">Generated at: {{ $generatedAt->format('d M Y, h:i A') }}</p>
    </div>

    <table class="stats">
        <tr>
            <td><strong>Total Logs:</strong> {{ number_format($stats['total_logs']) }}</td>
            <td><strong>Entries:</strong> {{ number_format($stats['entries']) }}</td>
            <td><strong>Exits:</strong> {{ number_format($stats['exits']) }}</td>
            <td><strong>Unique Visitors:</strong> {{ number_format($stats['unique_visitors']) }}</td>
        </tr>
    </table>

    <div class="filters">
        <strong>Applied Filters:</strong>
        Date {{ $filters['from_date'] ?: 'N/A' }} to {{ $filters['to_date'] ?: 'N/A' }} |
        Building {{ $filters['building_id'] ?: 'All' }} |
        Type {{ $filters['visitor_type'] ?: 'All' }} |
        Action {{ $filters['action'] ?: 'All' }} |
        Guard {{ $filters['guard_id'] ?: 'All' }} |
        Resident {{ $filters['resident_id'] ?: 'All' }} |
        Entry Code {{ $filters['entry_code'] !== '' ? $filters['entry_code'] : 'Any' }} |
        Search {{ $filters['search'] !== '' ? $filters['search'] : 'None' }}
    </div>

    <table class="logs">
        <thead>
            <tr>
                <th style="width: 11%">Date/Time</th>
                <th style="width: 11%">Building</th>
                <th style="width: 14%">Visitor</th>
                <th style="width: 9%">Type</th>
                <th style="width: 8%">Action</th>
                <th style="width: 9%">Entry Code</th>
                <th style="width: 12%">Guard</th>
                <th style="width: 12%">Resident</th>
                <th style="width: 14%">Purpose/Notes</th>
            </tr>
        </thead>
        <tbody>
            @forelse($logs as $log)
                <tr>
                    <td>
                        {{ $log->activity_date?->format('d M Y') }}<br>
                        <span class="muted">{{ $log->activity_date?->format('h:i A') }}</span>
                    </td>
                    <td>{{ $log->building?->name ?? 'N/A' }}</td>
                    <td>
                        <strong>{{ $log->visitor_name ?: 'N/A' }}</strong><br>
                        <span class="muted">{{ $log->visitor_phone ?: 'No phone' }}</span>
                    </td>
                    <td>{{ $log->getVisitorTypeLabel() }}</td>
                    <td>{{ $log->getActionLabel() }}</td>
                    <td>{{ $log->entry_code ?: ($log->gatepass?->entry_code ?: 'N/A') }}</td>
                    <td>{{ $log->guardUser?->user?->name ?? 'N/A' }}</td>
                    <td>{{ $log->resident?->user?->name ?? 'N/A' }}</td>
                    <td>
                        {{ $log->purpose ?: 'No purpose' }}
                        @if(!empty($log->notes))
                            <br><span class="muted">{{ $log->notes }}</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="9" style="text-align:center">No logs found for current filters.</td>
                </tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
