set timing on linesize 100 pages 50
col solutions for a12

CREATE TABLE numbers(c NUMBER);
INSERT INTO numbers (c) VALUES (1);
INSERT INTO numbers (c) VALUES (2);
INSERT INTO numbers (c) VALUES (3);
INSERT INTO numbers (c) VALUES (4);

rem this query can solve 4by4 kenken puzzles
rem ensure that the NUMBERS table has four rows with values 1-4.

select a.c || ' ' || b.c || ' ' || c.c || ' ' || d.c || chr(10) ||
       e.c || ' ' || f.c || ' ' || g.c || ' ' || h.c || chr(10) ||
	   i.c || ' ' || j.c || ' ' || k.c || ' ' || l.c || chr(10) ||
	   m.c || ' ' || n.c || ' ' || o.c || ' ' || p.c as solutions
  from numbers a,
       numbers b,
       numbers c,
       numbers d,
       numbers e,
       numbers f,
       numbers g,
       numbers h,
       numbers i,
       numbers j,
       numbers k,
       numbers l,
       numbers m,
       numbers n,
       numbers o,
       numbers p
 where a.c <> b.c and a.c <> c.c and a.c <> d.c
   and b.c <> c.c and b.c <> d.c
   and c.c <> d.c
   and e.c <> f.c and e.c <> g.c and e.c <> h.c
   and f.c <> g.c and f.c <> h.c
   and g.c <> h.c
   and i.c <> j.c and i.c <> k.c and i.c <> l.c
   and j.c <> k.c and j.c <> l.c
   and k.c <> l.c
   and m.c <> n.c and m.c <> o.c and m.c <> p.c
   and n.c <> o.c and n.c <> p.c
   and o.c <> p.c
   and a.c <> e.c and a.c <> i.c and a.c <> m.c
   and e.c <> i.c and e.c <> m.c
   and i.c <> m.c
   and b.c <> f.c and b.c <> j.c and b.c <> n.c
   and f.c <> j.c and f.c <> n.c
   and j.c <> n.c
   and c.c <> g.c and c.c <> k.c and c.c <> o.c
   and g.c <> k.c and g.c <> o.c
   and k.c <> o.c
   and d.c <> h.c and d.c <> l.c and d.c <> p.c
   and h.c <> l.c and h.c <> p.c
   and l.c <> p.c
   and 1=1 --  add puzzle specific clues here
--   and a.c = 2
   and abs (e.c - i.c) = 3
   and b.c + c.c + f.c = 9
   and m.c + n.c + j.c = 8
   and d.c * g.c * h.c = 12
/
