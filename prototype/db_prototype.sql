
-- 1. Equipment categories
CREATE TABLE EquipmentCategory (
    category_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- 2. Hospital locations
CREATE TABLE Location (
    location_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ward_name VARCHAR(100),
    department VARCHAR(100),
    building VARCHAR(100),
    floor VARCHAR(20),
    room_number VARCHAR(30),
    description TEXT
);

-- 3. Staff members
CREATE TABLE Staff (
    staff_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    role VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    contact_number VARCHAR(30),
    email VARCHAR(255) UNIQUE
);

-- 4. Patients
-- Use authorised hospital identifiers and restrict access.
CREATE TABLE Patient (
    patient_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medical_record_number VARCHAR(100) NOT NULL UNIQUE
);

-- 5. Equipment inventory
CREATE TABLE Equipment (
    equipment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INT NOT NULL REFERENCES EquipmentCategory(category_id),
    asset_number VARCHAR(100) NOT NULL UNIQUE,
    barcode VARCHAR(100) UNIQUE,
    serial_number VARCHAR(100),
    model VARCHAR(100),
    purchase_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'available'
        CHECK (status IN (
            'available', 'on_loan', 'missing',
            'under_repair', 'retired'
        )),
    notes TEXT
);

-- 6. Tracking devices
CREATE TABLE Tracker (
    tracker_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipment_id INT NOT NULL UNIQUE
        REFERENCES Equipment(equipment_id),
    tracker_type VARCHAR(30) NOT NULL,
    device_identifier VARCHAR(150) NOT NULL UNIQUE,
    last_seen TIMESTAMPTZ,
    last_location_id INT REFERENCES Location(location_id),
    tracker_status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (tracker_status IN (
            'active', 'inactive', 'maintenance'
        ))
);

-- 7. Equipment requests / smart waiting list
CREATE TABLE EquipmentRequest (
    request_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES Patient(patient_id),
    category_id INT NOT NULL REFERENCES EquipmentCategory(category_id),
    requested_by INT NOT NULL REFERENCES Staff(staff_id),
    clinical_priority VARCHAR(20) NOT NULL
        CHECK (clinical_priority IN (
            'urgent', 'high', 'normal', 'low'
        )),
    request_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'waiting'
        CHECK (status IN (
            'waiting', 'under_review', 'allocated',
            'fulfilled', 'cancelled'
        )),
    notes TEXT
);

-- 8. Equipment allocations
CREATE TABLE Allocation (
    allocation_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_id INT NOT NULL REFERENCES EquipmentRequest(request_id),
    equipment_id INT NOT NULL REFERENCES Equipment(equipment_id),
    staff_id INT NOT NULL REFERENCES Staff(staff_id),
    allocation_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    issue_date TIMESTAMPTZ,
    return_date TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN (
            'pending', 'issued', 'returned', 'cancelled'
        ))
);

-- 9. Equipment movements
CREATE TABLE EquipmentMovement (
    movement_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipment_id INT NOT NULL REFERENCES Equipment(equipment_id),
    staff_id INT NOT NULL REFERENCES Staff(staff_id),
    patient_id INT REFERENCES Patient(patient_id),
    from_location_id INT REFERENCES Location(location_id),
    to_location_id INT REFERENCES Location(location_id),
    movement_type VARCHAR(20) NOT NULL
        CHECK (movement_type IN (
            'issue', 'return', 'transfer', 'found'
        )),
    movement_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- 10. Maintenance records
CREATE TABLE MaintenanceRecord (
    maintenance_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipment_id INT NOT NULL REFERENCES Equipment(equipment_id),
    service_date DATE NOT NULL,
    next_service_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
        CHECK (status IN (
            'scheduled', 'in_progress', 'completed'
        )),
    notes TEXT,
    CHECK (
        next_service_date IS NULL
        OR next_service_date >= service_date
    )
);