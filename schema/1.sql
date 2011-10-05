CREATE TABLE mailing_list (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(100) UNIQUE NOT NULL,
    title   VARCHAR(100) NOT NULL,
    owner   INTEGER NOT NULL,
    from_address VARCHAR(100) NOT NULL,
    response_page            VARCHAR(50),
    validation_page          VARCHAR(50),
    valiadtion_response_page VARCHAR(50),
    validate_template BLOB,
    confirm_template BLOB,
    FOREIGN KEY (owner) REFERENCES user(id)
);
CREATE TABLE mailing_list_member (
    id              INTEGER PRIMARY KEY,
    listid          INTEGER NOT NULL,
    email           VARCHAR(100) NOT NULL,
    validation_code VARCHAR(255) UNIQUE,
    approved        BOOL,
    register_ts     INTEGER,
    name            VARCHAR(100),

    FOREIGN KEY (listid) REFERENCES user(id)
);
PRAGMA user_version=1;
