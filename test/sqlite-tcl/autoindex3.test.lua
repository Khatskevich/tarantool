#!./tcltestrunner.lua

# 2014-06-17
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#
#*************************************************************************
#
# This file implements regression tests for SQLite library.  The
# focus of this script is testing automatic index creation logic,
# and specifically that an automatic index will not be created that
# shadows a declared index.
#

set testdir [file dirname $argv0]
source $testdir/tester.tcl
set testprefix autoindex3

# # The t1b and t2d indexes are not very selective.  It used to be that
# # the autoindex mechanism would create automatic indexes on t1(b) or
# # t2(d), make assumptions that they were reasonably selective, and use
# # them instead of t1b or t2d.  But that would be cheating, because the
# # automatic index cannot be any more selective than the real index.
# #
# # This test verifies that the cheat is no longer allowed.
# #
# do_execsql_test autoindex3-100 {
#   CREATE TABLE t1(a,b,x);
#   CREATE TABLE t2(c,d,y);
#   CREATE INDEX t1b ON t1(b);
#   CREATE INDEX t2d ON t2(d);
#   ANALYZE sqlite_master;
#   INSERT INTO sqlite_stat1 VALUES('t1','t1b','10000 500');
#   INSERT INTO sqlite_stat1 VALUES('t2','t2d','10000 500');
#   ANALYZE sqlite_master;
#   EXPLAIN QUERY PLAN SELECT * FROM t1, t2 WHERE d=b;
# } {~/AUTO/}

# # Automatic indexes can still be used if existing indexes do not
# # participate in == constraints.
# #
# do_execsql_test autoindex3-110 {
#   EXPLAIN QUERY PLAN SELECT * FROM t1, t2 WHERE d>b AND x=y;
# } {/AUTO/}
# do_execsql_test autoindex3-120 {
#   EXPLAIN QUERY PLAN SELECT * FROM t1, t2 WHERE d<b AND x=y;
# } {/AUTO/}
# do_execsql_test autoindex3-130 {
#   EXPLAIN QUERY PLAN SELECT * FROM t1, t2 WHERE d IS NULL AND x=y;
# } {/AUTO/}
# do_execsql_test autoindex3-140 {
#   EXPLAIN QUERY PLAN SELECT * FROM t1, t2 WHERE d IN (5,b) AND x=y;
# } {/AUTO/}

# reset_db
# do_execsql_test 210 {
#   CREATE TABLE v(b, d, e);
#   CREATE TABLE u(a, b, c);
#   ANALYZE sqlite_master;
#   INSERT INTO "sqlite_stat1" VALUES('u','uab','40000 400 1');
#   INSERT INTO "sqlite_stat1" VALUES('v','vbde','40000 400 1 1');
#   INSERT INTO "sqlite_stat1" VALUES('v','ve','40000 21');

#   CREATE INDEX uab on u(a, b);
#   CREATE INDEX ve on v(e);
#   CREATE INDEX vbde on v(b,d,e);

#   DROP TABLE IF EXISTS sqlite_stat4;
#   ANALYZE sqlite_master;
# }

# # At one point, SQLite was using the inferior plan:
# #
# #   0|0|1|SEARCH TABLE v USING INDEX ve (e>?)
# #   0|1|0|SEARCH TABLE u USING COVERING INDEX uab (ANY(a) AND b=?)
# #
# # on the basis that the real index "uab" must be better than the automatic
# # index. This is not right - a skip-scan is not necessarily better than an
# # automatic index scan.
# #
# do_eqp_test 220 {
#   select count(*) from u, v where u.b = v.b and v.e > 34;
# } {
#   0 0 1 {SEARCH TABLE v USING INDEX ve (e>?)} 
#   0 1 0 {SEARCH TABLE u USING AUTOMATIC COVERING INDEX (b=?)}
# }


finish_test
