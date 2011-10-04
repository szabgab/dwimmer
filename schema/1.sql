CREATE TABLE mailing_list (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(100) UNIQUE NOT NULL,
    owner   INTEGER NOT NULL,
    from_address VARCHAR(100) NOT NULL,
    FOREIGN KEY (owner) REFERENCES user(id)
);
CREATE TABLE mailing_list_member (
    id              INTEGER PRIMARY KEY,
    listid          INTEGER NOT NULL,
    email           VARCHAR(100) NOT NULL,
    validation_key  VARCHAR(255) UNIQUE,
    approved        BOOL,
    register_ts     INTEGER,
    name            VARCHAR(100),

    FOREIGN KEY (listid) REFERENCES user(id)
);
PRAGMA user_version=1;
