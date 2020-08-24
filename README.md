# GET_FORMAT_DATE

----

## Description :

The GET_FORMAT_DATE is an oracle sql function created under GNU General Public License v3.0 to  
determinate if a string is in a date format or not. You can also use it to validate a string like an IS_DATE function. Function use regular expression to validate Date String and function is editable adding new couple  
of format value and regular expression to improve its funcionality. 

Function have two input arguments :  
1. String Date  
2. Format Date (If is null check if first arguments is a date and return relative format date  
                otherwise apply "Format Date" to "String Date" and if is correct return the value  
                of String Date otherwise null)  

Function returns null if the input is not a valid date otherwise Format Date   

----

## Compatibility :

ORACLE 10 or upper


----

## Samples:
           
           GET_FORMAT_DATE( '2020/08/24',null )

           result:
           ----------
           YYYY/MM/DD  

           GET_FORMAT_DATE( '19-ENE-2020',null ) {Actually Function manage Spanish and Italian 
                                                  notation for MON or MONTH}

           result:
           -----------
           DD-MON-YYYY  

           GET_FORMAT_DATE( '20200230','YYYYMMDD' ) {This modality permits execute a check if 
                                                     date string is in a correct format and value}

           result:
           -----------
           null  
