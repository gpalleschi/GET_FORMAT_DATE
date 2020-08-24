/********************************************************************************************************************
    The GET_FORMAT_DATE is an oracle sql function created under GNU General Public License v3.0 to determinate if a 
    string is in a date format or not.
    Function have two input arguments :
        1) String Date
        2) Format Date (If is null check if first arguments is a date and return relative format date
                        otherwise apply "Format Date" to "String Date" and if is correct return the value 
                        of String Date otherwise null)
    
    Function returns null if the input is not a valid date otherwise Format Date    

    samples:
    -------
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


    History of changes
    yyyy.mm.dd | Version | Author                | Changes
    -----------+---------+-----------------------+-------------------------
    2020.08.20 |  1.0    | Giovanni Palleschi    | First Release 

********************************************************************************************************************/

create or replace function get_format_date( I_DATE_STRING  in varchar2,
                                            I_DATE_FORMAT  in varchar2
                                          ) RETURN VARCHAR2 IS
    V_DATE_STRING varchar( 1024 );
    LEN_DATE_STRING integer;
    V_DATE_FORMAT varchar( 1024 );
    V_DATE date;

    type a_conv_month_t is varray(12) of varchar2(32);
    type a_dict_from_mon_conv_t is varray(2) of a_conv_month_t;
    -- MON Spanish x 12
    a_conv_esp_mon a_conv_month_t := a_conv_month_t('ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DEC');
    -- MONTH Spanish x 12
    a_conv_esp_month a_conv_month_t := a_conv_month_t('ENERO','FEBRERO','MARZO','ABRIL','MAYO','JUNIO','JULIO','AGOSTO','SEPTIEMBRE','OCTUBRE','NOVIEMBRE','DICIEMBRE');
    -- MON Italian x 12
    a_conv_ita_mon a_conv_month_t := a_conv_month_t('GEN','FEB','MAR','APR','MAG','GIU','LUG','AGO','SET','OTT','NOV','DIC');
    -- MONTH Italian x 12
    a_conv_ita_month a_conv_month_t := a_conv_month_t('GENNAIO','FEBBRAIO','MARZO','APRILE','MAGGIO','GIUGNO','LUGLIO','AGOSTO','SETTEMBRE','OTTOBRE','NOVEMBRE','DICEMBRE');
    -- MON English x 12
    a_conv_to_mon a_conv_month_t := a_conv_month_t('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC');
    a_conv_to_month a_conv_month_t := a_conv_month_t('JANUARY','FEBRUARY','MARCH','APRIL','MAY','JUNE','JULY','AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER');

    a_conv_from_mon a_conv_month_t := null;
    a_conv_from_month a_conv_month_t := null;

    a_dict_from_mon_conv a_dict_from_mon_conv_t := a_dict_from_mon_conv_t(a_conv_esp_mon,a_conv_ita_mon);
    a_dict_from_month_conv a_dict_from_mon_conv_t := a_dict_from_mon_conv_t(a_conv_esp_month,a_conv_ita_month);

    type a_frmt_date_t is varray(35) of varchar2(64);

-- **** YOU CAN AGGREGATE NEW COUPLE DATE FORMAT AND EXPRESSION IN ARRAYS a_frmt_date AND a_frmt_date_exp ****
-- **** TO IMPROVE FUNCTIONALITY ****
-- Array of date format     
    a_frmt_date a_frmt_date_t := a_frmt_date_t('YYYYMMDD',
                                               'DDMMYYYY',
                                               'DDMMRR',
                                               'RRMMDD',
                                               'YYYYDDD',
                                               'RRDDD',
                                               'YYYY/MM/DD',
                                               'DD/MM/YYYY',
                                               'DD/MM/RR',
                                               'RR/MM/DD',
                                               'YYYY/MON/DD',
                                               'DD/MON/YYYY',
                                               'DD/MON/RR',
                                               'RR/MON/DD',
                                               'YYYY/MONTH/DD',
                                               'DD/MONTH/YYYY',
                                               'DD/MONTH/RR',
                                               'RR/MONTH/DD',
                                               'YYYY-MM-DD',
                                               'DD-MM-YYYY',
                                               'DD-MM-RR',
                                               'RR-MM-DD',
                                               'YYYY-MON-DD',
                                               'DD-MON-YYYY',
                                               'DD-MON-RR',
                                               'RR-MON-DD',
                                               'YYYY-MONTH-DD',
                                               'DD-MONTH-YYYY',
                                               'DD-MONTH-RR',
                                               'RR-MONTH-DD',                                               
                                               null,
                                               null,
                                               null,
                                               null
                                              );
-- Array of date expr
    a_frmt_date_exp a_frmt_date_t := a_frmt_date_t('^[0-9]{4}[0-1][0-9][0-3][0-9]$',     -- YYYYMMDD
                                                   '^[0-3][0-9][0-1][0-9][0-9]{4}$',     -- DDMMYYYY
                                                   '^[0-3][0-9][0-1][0-9][0-9]{2}$',     -- DDMMRR
                                                   '^[0-9]{2}[0-1][0-9][0-3][0-9]$',     -- RRMMDD
                                                   '^[0-9]{4}[0-3][0-9][0-9]$',          -- YYYYDDD
                                                   '^[0-9]{2}[0-3][0-9][0-9]$',          -- RRDDD
                                                   '^[0-9]{4}/[0-1][0-9]/[0-3][0-9]$',   -- YYYY/MM/DD
                                                   '^[0-3][0-9]/[0-1][0-9]/[0-9]{4}$',   -- DD/MM/YYYY
                                                   '^[0-3][0-9]/[0-1][0-9]/[0-9]{2}$',   -- DD/MM/RR
                                                   '^[0-9]{2}/[0-1][0-9]/[0-3][0-9]$',   -- RR/MM/DD
                                                   '^[0-9]{4}/[A-Z]{3}/[0-3][0-9]$',     -- YYYY/MON/DD
                                                   '^[0-3][0-9]/[A-Z]{3}/[0-9]{4}$',     -- DD/MON/YYYY
                                                   '^[0-3][0-9]/[A-Z]{3}/[0-9]{2}$',     -- DD/MON/RR
                                                   '^[0-9]{2}/[A-Z]{3}/[0-3][0-9]$',     -- RR/MON/DD
                                                   '^[0-9]{4}/[A-Z]{3,}/[0-3][0-9]$',     -- YYYY/MONTH/DD
                                                   '^[0-3][0-9]/[A-Z]{3,}/[0-9]{4}$',     -- DD/MONTH/YYYY
                                                   '^[0-3][0-9]/[A-Z]{3,}/[0-9]{2}$',     -- DD/MONTH/RR
                                                   '^[0-9]{2}/[A-Z]{3,}/[0-3][0-9]$',     -- RR/MONTH/DD
                                                   '^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$',   -- YYYY-MM-DD
                                                   '^[0-3][0-9]-[0-1][0-9]-[0-9]{4}$',   -- DD-MM-YYYY
                                                   '^[0-3][0-9]-[0-1][0-9]-[0-9]{2}$',   -- DD-MM-RR
                                                   '^[0-9]{2}-[0-1][0-9]-[0-3][0-9]$',   -- RR-MM-DD
                                                   '^[0-9]{4}-[A-Z]{3}-[0-3][0-9]$',     -- YYYY-MON-DD
                                                   '^[0-3][0-9]-[A-Z]{3}-[0-9]{4}$',     -- DD-MON-YYYY
                                                   '^[0-3][0-9]-[A-Z]{3}-[0-9]{2}$',     -- DD-MON-RR
                                                   '^[0-9]{2}-[A-Z]{3}-[0-3][0-9]$',     -- RR-MON-DD
                                                   '^[0-9]{4}-[A-Z]{3,}-[0-3][0-9]$',     -- YYYY-MONTH-DD
                                                   '^[0-3][0-9]-[A-Z]{3,}-[0-9]{4}$',     -- DD-MONTH-YYYY
                                                   '^[0-3][0-9]-[A-Z]{3,}-[0-9]{2}$',     -- DD-MONTH-RR
                                                   '^[0-9]{2}-[A-Z]{3,}-[0-3][0-9]$',     -- RR-MONTH-DD
                                                   null,
                                                   null,
                                                   null,
                                                   null
                                                  );
BEGIN

-- Change NLS_DATE_LANGUAGE for MON and MONTH Format
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_LANGUAGE = ''AMERICAN'''; 

-- Start Check input parameters
    if I_DATE_STRING is NULL OR length(I_DATE_STRING) > 1024 OR length(I_DATE_FORMAT) > 1024 then
       return NULL;
    end if;
-- End Check input parameters

    V_DATE_STRING := trim(UPPER(I_DATE_STRING));
    LEN_DATE_STRING := LENGTH(V_DATE_STRING);
    V_DATE_FORMAT := trim(UPPER(I_DATE_FORMAT));

-- Start Check input parameters
-- If is specified Format Date 
    if I_DATE_FORMAT is not NULL then
       V_DATE := TO_DATE(V_DATE_STRING,V_DATE_FORMAT);
    else

-- If is not specified Format Date 
-- If string is in numeric format
       if regexp_like(V_DATE_STRING, '^[0-9A-Z/-]+$') then
          -- Case with MON inside for conversion
          if regexp_like(V_DATE_STRING, '^.*[-/]{1}[A-Z]{3}[-/].*$') then
             for i in 1..a_dict_from_mon_conv.count loop 
                 a_conv_from_mon := a_dict_from_mon_conv(i);
                 for y in 1..12 loop
                     V_DATE_STRING := REPLACE(V_DATE_STRING,a_conv_from_mon(y),a_conv_to_mon(y));
                 end loop;
             end loop;
          else   
             if regexp_like(V_DATE_STRING, '^.*[-/]{1}[A-Z]{4,}[-/].*$') then
                for i in 1..a_dict_from_month_conv.count loop 
                    a_conv_from_month := a_dict_from_month_conv(i);
                    for y in 1..12 loop
                        V_DATE_STRING := REPLACE(V_DATE_STRING,a_conv_from_month(y),a_conv_to_month(y));
                    end loop;
                end loop;
             end if;
          end if;
       end if;

       for i in 1..a_frmt_date.count loop 
           exit when a_frmt_date(i) is null;
           if regexp_like(V_DATE_STRING, a_frmt_date_exp(i)) then
              begin 
                 V_DATE := TO_DATE(V_DATE_STRING,a_frmt_date(i));
                 V_DATE_FORMAT := a_frmt_date(i);
                 exit;
              exception when others then
                 continue;
              end;
           end if;
       end loop;        
    end if;
    return V_DATE_FORMAT;
exception when others then
    return NULL;  -- Not determinated Format Date
end;
/