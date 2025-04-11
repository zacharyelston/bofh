#!/bin/bash
# Create SQLite database for file vectors
sqlite3 filesystem.db "CREATE TABLE files (
    path TEXT PRIMARY KEY,
    size INTEGER, 
    modified INTEGER,
    permissions TEXT,
    access_time INTEGER,
    change_time INTEGER,
    user_id INTEGER,
    group_id INTEGER,
    content_hash TEXT
);"

# Import collected data
cat raw_metadata.txt | while IFS='|' read -r path size modified perms type uid gid links atime ctime; do
    sqlite3 filesystem.db "INSERT INTO files 
        (path, size, modified, permissions, access_time, change_time, user_id, group_id) 
        VALUES ('$path', $size, $modified, '$perms', $atime, $ctime, $uid, $gid);"
done
