CREATE TABLE user (
    id              INTEGER PRIMARY KEY,
    name            VARCHAR(30) UNIQUE NOT NULL,
    sha1            VARCHAR(255),
    email           VARCHAR(100) UNIQUE NOT NULL,
    fname           VARCHAR(100),
    lname           VARCHAR(100),
    country         VARCHAR(100),
    state           VARCHAR(100),
    validation_key  VARCHAR(255),
    verified        BOOL DEFAULT 0,
    register_ts     INTEGER DEFAUL NOW
);
-- record if the person was added manually of s/he registered?

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_email ON user (email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_name  ON user (name);

CREATE TABLE site (
    id            INTEGER PRIMARY KEY,
    name          VARCHAR(100) UNIQUE NOT NULL,
    owner         INTEGER NOT NULL,
    creation_ts   INTEGER NOT NULL DEFAULT NOW ,
    FOREIGN KEY (owner) REFERENCES user(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_site_name ON site (name);

CREATE TABLE page (
    id          INTEGER PRIMARY KEY,
    siteid      INTEGER,
    title       VARCHAR(255),
    body        BLOB,
    description VARCHAR(255),
    abstract    BLOB,
    filename    VARCHAR(255),
    timestamp   INTEGER,
    author      INTEGER,
    FOREIGN KEY (siteid) REFERENCES site(id),
    FOREIGN KEY (author) REFERENCES user(id)
);
