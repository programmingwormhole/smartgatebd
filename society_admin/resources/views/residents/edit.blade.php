@extends('layouts.app')

@section('title', 'Edit Resident - ' . $resident->user?->name)
@section('header', 'Edit Resident')

@section('content')
<div class="max-w-4xl">
    <div class="mb-6 flex items-center justify-between">
        <a href="{{ route('admin.residents.show', $resident) }}" class="text-gray-600 hover:text-gray-900 font-medium flex items-center gap-2">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
            Back to Resident Details
        </a>
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
        <form method="POST" action="{{ route('admin.residents.update', $resident) }}" id="resident-form">
            @csrf
            @method('PUT')

            <div class="mb-8">
                <h3 class="text-lg font-semibold text-gray-800 mb-4 border-b pb-2">Resident Details</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="md:col-span-2">
                        <label class="block text-sm font-medium mb-1">Full Name</label>
                        <input type="text" name="name" value="{{ old('name', $resident->user?->name) }}" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Phone</label>
                        <input type="text" name="phone" value="{{ old('phone', $resident->user?->phone) }}" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Email (Optional)</label>
                        <input type="email" name="email" value="{{ old('email', $resident->user?->email) }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Resident Role</label>
                        <select name="role" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" required>
                            <option value="resident" @selected(old('role', $resident->role) === 'resident')>Resident</option>
                            <option value="committee" @selected(old('role', $resident->role) === 'committee')>Committee</option>
                            <option value="admin" @selected(old('role', $resident->role) === 'admin')>Building Admin Resident</option>
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
                            <select name="building_id" id="building_id" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" required>
                                <option value="">Select a building</option>
                                @foreach($allBuildings as $b)
                                    <option value="{{ $b->id }}" @selected(old('building_id', $building->id) == $b->id)>{{ $b->name }}</option>
                                @endforeach
                            </select>
                            <p class="text-xs text-gray-500 mt-1">Select the building for this resident.</p>
                        @else
                            <input type="hidden" name="building_id" value="{{ $building->id }}">
                            <input type="text" value="{{ $building->name }}" disabled class="w-full px-4 py-2 border rounded-lg bg-gray-100 text-gray-600 cursor-not-allowed">
                            <p class="text-xs text-gray-500 mt-1">Building cannot be changed.</p>
                        @endif
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1">Block</label>
                        <select name="block_id" id="block_id" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" required>
                            <option value="">Select block</option>
                            @foreach($blocks as $block)
                                <option value="{{ $block->id }}" @selected(old('block_id', $resident->flat->floor->block_id) == $block->id)>{{ $block->name }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1">Floor</label>
                        <select name="floor_id" id="floor_id" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" required>
                            <option value="">Select floor</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1">Flat</label>
                        <select name="flat_id" id="flat_id" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" required>
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
                        <input type="number" step="0.01" min="0" name="monthly_maintenance_fee" value="{{ old('monthly_maintenance_fee', $resident->monthly_maintenance_fee) }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Rent Per Month</label>
                        <input type="number" step="0.01" min="0" name="rent" value="{{ old('rent', $resident->rent) }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Billing Date (Optional)</label>
                        <input type="number" min="1" max="28" name="bill_generate_day" value="{{ old('bill_generate_day', $resident->bill_generate_day) }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                        <p class="text-xs text-gray-500 mt-1">Day of month for billing cycle (1-28).</p>
                    </div>
                </div>
            </div>

            <div class="flex justify-end gap-3">
                <a href="{{ route('admin.residents.show', $resident) }}" class="px-6 py-2 border rounded-lg text-gray-600 hover:bg-gray-50 transition font-medium">Cancel</a>
                <button type="submit" class="bg-primary hover:bg-blue-600 text-white font-medium py-2 px-6 rounded-lg transition">Update Resident</button>
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

    const currentFloorId = '{{ old('floor_id', $resident->flat->floor_id) }}';
    const currentFlatId = '{{ old('flat_id', $resident->flat_id) }}';

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

        try {
            const data = await fetchJson(`/buildings/${buildingId}/blocks`);
            blockSelect.innerHTML = '<option value="">Select block</option>';

            data.forEach(block => {
                const option = document.createElement('option');
                option.value = block.id;
                option.textContent = block.name;
                if (selectedId && block.id == selectedId) {
                    option.selected = true;
                }
                blockSelect.appendChild(option);
            });

            if (selectedId) {
                await loadFloors(selectedId, '{{ old('floor_id', $resident->flat->floor_id) }}');
            }
        } catch (error) {
            console.error('Error loading blocks:', error);
            setLoading(blockSelect, 'Error loading blocks');
        }
    }

    async function loadFloors(blockId, selectedId = '') {
        setLoading(floorSelect, 'Loading floors...');
        setLoading(flatSelect, 'Select flat');

        if (!blockId) {
            setLoading(floorSelect, 'Select floor');
            return;
        }

        try {
            const blockElement = blockSelect.querySelector(`option[value="${blockId}"]`);
            if (!blockElement) return;

            const url = `/blocks/${blockId}/floors`;
            const data = await fetchJson(url);
            floorSelect.innerHTML = '<option value="">Select floor</option>';

            data.forEach(floor => {
                const option = document.createElement('option');
                option.value = floor.id;
                option.textContent = `Floor ${floor.floor_number}`;
                if (selectedId && floor.id == selectedId) {
                    option.selected = true;
                }
                floorSelect.appendChild(option);
            });

            if (selectedId) {
                await loadFlats(selectedId, currentFlatId);
            }
        } catch (error) {
            console.error('Error loading floors:', error);
            setLoading(floorSelect, 'Error loading floors');
        }
    }

    async function loadFlats(floorId, selectedId = '') {
        setLoading(flatSelect, 'Loading flats...');

        if (!floorId) {
            setLoading(flatSelect, 'Select flat');
            return;
        }

        try {
            const url = `/floors/${floorId}/flats`;
            const data = await fetchJson(url);
            flatSelect.innerHTML = '<option value="">Select flat</option>';

            data.forEach(flat => {
                const option = document.createElement('option');
                option.value = flat.id;
                option.textContent = `Flat ${flat.flat_number}`;
                if (selectedId && flat.id == selectedId) {
                    option.selected = true;
                }
                flatSelect.appendChild(option);
            });
        } catch (error) {
            console.error('Error loading flats:', error);
            setLoading(flatSelect, 'Error loading flats');
        }
    }

    // For superadmin: listener on building change
    if (buildingSelect) {
        buildingSelect.addEventListener('change', (e) => {
            loadBlocks(e.target.value);
        });
    }

    blockSelect.addEventListener('change', (e) => {
        loadFloors(e.target.value);
    });

    floorSelect.addEventListener('change', (e) => {
        loadFlats(e.target.value);
    });

    // Load initial data
    if (buildingSelect && buildingSelect.value) {
        // Superadmin mode: load blocks when building is pre-selected
        loadBlocks(buildingSelect.value, '{{ old('block_id', $resident->flat->floor->block_id) }}');
    } else if (blockSelect.value) {
        // Regular admin mode: load floors based on selected block
        loadFloors(blockSelect.value, currentFloorId);
    }
})();
</script>
@endsection
