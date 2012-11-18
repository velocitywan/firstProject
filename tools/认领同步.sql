declare
  htid        varchar2(36);
  htje        NUMBER(14, 2) := 0.00; ---合同总金额
  jkzje       NUMBER(14, 2) := 0.00; ---合同价款上总金额
  jfsj        Date; --新价款实际认领时间
  rlje        NUMBER(14, 2) := 0.00; -- 新价款认领金额
  ht06rid     varchar2(36); --新价款ID
  yrcounter   NUMBER(2); --- 合同已认领计数
  jkyrcounter NUMBER(2); ----价款已认领计数
  yrmxcounter NUMBER(2); ----pjf15认领明细计数
  htyrje      NUMBER(14, 2) := 0.00; ---合同上已认领的金额
  htyrcdje    NUMBER(14, 2) := 0.00; ---合同上冲单金额
  jkyrje      NUMBER(14, 2) := 0.00; ---价款上已认领的金额
  htmxyrje      NUMBER(14, 2) := 0.00; ---合同明细上已认领的金额
  htmxyrcdje    NUMBER(14, 2) := 0.00; ---合同明细上冲单金额
  cursor cur_ht06 is
    select h1.ht00, h1.ht0104, tbl.jkzje
      from ht01 h1
     inner join (select nvl(sum(ht0603), 0) as jkzje, ht00
                   from ht06
                  group by ht00) tbl
        on tbl.ht00 = h1.ht00
     where h1.ht0104 <> tbl.jkzje
       and h1.ht0128 = 1
       and h1.ht0129 = 1;
begin
  open cur_ht06;
  fetch cur_ht06
    into htid, htje, jkzje;
  while cur_ht06%found loop
    select get_guid() into ht06rid from dual;
    dbms_output.put_line('新增价款id:' || ht06rid);
    dbms_output.put_line('处理的合同id:' || htid);
    --得到认领金额、冲单金额
    select count(recordid)
      into yrcounter
      from pjf03
     where pjf0304 > 0
       and PJF0302 in
           (select ht00
              from ht01
             where ht00 = htid
                or HT0126 = htid
                or ht00 = (select ht0126 from ht01 where ht00 = htid));
    dbms_output.put_line('合同认领的记录条数:' || yrcounter);
    if (yrcounter > 0) then
      select (nvl(sum(pjf0304), 0)-nvl(sum(pjf0316), 0)) into htyrje 
        from pjf03
       where pjf0304 > 0
         and PJF0302 in
             (select ht00
                from ht01
               where ht00 = htid
                  or HT0126 = htid
                  or ht00 = (select ht0126 from ht01 where ht00 = htid));
    else
      htyrje := 0;
    end if;
    select count(recordid) into jkyrcounter from ht06 where ht00 = htid;
    dbms_output.put_line('合同下价款个数:' || to_char(jkyrcounter));
    if (jkyrcounter > 0) then
      select nvl(sum(ht0605), 0)
        into jkyrje
        from ht06
       where ht00 = htid
       group by ht00;
    else
      jkyrje := 0;
    end if;
    ---得到当前的价款应该认领的金额
    rlje := htyrje - jkyrje;
    jfsj := sysdate;
    insert into ht06
      (ht00,
       recordid,
       parentid,
       ht0601,
       ht0602,
       ht0603,
       ht0604,
       ht0605,
       ht0606,
       ht0607,
       ht0608)
    values
      (htid,
       ht06rid,
       htid,
       '从老系统过来的合同自动生成的价款',
       sysdate,
       htje - jkzje,
       null,
       rlje,
       '根据合同金额和认领数据自动建立的数据',
       ht06rid,
       0);
    dbms_output.put_line('-------------------------------------------------------------------------------');   
    fetch cur_ht06
      into htid, htje, jkzje;
  end loop;
  close cur_ht06;
end;
