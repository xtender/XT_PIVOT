Package for dynamic pivotting - Tom Kyte's package modification.

http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:766825833740#14642820392307

Example:

     begin
      :qq:=XT_PIVOT.pivot_sql(
                                         'select count(distinct trunc(dt)) from actions'
                                        , 'select e.name name,sum(a.cnt) sum_cnt,a.dt,dense_rank() over(order by dt) rn from actions a left join emp e on e.id=a.emp group by e.name,a.dt'
                                        , varchar2_table('NAME')
                                        , varchar2_table('SUM_CNT')
                                        , varchar2_table('select distinct ''Date ''||trunc(dt) from actions')
                                    );
      :qc :=XT_PIVOT.pivot_ref(
                                         'select count(distinct trunc(dt)) from actions'
                                        , 'select e.name,sum(a.cnt) sum_cnt,a.dt,dense_rank() over(order by dt) rn from actions a left join emp e on e.id=a.emp group by e.name,a.dt'
                                        , varchar2_table('NAME')
                                        , varchar2_table('SUM_CNT')
                                        , varchar2_table('select distinct ''Date ''||trunc(dt) from actions')
                                    );
     end;
