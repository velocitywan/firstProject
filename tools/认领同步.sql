declare
  htid        varchar2(36);
  htje        NUMBER(14, 2) := 0.00; ---��ͬ�ܽ��
  jkzje       NUMBER(14, 2) := 0.00; ---��ͬ�ۿ����ܽ��
  jfsj        Date; --�¼ۿ�ʵ������ʱ��
  rlje        NUMBER(14, 2) := 0.00; -- �¼ۿ�������
  ht06rid     varchar2(36); --�¼ۿ�ID
  yrcounter   NUMBER(2); --- ��ͬ���������
  jkyrcounter NUMBER(2); ----�ۿ����������
  yrmxcounter NUMBER(2); ----pjf15������ϸ����
  htyrje      NUMBER(14, 2) := 0.00; ---��ͬ��������Ľ��
  htyrcdje    NUMBER(14, 2) := 0.00; ---��ͬ�ϳ嵥���
  jkyrje      NUMBER(14, 2) := 0.00; ---�ۿ���������Ľ��
  htmxyrje      NUMBER(14, 2) := 0.00; ---��ͬ��ϸ��������Ľ��
  htmxyrcdje    NUMBER(14, 2) := 0.00; ---��ͬ��ϸ�ϳ嵥���
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
    dbms_output.put_line('�����ۿ�id:' || ht06rid);
    dbms_output.put_line('����ĺ�ͬid:' || htid);
    --�õ�������嵥���
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
    dbms_output.put_line('��ͬ����ļ�¼����:' || yrcounter);
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
    dbms_output.put_line('��ͬ�¼ۿ����:' || to_char(jkyrcounter));
    if (jkyrcounter > 0) then
      select nvl(sum(ht0605), 0)
        into jkyrje
        from ht06
       where ht00 = htid
       group by ht00;
    else
      jkyrje := 0;
    end if;
    ---�õ���ǰ�ļۿ�Ӧ������Ľ��
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
       '����ϵͳ�����ĺ�ͬ�Զ����ɵļۿ�',
       sysdate,
       htje - jkzje,
       null,
       rlje,
       '���ݺ�ͬ�������������Զ�����������',
       ht06rid,
       0);
    dbms_output.put_line('-------------------------------------------------------------------------------');   
    fetch cur_ht06
      into htid, htje, jkzje;
  end loop;
  close cur_ht06;
end;
