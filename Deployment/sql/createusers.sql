CREATE USER [apv-linage-0799-demo] FROM EXTERNAL PROVIDER
ALTER ROLE [db_owner] ADD MEMBER  [apv-linage-0799-demo]

CREATE USER [syn-ws-linage-0799-demo] FROM EXTERNAL PROVIDER
ALTER ROLE [db_owner] ADD MEMBER [syn-ws-linage-0799-demo] 