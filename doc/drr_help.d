/************************************************/
/*            version and license               */
/*												*/
/*       Copyright (C) Shakiba 2017             */
/*                                              */
/*       source: github.com/k-five/drr          */
/*       License:                Boost          */
/************************************************/

immutable char[ 5 ] __DRR_VERSION__ = "0.1.0";

/****************************/
/*     Standard Library     */
/****************************/

import std.stdio:      writef, writeln;
import std.process:    browse;
import core.exception: RangeError;

int main( immutable string[] args ){

    if( args.length > 2 ){
        writeln( "No need to use more than one argument" );
        return 0;
    }

	try{
		switch( args[ 1 ] ){
			case "--help":
				get_help( "--help" );
			break;

			case "--example":
				example();
			break;

			case "--note":
				note();
			break;

			case "--source":
				browse("https://github.com/k-five/dren/");
			break;

			default:
			break;
		}
	} catch( RangeError re ){
		get_help( "Error: missing the first argument" );
	}

return 0;
}

void get_help( const string what = "get_help() was called" ){
const string usage =
"drr: \033[1;31mD-Language\033[m \033[1;32mRename\033[m and \033[1;32mRemove\033[m program utility
-------------------------------------------------
Usage:
    rename: '[1]/[2]/[3]/[4]/[5]/[6]'
    remove: '[1]/[2]/[4]/[5]'

    [1]:
    r = recursively
    s = substitute ( =renaming )
    d = delete     ( =removing )

    [2]:
    match = RegExp

    [3]:
    substitution = RegExp

    [4]:
    f = only-file
    d = only-directory
    b = both file and directory

    [5]:
    g = global matching
    i = case-sensitive matching

    [6]:
    [1 to 99]   = positive index-match
    [-1 to -99] = negative index-match

    More:
    drr --note ( see before doing anything )
    drr --help
    drr --example
    drr --source
-------------------------------------------------
Copyright (C) Shakiba 2017. License: Boost.
-------------------------------------------------
source and bug report:    github.com/k-five/drr.d";
	writeln( usage );
    writeln( "version: ", __DRR_VERSION__, '\n' );
    writeln( what );
}
void example(){
writeln(
`Ex:
rename:
    '/[RexExp]/[RexExp or string]/[b or f or d]'
    '/\d+/###/f'

    '/[RexExp]/[RexExp or string]/[b or f or d]/[g or i or gi or ig]'
    '/\d+/###/b/g'

    '[r or s or sr or rs]/[RexExp]/[RexExp or string]/[b or f or d]/[g or i or gi or ig]'
    'r/\d+/###/g'

    '/[RexExp]/[RexExp or string]/[b or f or d]/[g or or gi or ig]/[ -99 to 99 (except: 0) ]'
    'r/\d+/###/b/g/-1'

    '[r or s or sr or rs]/[RexExp]/[RexExp or string]/[b or f or d]/[g or gi or ig]/[ -99 to 99 (except: 0) ]'
    'rs/\d+/###/b/g/2'

remove:
    '/[RegExp]/[b or f or d]'
    '/_+/b'

    '/[RegExp]/[b or f or d]/[g or i or gi or ig]'
    '/_+/b/g'

    '[r or d or dr or rd]/[RegExp]/[b or f or d]/[g or i or gi or ig]'
    'rd/_+/b/g'
`,
`

--example`
);
}
void note(){
writeln(
`------------------------------------------------+
Delimiter is free that meas it is up to you     |
-------------------------------------------------
0 for index-match does not allowed              |
-------------------------------------------------
without 's' flag or 'd' flag at the beginning,  |
program only prints and has no action. After you|
made sure that the output is what you want then |
use 's' for renaming or 'd' for removing.       |

With 'r' flag, name of the file or dir returns  |
based on absolute path. Be careful with matching|
------------------------------------------------+`
,
`

--note`);
}

