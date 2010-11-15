CREATE OR REPLACE PACKAGE XT_PIVOT IS
/**
 * Modification of Tom Kyte's package for pivot on oracle <11g
 * http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:766825833740#14642820392307
 */

 FUNCTION pivot_sql (
                     p_max_cols_query IN VARCHAR2 DEFAULT NULL
                    , p_query IN VARCHAR2
                    , p_anchor IN varchar2_table
                    , p_pivot IN varchar2_table
                    , p_pivot_head_sql IN varchar2_table DEFAULT varchar2_table()
                    )
 RETURN VARCHAR2;

 FUNCTION pivot_ref (
                        p_max_cols_query IN VARCHAR2 DEFAULT NULL
                     , p_query IN VARCHAR2
                     , p_anchor IN varchar2_table
                     , p_pivot IN varchar2_table
                     , p_pivot_name IN varchar2_table DEFAULT varchar2_table()
                     )
 RETURN sys_refcursor;

END XT_PIVOT;
/
CREATE OR REPLACE PACKAGE BODY XT_PIVOT IS
/**
* Function returning query
*/
 FUNCTION pivot_sql (
                     p_max_cols_query IN VARCHAR2 DEFAULT NULL
                    , p_query IN VARCHAR2
                    , p_anchor IN varchar2_table
                    , p_pivot IN varchar2_table
                    , p_pivot_head_sql IN varchar2_table
                    ) RETURN VARCHAR2
                    IS
    l_max_cols NUMBER;
    l_query VARCHAR2(4000);
    l_pivot_name varchar2_table:=varchar2_table();
    k INTEGER;
    c1 sys_refcursor;
    v VARCHAR2(30);
 BEGIN
    -- Getting columns count
    IF (p_max_cols_query IS NOT NULL) THEN
     EXECUTE IMMEDIATE p_max_cols_query
        INTO l_max_cols;
    ELSE
     raise_application_error (-20001, 'Cannot figure out max cols');
    END IF;

    -- Concatenating our query
    l_query := 'select ';

    FOR i IN 1 .. p_anchor.COUNT LOOP
     l_query := l_query || p_anchor (i) || ',';
    END LOOP;
    --Getting columns headers
    k:=1;
    IF p_pivot_head_sql.COUNT=p_pivot.COUNT
     THEN
         FOR j IN 1 .. p_pivot.COUNT LOOP
            OPEN c1 FOR p_pivot_head_sql(j);
            LOOP
             FETCH c1 INTO v;
             l_pivot_name.extend(1);
             l_pivot_name(k):=v;
             EXIT WHEN c1%NOTFOUND;
             k:=k+1;
            END LOOP;
         END LOOP;
    END IF;

    -- Adding columns headers
    -- as "max(decode(rn,1,C{X+1},null)) c_name+1_1"
    FOR i IN 1 .. l_max_cols LOOP
     FOR j IN 1 .. p_pivot.COUNT LOOP
        l_query := l_query || 'max(decode(rn,' || i || ',' || p_pivot (j) || ',null)) '
                  ||'"' ||l_pivot_name ((j-1)*l_max_cols+i) ||'"'|| ',';
     END LOOP;
    END LOOP;

    -- adding original query
    l_query := RTRIM (l_query, ',') || ' from ( ' || p_query || ') group by ';

    -- groupping
    FOR i IN 1 .. p_anchor.COUNT LOOP
     l_query := l_query || p_anchor (i) || ',';
    END LOOP;

    l_query := RTRIM (l_query, ',');

    -- returning query
    RETURN l_query;
 END;

/**
* Function returns cursor with pivotted query
*/
 FUNCTION pivot_ref (
                     p_max_cols_query IN VARCHAR2 DEFAULT NULL
                    , p_query IN VARCHAR2
                    , p_anchor IN varchar2_table
                    , p_pivot IN varchar2_table
                    , p_pivot_name IN varchar2_table
                    ) RETURN sys_refcursor
                    IS
    p_cursor sys_refcursor;
 BEGIN
    EXECUTE IMMEDIATE 'alter session set cursor_sharing=force';
    OPEN p_cursor FOR pkg_pivot.pivot_sql (
                     p_max_cols_query
                    , p_query
                    , p_anchor
                    , p_pivot
                    , p_pivot_name
                    );
    EXECUTE IMMEDIATE 'alter session set cursor_sharing=exact';
    RETURN p_cursor;
 END;
END XT_PIVOT;
/
