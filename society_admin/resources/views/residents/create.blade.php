@extends('layouts.app')

@section('title', 'Create Resident')
@section('header', 'Create Resident')

@section('content')
<div class="max-w-4xl">
    <div class="mb-6 flex items-center justify-between">
        <a href="{{ route('admin.residents.index') }}" class="text-gray-500 hover:text-gray-700 text-sm font-medium">&larr; Back to Residents</a>
    </div>

    @if ($errors->any())
        <div class="bg-red-50 text-red-700 p-4 rounded-xl mb-6">
            <ul class="list-disc pl-5 text-sm">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8">
        <form method="POST" action="{{ route('admin.residents.store') }}" id="resident-form">
            @csrf

            <div class="mb-8">
                <h3 class="text-lg font-semibold text-gray-800 mb-4 border-b pb-2">Resident Details</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="md:col-span-2">
                        <label class="block text-sm font-medium mb-1">Full Name</label>
                        <input type="text" name="name" value="{{ old('name') }}" required class="w-full px-4 py-2 border rounded-lg">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Phone</label>
                        <input type="text" name="phone" value="{{ old('phone') }}" required class="w-full px-4 py-2 border rounded-lg">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Email (Optional)</label>
                        <input type="email" name="email" value="{{ old('email') }}" class="w-full px-4 py-2 border rounded-lg">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Resident Role</label>
                        <select name="role" class="w-full px-4 py-2 border rounded-lg" required>
                            <option value="resident" @selected(old('role') === 'resident')>Resident</option>
                            <option value="committee" @selected(old('role') === 'committee')>Committee</option>
                            <option value="admin" @selected(old('role') === 'admin')>Building Admin Resident</option>
                        </select>
                    </div>
                </div>
            </div>

            <div class="mb-8">
                <h3 class="text-lg font-semibold text-gray-800 mb-4 border-b pb-2">Building Assignment</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="md:col-span-2">
                        <label class="block text-sm font-medium mb-1">Building</label>
                        @if ($isSuperadmin)
                            <select name="building_id" id="building_id" class="w-full px-4 py-2 border rounded-lg" required>
                                <option value="">Select a building</option>
                                @foreach($allBuildings as $b)
                                    <option value="{{ $b->id }}" @selected(old('building_id') == $b->id)>{{ $b->name }}</option>
                                @endforeach
                            </select>
                            <p class="text-xs text-gray-500 mt-1">Select the building where you want to add this resident.</p>
                        @else
                            <input type="hidden" name="building_id" value="{{ $building->id }}">
                            <input type="text" value="{{ $building->name }}" disabled class="w-full px-4 py-2 border rounded-lg bg-gray-100 text-gray-600 cursor-not-allowed">
                            <p class="text-xs text-gray-500 mt-1">Auto-selected from your authenticated admin building.</p>
                        @endif
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1">Block</label>
                        <select name="block_id" id="block_id" class="w-full px-4 py-2 border rounded-lg" required>
                            <option value="">Select block</option>
                            @foreach($blocks as $block)
                                <option value="{{ $block->id }}" @selected(old('block_id') == $block->id)>{{ $block->name }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1">Floor</label>
                        <select name="floor_id" id="floor_id" class="w-full px-4 py-2 border rounded-lg" required>
                            <option value="">Select floor</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1">Flat</label>
                        <select name="flat_id" id="flat_id" class="w-full px-4 py-2 border rounded-lg" required>
                            <option value="">Select flat</option>
                        </select>
                    </div>
                </div>
            </div>

            <div class="mb-8">
                <h3 class="text-lg font-semibold text-gray-800 mb-4 border-b pb-2">Finance</h3>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium mb-1">Monthly Maintenance Fee</label>
                        <input type="number" step="0.01" min="0" name="monthly_maintenance_fee" value="{{ old('monthly_maintenance_fee', 0) }}" class="w-full px-4 py-2 border rounded-lg">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Rent Per Month</label>
                        <input type="number" step="0.01" min="0" name="rent" value="{{ old('rent', 0) }}" class="w-full px-4 py-2 border rounded-lg">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Billing Date (Optional)</label>
                        <input type="number" min="1" max="28" name="bill_generate_day" value="{{ old('bill_generate_day', 1) }}" class="w-full px-4 py-2 border rounded-lg">
                        <p class="text-xs text-gray-500 mt-1">Leave default for scheduler-driven billing cycle.</p>
                    </div>
                </div>
            </div>

            <div class="flex justify-end gap-3">
                <a href="{{ route('admin.residents.index') }}" class="px-6 py-2 border rounded-lg text-gray-600 hover:bg-gray-50 transition font-medium">Cancel</a>
                <button type="submit" class="bg-primary hover:bg-blue-600 text-white font-medium py-2 px-6 rounded-lg transition">Create Resident</button>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    const buildingSelect = document.getElementById('building_id');
    const blockSelect = document.getElementById('block_id');
    const floorSelect = document.getElementById('floor_id');
    const flatSelect = document.getElementById('flat_id');

    const oldFloorId = '{{ old('floor_id') }}';
    const oldFlatId = '{{ old('flat_id') }}';

    function setLoading(select, placeholder) {
        select.innerHTML = `<option value="">${placeholder}</option>`;
    }

    async function fetchJson(url) {
        const response = await fetch(url, {
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'Accept': 'application/json',
            },
        });

        if (!response.ok) {
            throw new Error('Failed to fetch data');
        }

        return response.json();
    }

    async function loadBlocks(buildingId, selectedId = '') {
        setLoading(blockSelect, 'Loading blocks...');
        setLoading(floorSelect, 'Select floor');
        setLoading(flatSelect, 'Select flat');

        if (!buildingId) {
            setLoading(blockSelect, 'Select block');
            return;
        }

        const data = await fetchJson(`/buildings/${buildingId}/blocks`);
        blockSelect.innerHTML = '<option value="">Select block</option>';

        data.forEach((block) => {
            const option = document.createElement('option');
            option.value = block.id;
            option.textContent = block.name;
            if (String(selectedId) === String(block.id)) {
                option.selected = true;
            }
            blockSelect.appendChild(option);
        });

        if (selectedId) {
            await loadFloors(selectedId, oldFloorId);
        }
    }

    async function loadFloors(blockId, selectedId = '') {
        setLoading(floorSelect, 'Loading floors...');
        setLoading(flatSelect, 'Select flat');

        if (!blockId) {
            setLoading(floorSelect, 'Select floor');
            return;
        }

        const data = await fetchJson(`{{ url('/blocks') }}/${blockId}/floors`);
        floorSelect.innerHTML = '<option value="">Select floor</option>';

        data.forEach((floor) => {
            const option = document.createElement('option');
            option.value = floor.id;
            option.textContent = floor.floor_number;
            if (String(selectedId) === String(floor.id)) {
                option.selected = true;
            }
            floorSelect.appendChild(option);
        });

        if (selectedId) {
            await loadFlats(selectedId, oldFlatId);
        }
    }

    async function loadFlats(floorId, selectedId = '') {
        setLoading(flatSelect, 'Loading flats...');

        if (!floorId) {
            setLoading(flatSelect, 'Select flat');
            return;
        }

        const data = await fetchJson(`{{ url('/floors') }}/${floorId}/flats`);
        flatSelect.innerHTML = '<option value="">Select flat</option>';

        data.forEach((flat) => {
            const option = document.createElement('option');
            option.value = flat.id;
            option.textContent = flat.flat_number;
            if (String(selectedId) === String(flat.id)) {
                option.selected = true;
            }
            flatSelect.appendChild(option);
        });
    }

    // For superadmin: listener on building change
    if (buildingSelect) {
        buildingSelect.addEventListener('change', async function () {
            await loadBlocks(this.value);
        });
    }

    blockSelect.addEventListener('change', async function () {
        await loadFloors(this.value);
    });

    floorSelect.addEventListener('change', async function () {
        await loadFlats(this.value);
    });

    // Initialize data on page load
    if (buildingSelect && buildingSelect.value) {
        // Superadmin mode: load blocks when building is pre-selected
        loadBlocks(buildingSelect.value, '{{ old('block_id') }}');
    } else if (blockSelect.value) {
        // Regular admin mode: load floors based on selected block
        loadFloors(blockSelect.value, oldFloorId);
    }
})();
</script>
@endsection
