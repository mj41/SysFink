package SysFink::ScanData;

use strict;
use warnings;


sub get_test_test_cases {

        my $default_flags = {
           'S' => '-',
           'B' => '-',
           'H' => '-',
           'M' => '+',
           'D' => '-',
           'G' => '-',
           'L' => '-',
           'U' => '-',
           '5' => '+'
        };

        my $skip_flags = {
           'S' => '-',
           'B' => '-',
           'H' => '-',
           'M' => '-',
           'D' => '-',
           'G' => '-',
           'L' => '-',
           'U' => '-',
           '5' => '-'
        };

    my @all_test_cases = ();

    # --- test 1 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = 'two simple items';

        $test_case->{test_obj_conf} = [
            '/',
            '/etc/',
            '/myfile',
        ];

        $test_case->{paths_to_scan} = [
            [ '', $default_flags, ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/'
            },
            {
                'mode' => 16877,
                'path' => '/etc'
            },
            {
                'hash' => 'HASH:/myfile',
                'mode' => 33188,
                'path' => '/myfile'
            },
        ];

        push @all_test_cases, $test_case;
    }


    # --- test 2 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = 'more items, mode modification';

        $test_case->{test_obj_conf} = [
            '/',
            '/etc/',
            '/etc/passwd',
            '/home/',
            '/tmp/',
            [ '/tmp/myfile', { mode => 16876, }, ],
        ];

        $test_case->{paths_to_scan} = [
            [ '', $default_flags, ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/'
            },
            {
                'mode' => 16877,
                'path' => '/etc'
            },
            {
                'mode' => 16877,
                'path' => '/home'
            },
            {
                'mode' => 16877,
                'path' => '/tmp'
            },
            {
                'hash' => 'HASH:/etc/passwd',
                'mode' => 33188,
                'path' => '/etc/passwd'
            },
            {
                'mode' => 16876,
                'path' => '/tmp/myfile'
            },
        ];

        push @all_test_cases, $test_case;
    }


    # --- test 3 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = 'skip some items';

        $test_case->{test_obj_conf} = [
            '/',
            '/etc/',
            '/home/',
            '/home/file1',
            '/home/mjdir/',
            '/home/mjdir/sfile2',
            '/tmp/',
            '/tmp/somefile',
            '/tmp/sdir/',
        ];

        my $my_flags = { %$default_flags };
        $my_flags->{5} = '-';
        $test_case->{paths_to_scan} = [
            [ '', $my_flags ],
            [ '/home/mjdir', { '5' => '+' } ],
            [ '/tmp', $skip_flags ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/'
            },
            {
                'mode' => 16877,
                'path' => '/etc'
            },
            {
                'mode' => 16877,
                'path' => '/home'
            },
            {
                'mode' => 33188,
                'path' => '/home/file1'
            },
            {
                'mode' => 16877,
                'path' => '/home/mjdir'
            },
            {
                'hash' => 'HASH:/home/mjdir/sfile2',
                'mode' => 33188,
                'path' => '/home/mjdir/sfile2'
            },
        ];
        push @all_test_cases, $test_case;
    }


    # --- test 4 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = 'items included inside excluded dir, root dir excluded';

        $test_case->{test_obj_conf} = [
            '/',
            '/etc/',
            '/home/',
            '/home/file1',
            '/home/mjdir/',
            '/home/mjdir/subfile2no',
            '/home/mjdir/subfile3yes',
            '/home/mjdir/subdir/',
            '/home/mjdir/subdir/subfile4yes',
            '/home/mjdir/asdir1/',
            '/home/mjdir/asdir1/asdir2/',
            '/home/mjdir/asdir1/asdir2/sfile5no',
            '/home/mjdir/asdir1/asdir2/asdir3/',
            '/home/mjdir/asdir1/asdir2/asdir3/sfile6yes',
            '/home/mjdir/asdir1/asdir2/asdir3/sfile7no',
            '/tmp/',
            '/tmp/somefile',
            '/tmp/sdir/',
        ];

        my $my_flags = { %$default_flags };
        $my_flags->{5} = '-';
        $test_case->{paths_to_scan} = [
            [ '', $skip_flags ],
            [ '/', $my_flags ],
            [ '/home/mjdir', $skip_flags ],
            [ '/home/mjdir/subfile3yes', { '5' => '+' } ],
            [ '/home/mjdir/asdir1/asdir2/asdir3/sfile6yes', { '5' => '+' } ],
            [ '/home/mjdir/subdir', { '5' => '+' } ],
            [ '/tmp', $skip_flags ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/etc'
            },
            {
                'mode' => 16877,
                'path' => '/home'
            },
            {
                'mode' => 33188,
                'path' => '/home/file1'
            },
            {
                'hash' => 'HASH:/home/mjdir/asdir1/asdir2/asdir3/sfile6yes',
                'mode' => 33188,
                'path' => '/home/mjdir/asdir1/asdir2/asdir3/sfile6yes'
            },
            {
                'mode' => 16877,
                'path' => '/home/mjdir/subdir'
            },
            {
                'hash' => 'HASH:/home/mjdir/subdir/subfile4yes',
                'mode' => 33188,
                'path' => '/home/mjdir/subdir/subfile4yes'
            },
            {
                'hash' => 'HASH:/home/mjdir/subfile3yes',
                'mode' => 33188,
                'path' => '/home/mjdir/subfile3yes'
            },
        ];
        push @all_test_cases, $test_case;
    }


    # --- test 5 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = "dir vs. dir's content, duplicated conf";

        $test_case->{test_obj_conf} = [
            '/',
            '/aroot-file1',
            '/home/',
            '/home/file2',
            '/home/mjdir/',
            '/home/mjdir/fileC',
            '/home/mjdir/subdirA/',
            '/home/mjdir/subdirA/file3',
            '/home/mjdir/subdirA/subdirB1/',
            '/home/mjdir/subdirA/subdirB1/file4',
            '/home/mjdir/subdirA/subdirB1/file5',
            '/home/mjdir/subdirA/subdirB2/',
            '/home/mjdir/subdirA/subdirB2/file6',
            '/home/mjdir/subdirA/subdirB2/file7',
            '/home/mjdir/subdirA/subdirB3/',
            '/home/mjdir/subdirA/subdirB3/file8',
            '/home/mjdir/subdirA/subdirB3/file9',
            '/tmp/',
            '/tmp/tmp.11',
        ];

        my $my_flags = { %$default_flags };
        $my_flags->{5} = '-';
        $test_case->{paths_to_scan} = [
            [ '', $my_flags ],
            [ '/', $skip_flags ],

            # duplicated conf
            [ '/home', $my_flags ],
            [ '/home/mjdir/', $skip_flags ],
            [ '/home', $my_flags ],
            [ '/home/mjdir/', $skip_flags ],

            [ '/home/mjdir/subdirA/subdirB1', $my_flags ],
            [ '/home/mjdir/subdirA/subdirB2/', $skip_flags ],
            [ '/home/mjdir/subdirA/subdirB3', $my_flags ],
            [ '/home/mjdir/subdirA/subdirB3/', $skip_flags ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/'
            },
            {
                'mode' => 16877,
                'path' => '/home'
            },
            {
                'mode' => 33188,
                'path' => '/home/file2'
            },
            {
                'mode' => 16877,
                'path' => '/home/mjdir'
            },
            {
                'mode' => 16877,
                'path' => '/home/mjdir/subdirA/subdirB1'
            },
            {
                'mode' => 33188,
                'path' => '/home/mjdir/subdirA/subdirB1/file4'
            },
            {
                'mode' => 33188,
                'path' => '/home/mjdir/subdirA/subdirB1/file5'
            },
            {
                'mode' => 16877,
                'path' => '/home/mjdir/subdirA/subdirB3'
            }
        ];
        push @all_test_cases, $test_case;
    }


    # --- test 6 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = 'two simple items';

        $test_case->{test_obj_conf} = [
            '/',
            '/etc/',
            '/myfile',
        ];

        $test_case->{paths_to_scan} = [
            [ '', $default_flags, ],
            [ '/unknow-name-xyz', $default_flags, ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/'
            },
            {
                'mode' => 16877,
                'path' => '/etc'
            },
            {
                'hash' => 'HASH:/myfile',
                'mode' => 33188,
                'path' => '/myfile'
            },
        ];

        push @all_test_cases, $test_case;
    }


    # --- test 7 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = 'dirs and regexes';

        my $my_flags = { %$default_flags };
        $my_flags->{5} = '-';

        $test_case->{test_obj_conf} = [
            '/',

            '/aall/',
            '/aall/file-yes',

            '/afoo/',
            '/afoo/file-no-X',
            '/afoo/fileA',
            '/afoo/fileBB',

            '/bar/',
            '/bar/no-file',

            '/bazz/',
            '/bazz/fileX',
            '/bazz/fileYY',
            '/bazz/file-no',
        ];

        $test_case->{paths_to_scan} = [
            [ '', $skip_flags, ],

            [ '/aall',        $my_flags, ],

            [ '/afoo/file?',  $my_flags, ],
            [ '/afoo/file??', $my_flags, ],

            [ '/bazz',        $skip_flags, ],
            [ '/bazz/file?',  $my_flags, ],
            [ '/bazz/file??', $my_flags, ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/aall'
            },
            {
                'mode' => 33188,
                'path' => '/aall/file-yes'
            },
            {
                'mode' => 33188,
                'path' => '/afoo/fileA'
            },
            {
                'mode' => 33188,
                'path' => '/afoo/fileBB'
            },
            {
                'mode' => 33188,
                'path' => '/bazz/fileX'
            },
            {
                'mode' => 33188,
                'path' => '/bazz/fileYY'
            }
        ];

        push @all_test_cases, $test_case;
    }


    # --- test 8 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = "more regexes";

        $test_case->{test_obj_conf} = [
            '/',

            '/part1/',
            '/part1/okfile',
            '/part1/okfileA',
            '/part1/okfileXX',
            '/part1/bad-file',

            '/part2/',
            '/part2/okfile',
            '/part2/okfileA',
            '/part2/okfileBB',
            '/part2/okfileXXX',
            '/part3/bad-file',

            '/part3/',
            '/part3/okfile',
            '/part3/okfileA',
            '/part3/okfileBB',
            '/part3/okfileCCC',
            '/part3/bad-file',

            '/part4/',
            '/part4/okfile',
            '/part4/okfile-xA',
            '/part4/okfile-yBBB',
            '/part4/bad-file',
            
            '/part5/',
            '/part5/subdirA/',
            '/part5/subdirA/okfile',
            '/part5/subdirA/okfileA',
            '/part5/subdirA/okfileXX',
            '/part5/subdirA/bad-file',
            '/part5/subdirB/',
            '/part5/subdirB/okfile',
            '/part5/subdirB/okfileA',
            '/part5/subdirB/okfileXX',
            '/part5/subdirB/bad-file',
            '/part5/subdirB/bad-subsubdir/',
            '/part5/subdirB/bad-subsubdir/okfile',

            # part 6
            '/part6/',
            '/part6/bad-file-ok',
            '/part6/ok-a1-ok',
            '/part6/ok-a2-ok',
            '/part6/ok-bad',

            '/part6/bad-subdir/',
            '/part6/bad-subdir/bad',
            '/part6/bad-subdir/bad-ok',
            '/part6/bad-subdir/ok-bad-ok',

            '/part6/ok-subdir/',
            '/part6/ok-subdir/b1-ok',
            '/part6/ok-subdir/bad-y',
            '/part6/ok-subdir/b2-ok',

            '/part6/ok-subdir/ok-subsubdir-ok/',

            '/part6/ok-subdir/ok-subsubdir/',
            '/part6/ok-subdir/ok-subsubdir/c3-ok',
            '/part6/ok-subdir/ok-subsubdir/bad-z',
        ];

        my $my_flags = { %$default_flags };
        $my_flags->{5} = '-';
        $test_case->{paths_to_scan} = [
            [ '', $skip_flags ],
            [ '/part1/okfile?',   $my_flags ],
            [ '/part2/okfile??',  $my_flags ],
            [ '/part3/okfile*',   $my_flags ],
            [ '/part4/okfile-x?', $my_flags ],
            [ '/part4/okfile-y*', $my_flags ],
            [ '/part5/*/okfile?', $my_flags ],
            [ '/part6/ok-**-ok',  $my_flags ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 33188,
                'path' => '/part1/okfile'
            },
            {
                'mode' => 33188,
                'path' => '/part1/okfileA'
            },

            {
                'mode' => 33188,
                'path' => '/part2/okfile'
            },
            {
                'mode' => 33188,
                'path' => '/part2/okfileA'
            },
            {
                'mode' => 33188,
                'path' => '/part2/okfileBB'
            },

            {
                'mode' => 33188,
                'path' => '/part3/okfile'
            },
            {
                'mode' => 33188,
                'path' => '/part3/okfileA'
            },
            {
                'mode' => 33188,
                'path' => '/part3/okfileBB'
            },
            {
                'mode' => 33188,
                'path' => '/part3/okfileCCC'
            },

            {
                'mode' => 33188,
                'path' => '/part4/okfile-xA'
            },
            {
                'mode' => 33188,
                'path' => '/part4/okfile-yBBB'
            },

            {
                'mode' => 33188,
                'path' => '/part5/subdirA/okfile'
            },
            {
                'mode' => 33188,
                'path' => '/part5/subdirA/okfileA'
            },
            {
                'mode' => 33188,
                'path' => '/part5/subdirB/okfile'
            },
            {
                'mode' => 33188,
                'path' => '/part5/subdirB/okfileA'
            },

            {
                'mode' => 33188,
                'path' => '/part6/ok-a1-ok'
            },
            {
                'mode' => 33188,
                'path' => '/part6/ok-a2-ok'
            },
            {
                'mode' => 33188,
                'path' => '/part6/ok-subdir/b1-ok'
            },
            {
                'mode' => 33188,
                'path' => '/part6/ok-subdir/b2-ok'
            },
            {
                'mode' => 16877,
                'path' => '/part6/ok-subdir/ok-subsubdir-ok'
            },
            {
                'mode' => 33188,
                'path' => '/part6/ok-subdir/ok-subsubdir/c3-ok'
            },

        ];
        push @all_test_cases, $test_case;
    }


    # --- test 9 -----------------------------------------------------------------
    {
        my $test_case = {};
        $test_case->{tescase_name} = "recursive, regex and flags' inheritance";

        $test_case->{test_obj_conf} = [
            '/',

            '/dirA/',
            '/dirA/file-base',
            '/dirA/file-re1',
            '/dirA/file-re1B',
            '/dirA/file-re2',
            '/dirA/file-yy',

            '/dirA/dir-no/',
            '/dirA/dir-no/file-re1',
            '/dirA/dir-no/file-re1B',
            '/dirA/dir-no/file-yy',

            '/dirB/',
            '/dirB/file-base',
            '/dirB/file-re1',
            '/dirB/file-re1B',
            '/dirB/file-re2',

            '/dirB/dir-no/',
            '/dirB/dir-no/file-re1',
            '/dirB/dir-no/file-re1B',
            '/dirB/dir-no/file-yy',

            '/x-reMA/',
            '/x-reMA/re1/',
            '/x-reMA/re1/re2/',
            '/x-reMA/re1/re2/reMB-x',
            '/x-reMA/re1/re2/reMB-x',
            '/x-reMA/re1/re2/reMB/',
            '/x-reMA/re1/re2/reMB/reMPP-x',
        ];

        my $my_flags = { %$default_flags };
        $my_flags->{5} = '-';
        $test_case->{paths_to_scan} = [
            [ '', $my_flags, ],

            [ '/**reMA**',      $skip_flags, ],

            [ '/**re1**',       { 'U' => '+' }, ],
            [ '/**re2**',       { 'G' => '+' }, ],

            [ '/**reMB**',      { 'G' => '-', 'U' => '-', }, ],
            [ '/**reMPP**',     { 'G' => '+', }, ],

            [ '/dirA/',         { 'U' => '+' }, ],
            [ '/dirA/dir-no',   $skip_flags, ],

            [ '/**re1B**',      { 'U' => '-' }, ],

            [ '/dirB/',         { 'G' => '-' }, ],
            [ '/dirB/dir-no/',  $skip_flags, ],
        ];

        $test_case->{expected} = [
            {
                'mode' => 16877,
                'path' => '/'
            },
            {
                'mode' => 16877,
                'path' => '/dirA'
            },
            {
                'mode' => 16877,
                'path' => '/dirB'
            },
            {
                'uid' => 1,
                'mode' => 33188,
                'path' => '/dirA/file-base',
                'user_name' => 'bin'
            },
            {
                'uid' => 1,
                'mode' => 33188,
                'path' => '/dirA/file-re1',
                'user_name' => 'bin'
            },
            {
                'mode' => 33188,
                'path' => '/dirA/file-re1B'
            },
            {
                'group_name' => 'bin',
                'uid' => 1,
                'mtime' => 1251747432,
                'mode' => 33188,
                'path' => '/dirA/file-re2',
                'gid' => 1,
                'user_name' => 'bin'
            },
            {
                'uid' => 1,
                'mode' => 33188,
                'path' => '/dirA/file-yy',
                'user_name' => 'bin'
            },
            {
                'uid' => 1,
                'mode' => 33188,
                'path' => '/dirA/dir-no/file-re1',
                'user_name' => 'bin'
            },
            {
                'mode' => 16877,
                'path' => '/dirB/dir-no'
            },
            {
                'mode' => 33188,
                'path' => '/dirB/file-base'
            },
            {
                'uid' => 1,
                'mode' => 33188,
                'path' => '/dirB/file-re1',
                'user_name' => 'bin'
            },
            {
                'mode' => 33188,
                'path' => '/dirB/file-re1B'
            },
            {
                'group_name' => 'bin',
                'mtime' => 1251747432,
                'mode' => 33188,
                'path' => '/dirB/file-re2',
                'gid' => 1
            },
            {
                'uid' => 1,
                'mode' => 33188,
                'path' => '/dirB/dir-no/file-re1',
                'user_name' => 'bin'
            },
            {
                'uid' => 1,                     # re1 +U
                'mode' => 16877,
                'path' => '/x-reMA/re1',
                'user_name' => 'bin'            # re1 +U
            },
            {
                'group_name' => 'bin',          # re2 +G
                'uid' => 1,                     # re1 +U
                'mtime' => 1251747432,
                'mode' => 16877,
                'path' => '/x-reMA/re1/re2',
                'gid' => 1,                     # re2 +G
                'user_name' => 'bin'            # re1 +U
            },
            {
                'group_name' => 'bin',          # reMPP +G
                'mtime' => 1251747432,
                'mode' => 33188,
                'path' => '/x-reMA/re1/re2/reMB/reMPP-x',
                'gid' => 1                      # reMPP +G
            }        
        ];

        push @all_test_cases, $test_case;
    }

    return @all_test_cases;
}

1;