create group readonly_access; 

create user looker in group readonly_access;

grant select on all tables in schema public to readonly_access;