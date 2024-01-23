CREATE TABLE IF NOT EXISTS file (
    path TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS label (
    name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS contributor (
    name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS pr (
    id INTEGER NOT NULL PRIMARY KEY,
    author_name TEXT NULL,
    created_at INTEGER NULL,
    closed_at INTEGER NULL,
    merged_at INTEGER NULL,
    manually_assigned BOOLEAN,
    FOREIGN KEY (author_name) REFERENCES contributor(name)
);

CREATE TABLE IF NOT EXISTS pr_assignee (
    pr_id INTEGER NOT NULL,
    assignee_name TEXT NOT NULL,
    PRIMARY KEY(pr_id, assignee_name),
    FOREIGN KEY(pr_id) REFERENCES pr(id),
    FOREIGN KEY(assignee_name) REFERENCES contributor(name)
);

CREATE TABLE IF NOT EXISTS pr_label (
    pr_id INTEGER NOT NULL,
    label_name TEXT NOT NULL,
    PRIMARY KEY(pr_id, label_name),
    FOREIGN KEY(pr_id) REFERENCES pr(id),
    FOREIGN KEY(label_name) REFERENCES label(name)
);

CREATE TABLE IF NOT EXISTS pr_files (
    pr_id INTEGER NOT NULL,
    file_path TEXT NOT NULL,
    PRIMARY KEY(pr_id, file_path),
    FOREIGN KEY(pr_id) REFERENCES pr(id),
    FOREIGN KEY(file_path) REFERENCES file(path)
);
