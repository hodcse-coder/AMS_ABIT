-- Access roles supplement the existing login/profile account types in user_roles.
CREATE TABLE IF NOT EXISTS access_routes (
 route_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,route_key VARCHAR(100) NOT NULL UNIQUE,module VARCHAR(50) NOT NULL,
 label VARCHAR(150) NOT NULL,method VARCHAR(10) NOT NULL CHECK(method IN('GET','POST','PATCH','PUT','DELETE')),path_pattern VARCHAR(200) NOT NULL,
 is_active BOOLEAN NOT NULL DEFAULT TRUE,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id),UNIQUE(method,path_pattern)
);
CREATE TABLE IF NOT EXISTS access_permissions (
 permission_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name VARCHAR(100) NOT NULL UNIQUE,description VARCHAR(500),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS access_roles (
 access_role_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name VARCHAR(100) NOT NULL UNIQUE,description VARCHAR(500),is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),updated_at TIMESTAMPTZ,updated_by BIGINT REFERENCES users(user_id)
);
CREATE TABLE IF NOT EXISTS access_permission_routes (
 permission_id BIGINT NOT NULL REFERENCES access_permissions(permission_id) ON DELETE CASCADE,route_id BIGINT NOT NULL REFERENCES access_routes(route_id),PRIMARY KEY(permission_id,route_id)
);
CREATE TABLE IF NOT EXISTS access_role_permissions (
 access_role_id BIGINT NOT NULL REFERENCES access_roles(access_role_id) ON DELETE CASCADE,permission_id BIGINT NOT NULL REFERENCES access_permissions(permission_id),PRIMARY KEY(access_role_id,permission_id)
);
CREATE TABLE IF NOT EXISTS access_assignments (
 user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,access_role_id BIGINT NOT NULL REFERENCES access_roles(access_role_id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),created_by BIGINT NOT NULL REFERENCES users(user_id),PRIMARY KEY(user_id,access_role_id)
);
CREATE TABLE IF NOT EXISTS access_audit (
 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,actor_id BIGINT NOT NULL REFERENCES users(user_id),action VARCHAR(60) NOT NULL,record_id BIGINT,
 before_value JSONB,after_value JSONB,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS access_assignments_role_idx ON access_assignments(access_role_id);
