-------------

Service ID

Transaction
1 - 
                Is this a Custom URL?
                          |
         |----------------*-----------------|
         |                                  |
        No                                 Yes
         |                                  |
    ServiceID.new()          ServiceID.register("custom")
         |                                  |
           

ServiceID.new() -> Result<err, String>

Service ID gets the last ID
Tries to increment one and add to the table
if it works then returns that one, otherwise does that again


------------

Sequence

Table with

```
isert(custom : Option) ->
  custom match {
    Some(s) => {
      insert_db(s -> convert to id)? 
      // if this fails it means the ID is already there
    }
    None => {
      insert_db(next())?
      // if this fails it means the next ID was occupied (probably by a custom one)
      // we can try again a couple of times, inserting, incrementing the value
    }
  }
```

`alias`, `url`


