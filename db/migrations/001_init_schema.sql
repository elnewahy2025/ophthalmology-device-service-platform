CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TYPE user_role AS ENUM ('admin', 'technician', 'customer');
CREATE TABLE users (
id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
email         CITEXT UNIQUE NOT NULL,
password_hash TEXT        NOT NULL,
full_name     TEXT        NOT NULL,
role          user_role   NOT NULL DEFAULT 'technician',
mfa_secret    TEXT,
created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE devices (
id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
serial_number    CITEXT UNIQUE NOT NULL,
manufacturer     TEXT NOT NULL,
model            TEXT NOT NULL,
owner_id         UUID REFERENCES users(id) ON DELETE SET NULL,
location         TEXT,
installed_at     TIMESTAMPTZ DEFAULT NOW(),
last_service_at  TIMESTAMPTZ,
created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TYPE service_status AS ENUM ('open', 'in_progress', 'completed', 'cancelled');
CREATE TABLE service_records (
id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
device_id     UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
technician_id UUID NOT NULL REFERENCES users(id),
status        service_status NOT NULL DEFAULT 'open',
summary       TEXT,
description   TEXT,
started_at    TIMESTAMPTZ DEFAULT NOW(),
finished_at   TIMESTAMPTZ,
created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated    BEFORE UPDATE ON users    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_devices_updated  BEFORE UPDATE ON devices  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_service_updated  BEFORE UPDATE ON service_records FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_devices_owner      ON devices(owner_id);
CREATE INDEX idx_service_device     ON service_records(device_id);
CREATE INDEX idx_service_technician ON service_records(technician_id);