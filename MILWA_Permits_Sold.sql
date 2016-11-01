/**************************************************************************/
/* Milwaukee Monthly Permit Report                                        */
/*                                                                        */
/* This query will create the monthly permit report. When run, PL/SQL     */
/* Developer will ask for a MonthsAgoToBegin and MonthsAgoToEnd. If       */
/* MonthsAgoToBegin is 1 and MonthsAgoToEnd is 0, only the previous       */
/* month will be returned. If MonthsAgoToBegin is 34 and MonthsAgoToEnd   */
/* is 0, the entire report is recreated.                                  */
/*                                                                        */
/* The report groups permits sold by period that is covered(P1,P2,P3 or   */
/* Annual), by Transaction Source (Over The Counter, WEB, Mail, Kiosk)    */
/* and then which location in that Transaction Source (Kiosk 1,2,3,etc,   */
/* OTC TowLot, OTC PAB, etc) and then what month it as issued             */
/* in.                                                                    */
/*                                                                        */
/* Every month, the report should be emailed to Brian Dunn on the 1st.    */
/*                                                                        */
/* Report created 11/1/16 by ECW                                          */
/*                                                                        */
/**************************************************************************/

SELECT To_char(ISS_MONTH, 'MM/YYYY') Issue_Month,
       Decode(Grouping(PERIOD), 1, 'Total', PERIOD) PERIOD,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_1', NUM_PERMITS)), 0) K1,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_2', NUM_PERMITS)), 0) K2,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_2A', NUM_PERMITS)), 0) K2A,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_3', NUM_PERMITS)), 0) K3,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_4', NUM_PERMITS)), 0) K4,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_5', NUM_PERMITS)), 0) K5,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_5A', NUM_PERMITS)), 0) K5A,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_6', NUM_PERMITS)), 0) K6,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_6A', NUM_PERMITS)), 0) K6A,
       Nvl(SUM(Decode(TRANS_SOURCE, 'KIOSK_7', NUM_PERMITS)), 0) K7,
       Nvl(SUM(Decode(TRANS_SOURCE, 'WEB', NUM_PERMITS)), 0) WEB,
       Nvl(SUM(Decode(TRANS_SOURCE, 'OTC_CHASE', NUM_PERMITS)), 0) CHASE,
       Nvl(SUM(Decode(TRANS_SOURCE, 'OTC_TEUTONIA', NUM_PERMITS)), 0) TEUTONIA,
       Nvl(SUM(Decode(TRANS_SOURCE, 'OTC_PAB', NUM_PERMITS)), 0) PAB,
       Nvl(SUM(Decode(TRANS_SOURCE, 'OTC_TOWLOT', NUM_PERMITS)), 0) TOWLOT,
       Nvl(SUM(Decode(TRANS_SOURCE, 'OTC_OTHER', NUM_PERMITS)), 0) OTC_OTHER,
       Nvl(SUM(Decode(TRANS_SOURCE, 'MAIL', NUM_PERMITS)), 0) MAIL,
       Nvl(SUM(NUM_PERMITS), 0) TOTAL_PERMITS
  FROM (SELECT Trunc(ISSUEDATE, 'mm') Iss_Month,
               CASE
                 WHEN Instr(A.PERMITTYPENAME, 'MO') > 0 THEN
                  CASE
                    WHEN Instr(A.PERMITTYPENAME, 'JAN') > 0 THEN
                     'Period 1'
                    WHEN Instr(A.PERMITTYPENAME, 'MAY') > 0 THEN
                     'Period 2'
                    WHEN Instr(A.PERMITTYPENAME, 'SEP') > 0 THEN
                     'Period 3'
                    ELSE
                     A.PERMITTYPENAME
                  END
                 WHEN Instr(A.PERMITTYPENAME, 'AN') > 0 THEN
                  'Annual'
                 ELSE
                  A.PERMITTYPENAME
               END PERIOD,
               Count(DISTINCT PARENTKEY) Num_Permits,
               CASE TRANS_SOURCE
                 WHEN 'KIOSK' THEN
                  'KIOSK_' || Substr(B.LAST_CHANGE_USER_NAME, 5)
                 WHEN 'OTC' THEN
                  CASE
                    WHEN Upper(B.BATCHID) LIKE '%TOWLOT%' THEN
                     'OTC_TOWLOT'
                    WHEN Upper(B.BATCHID) LIKE '%TEUT%' THEN
                     'OTC_TEUTONIA'
                    WHEN Upper(B.BATCHID) LIKE '%CHASE%' THEN
                     'OTC_CHASE'
                    WHEN Upper(B.BATCHID) LIKE '%PAB%' THEN
                     'OTC_PAB'
                    ELSE
                     'OTC_OTHER'
                  END
                 WHEN 'OTC-TOW LOT' THEN
                  'OTC_TOWLOT'
                 ELSE
                  TRANS_SOURCE
               END TRANS_SOURCE
          FROM MVB.PERMITISSUED A, MVB.VIEW_PERMITMASTER_PAYMENT B
         WHERE A.UNIQUEKEY = B.PARENTKEY
           AND A.ISSUEDATE >=
               Add_months(Trunc(SYSDATE, 'mm'), - &MONTHSAGOTOSTART)
           AND A.ISSUEDATE <
               Add_months(Trunc(SYSDATE, 'mm') - 1, - &MONTHSAGOTOEND)
           AND A.RECCLEAREDREASON <> 'VO'
           AND TRANS_SOURCE IS NOT NULL
           AND TRANS_STATUS = 'APPLIED'
           AND TRANS_APPLICATION = 'PAYMENT'
           AND A.PERMITTYPENAME IS NOT NULL
         GROUP BY CASE
                    WHEN Instr(A.PERMITTYPENAME, 'MO') > 0 THEN
                     CASE
                       WHEN Instr(A.PERMITTYPENAME, 'JAN') > 0 THEN
                        'Period 1'
                       WHEN Instr(A.PERMITTYPENAME, 'MAY') > 0 THEN
                        'Period 2'
                       WHEN Instr(A.PERMITTYPENAME, 'SEP') > 0 THEN
                        'Period 3'
                       ELSE
                        A.PERMITTYPENAME
                     END
                    WHEN Instr(A.PERMITTYPENAME, 'AN') > 0 THEN
                     'Annual'
                    ELSE
                     A.PERMITTYPENAME
                  END,
                  CASE TRANS_SOURCE
                    WHEN 'KIOSK' THEN
                     'KIOSK_' || Substr(B.LAST_CHANGE_USER_NAME, 5)
                    WHEN 'OTC' THEN
                     CASE
                       WHEN Upper(B.BATCHID) LIKE '%TOWLOT%' THEN
                        'OTC_TOWLOT'
                       WHEN Upper(B.BATCHID) LIKE '%TEUT%' THEN
                        'OTC_TEUTONIA'
                       WHEN Upper(B.BATCHID) LIKE '%CHASE%' THEN
                        'OTC_CHASE'
                       WHEN Upper(B.BATCHID) LIKE '%PAB%' THEN
                        'OTC_PAB'
                       ELSE
                        'OTC_OTHER'
                     END
                    WHEN 'OTC-TOW LOT' THEN
                     'OTC_TOWLOT'
                    ELSE
                     TRANS_SOURCE
                  END,
                  Trunc(ISSUEDATE, 'mm'))
 WHERE PERIOD IN ('Annual', 'Period 1', 'Period 2', 'Period 3')
 GROUP BY ISS_MONTH, ROLLUP(PERIOD)
 ORDER BY ISS_MONTH, PERIOD
