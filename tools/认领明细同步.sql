declare
  htid       varchar2(36);
  pid        varchar2(36);
  pjf03rid   varchar2(36);
  pjf15rid   varchar2(36);
  htyrje     NUMBER(14, 2) := 0.00; ---合同上已认领的金额
  htyrcdje   NUMBER(14, 2) := 0.00; ---合同上冲单金额
  htmxyrje   NUMBER(14, 2) := 0.00; ---合同明细上已认领的金额
  htmxyrcdje NUMBER(14, 2) := 0.00; ---合同明细上冲单金额
  cursor cur_ht06 is
    select jf03.rlje, jf15.rlmxje, jf03.cdje, jf15.rlmxcdje, jf03.ht00
      from (select nvl(sum(pjf0304), 0) as rlje,
                   nvl(sum(pjf0316), 0) as cdje,
                   pjf0302 as ht00
              from pjf03
             group by pjf0302) jf03
     inner join (select nvl(sum(b.PJF1502), 0) as rlmxje,
                        nvl(sum(b.PJF1503), 0) as rlmxcdje,
                        a.pjf0302 as ht00
                   from pjf03 a
                  inner join pjf15 b
                     on a.recordid = b.parentid
                  group by a.pjf0302) jf15
        on jf03.ht00 = jf15.ht00
     where jf03.rlje <> jf15.rlmxje
        or jf03.cdje <> jf15.rlmxcdje;
begin
  open cur_ht06;
  fetch cur_ht06
    into htyrje, htmxyrje, htyrcdje, htmxyrcdje, htid;
  while cur_ht06%found loop
    dbms_output.put_line('处理的合同id:' || htid);
    select p00
      into pid
      from pjf03
     where pjf0302 = htid
       and rownum = 1;
    select recordid
      into pjf03rid
      from pjf03
     where pjf0302 = htid
       and rownum = 1;
    dbms_output.put_line('项目id:' || pid);
    delete from pjf15
     where parentid in (select recordid from pjf03 where pjf0302 = htid);
    insert into pjf15
      (p00, recordid, parentid, pjf1502, pjf1503, pjf1501)
      select pid, get_guid(), pjf03rid, ht0605, 0, recordid
        from ht06
       where ht00 = htid;
    if (htyrcdje > 0) then
      select recordid
        into pjf15rid
        from pjf15
       where parentid in (select recordid from pjf03 where pjf0302 = htid)
         and rownum = 1;
      insert into pjf15
        (p00, recordid, parentid, pjf1502, pjf1503, pjf1501)
        select pid, get_guid(), pjf03rid, -1 * htyrcdje, 0, pjf1501
          from pjf15
         where recordid = pjf15rid;
      update pjf15
         set pjf1502 = pjf1502 + htyrcdje, pjf1503 = htyrcdje
       where recordid = pjf15rid;
    end if;
    dbms_output.put_line('-------------------------------------------------------------------------------');
    fetch cur_ht06
      into htyrje, htmxyrje, htyrcdje, htmxyrcdje, htid;
  end loop;
  close cur_ht06;
end;
