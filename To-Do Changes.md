# Changes to be made
## Accessing PPRA data
 - Change the default to access FNW, HLI, and OPEP data from the server instead of from folder files
    - Consider keeping the current access method as the back up in case someone doesn't have access to the server but can have the files
    - Update README and ORGANIZATION_SUMMARY to reflect these changes
### I have changed to server-based loading; have not updated the data processing functions yet to reflect this

 - Updated the database connection function to use the new PPRA server connection information
    - Update README and ORGANIZATION_SUMMARY to reflect these changes
## Does the port variable take numbers and search that way

## ARM shipment information
- Change data access for shipments from diagnostic results table by FO to the previous methodology of getting inspections commodities etc from ARM directly for the region and port
    - there should be efficiencies in the code before collect() is called that i can incorporate


## Commodity is only showing shipments with pests
- I want to change this to take all shipment information
    - That way, I can then have predictions for the likelihood of a shipment having a pest, in addition to the overall impact rating of the pests
    - This might be stored somewhere in the port profiles approach