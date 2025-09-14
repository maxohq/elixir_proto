### Rules

- always support your implementation with unit tests
- All tests must be collocated
- Every implemented module must have corresponding tests. 
- There must be no gen servers in Elixir Proto
- You will find a creative solution for the schema registry. 
    - There should be no gen servers. 
    - And when I reboot the application without any gen servers, I should be still able to properly serialize and deserialize my structs.