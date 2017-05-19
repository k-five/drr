/************************************************/
/*            Version and License               */
/*												*/
/*       Copyright (C) Shakiba 2017             */
/*                                              */
/*       Source: github.com/k-five/drr.d        */
/*       License:                  Boost        */
/************************************************/

immutable char[ 5 ] __DRR_VERSION__ = "0.2.0";

/****************************/
/*     Standard Library     */
/****************************/

import std.array:	array;
import std.process:     browse;
import std.path:        baseName;
import std.stdio:	writeln, writef;
import std.conv:	to, ConvException;
import std.algorithm: 	copy, each, filter, map;
import core.exception:  RangeError, AssertError;
import std.string: 	split, empty, count, format, indexOf;
import std.file:        FileException, rename, remove, rmdirRecurse, dirEntries, SpanMode, isDir, isFile;
import std.regex:	regex, split, matchFirst, matchAll, replaceFirst, replaceAll, Regex, RegexException, Captures;

/******************************************/
/*            custom color                */
/******************************************/

immutable char[ 6 ]  reset_color      = "\033[m";
immutable char[ 10 ] green_color      = "\033[1;32m";
immutable char[ 10 ] red_color        = "\033[1;31m";
immutable char[ 20 ] file_colorize    = "\033[1;33mfile\033[m";
immutable char[ 20 ] dir_colorize     = "\033[1;34mdir \033[m";
immutable char[ 18 ] red_color_match  = "\033[1;31m$&\033[m";
immutable char[ 4 ]  prefix_and_match = "$`$&";

/***********************************/
/*          main function          */
/***********************************/

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
				browse("https://github.com/k-five/drr");
			break;

			default:
			break;
		}
	} catch( RangeError re ){
		get_help( "Error: missing the first argument" );
		return 0;
	}

	/*******************************/
	/* check the synopsis of input */
	/*******************************/

	bool rename_is_correct;
	bool remove_is_correct;
	immutable string rename_pattern = `^(?:rs|sr|[rs]|)(.)(?:(?!\1).)+\1(?:(?!\1).)*\1(?:[fdb](?:\1(?:g|gi|ig)(?:\1-?[1-9]\d?|)|))$`;
	immutable string remove_pattern = `^(?:rd|dr|[rd]|)!?(.)(?:(?!\1).)+\1(?:[fdb](?:\1(?:gi?|ig?)|))$`;

	try{
		rename_is_correct = !matchFirst( args[ 1 ], regex( rename_pattern ) ).empty;
		remove_is_correct = !matchFirst( args[ 1 ], regex( remove_pattern ) ).empty;
	} catch( RegexException regex_error ){
		writeln( "Error: ", regex_error.msg );
		return 0;
	}
	Captures!(string, uint ) delimiter = rename_is_correct ?  matchFirst( args[ 1 ], regex( rename_pattern ) ) : matchFirst( args[ 1 ], regex( remove_pattern ) );

	/****************************************************/
	/* find each part and initialize them appropriately */
	/****************************************************/

	string[] user_apply = [ "", "", "", "", "", "" ];
	int number_of_delimiter = 0;

	if( rename_is_correct || remove_is_correct ){
		string arg = args[ 1 ];

		try{
			split( arg, regex( delimiter[ 1 ] ) ).copy( user_apply );
			number_of_delimiter = arg.count( arg[ 2 ] );
		} catch( AssertError ar ){
			writeln( "Error: ", ar.msg );
			return 0;
		} catch( RegexException regex_error ){
			writeln( "Error: ", regex_error.msg );
			return 0;
		}

	} else {
		writeln( "Error in input-pattern" );
		return 0;
	}
	string[] files_and_dirs;

	immutable string action_flag  = user_apply[ 0 ];
	immutable string match        = user_apply[ 1 ];
	immutable string substitution = rename_is_correct ? user_apply[ 2 ] : "";
	immutable string recursive    = remove_is_correct ? user_apply[ 2 ] : user_apply[ 3 ];
	immutable string end_flag     = remove_is_correct ? user_apply[ 3 ] : user_apply[ 4 ];
	int       index               = 0;
	int       match_count         = 0;

    /********************************************/
    /* initializing the regex and related flags */
    /********************************************/

	Regex!(char) user_regex;
	string old_name;
        string old_name_colorize;
        string new_name;
        string new_name_colorize;
        string file_name;
	try{
		user_regex = regex( match, end_flag );
	}
	catch( RegexException regex_error ){
		writeln( "Error: ", regex_error.msg );
		return 0;
	}

	if( user_apply[ 5 ] != "" )
		index = to!int( user_apply[ 5 ] );

	immutable clone_index = index;
	immutable bool action_flag_for_rename = ( action_flag.indexOf( "s" ) != -1 && number_of_delimiter >= 3 );
	immutable bool action_flag_for_remove = action_flag.indexOf( "d" ) != -1;
	immutable bool end_flag_has_g         = end_flag.indexOf( "g" ) != -1;
	immutable bool not                    = action_flag.indexOf( "!" ) == -1;
	/*********************************************************************/
	/* find files and directories based on what the user has applied for */
	/*********************************************************************/

	if( rename_is_correct || remove_is_correct ){
		files_and_dirs =
		dirEntries( ".", ( action_flag.indexOf( "r" ) != -1 ? SpanMode.depth : SpanMode.shallow ), false )
			.filter!( file => ( not ? !file.name.matchAll( regex( match, end_flag ) ).empty() : file.name.matchAll( regex( match, end_flag ) ).empty() ) )
			.filter!( file => ( recursive == "b" ? !file.isSymlink : ( recursive == "f" ? !file.isDir : !file.isFile ) ) )
			.map!( file => file.name )
			.array;
	}

    /*************************************/
    /* setting up the auto zeros-leading */
    /*************************************/

    string str_argc = to!string( files_and_dirs.length );

    // string rename_format = format( "%%0%dd rename: %%s \033[1;36m>>\033[m ", str_argc.length );
    // string remove_format = format( "%%0%dd remove: %%s", str_argc.length );

	/*************************************************/
	/* main for loop, over all files and directories */
	/*************************************************/

	for( uint index_fd = 0; index_fd < files_and_dirs.length; ++index_fd ){
		file_name = action_flag.indexOf( "r" ) != -1 ? files_and_dirs[ index_fd ] : baseName( files_and_dirs[ index_fd ] );

		 old_name = file_name;
			if( index == 0 ){

				if ( end_flag_has_g ) {
					old_name_colorize = replaceAll( file_name, user_regex, red_color_match );

					new_name          = replaceAll( file_name, user_regex, substitution );
					new_name_colorize = replaceAll( file_name, user_regex, green_color ~ substitution ~ reset_color  );
				} else {
					old_name_colorize = replaceFirst( file_name, user_regex, red_color_match );

					new_name          = replaceFirst( file_name, user_regex, substitution );
					new_name_colorize = replaceFirst( file_name, user_regex, green_color ~ substitution ~ reset_color  );
				}

			} else { // if the input has a index-match, like: /one/two/g/3 or /one/two/g/-2

				new_name_colorize = file_name; // for sure when the index is out of range
				old_name_colorize = replaceAll( file_name, user_regex, red_color_match );

				foreach( regex_match ; matchAll( file_name, user_regex ) ){
					++match_count;
				}
				if( index < 0 ){
					index = match_count + index;
					match_count = 0;
				}
				foreach( regex_match ; matchAll( file_name, user_regex ) ){
					// string temp;
					if( !index-- ){
						new_name          = regex_match.pre ~ replaceFirst( regex_match.hit ~ regex_match.post, user_regex, substitution );
						new_name_colorize = regex_match.pre ~ replaceFirst( regex_match.hit ~ regex_match.post, user_regex, green_color ~ substitution ~ reset_color );
						// file_name = regex_match.pre ~ temp;
					}
				}

			}

			/***********************************************************/
			/*                   print and action                      */
			/***********************************************************/

			if( rename_is_correct ){	// such as: /one/two/
				writef( format( "%%0%dd rename (" ~ ( file_name.isFile? file_colorize : dir_colorize ) ~ "): %%s \033[1;36m>>\033[m ", str_argc.length ), index_fd + 1, old_name_colorize );

				// if user applied for renaming
				if( action_flag_for_rename && ( new_name != old_name ) ){
					string rename_state;
					try{
						rename( old_name, new_name  );
						rename_state = " [Succeed]";
					} catch( FileException file_error ){
						rename_state = " [" ~ ( file_error.msg ).split( ": " )[ 1 ] ~ "]";	// has an output like: [Operation not permitted]
					}
					writeln( new_name_colorize, rename_state );		                        // prints new_name plus [Success] or an appropriate Error
				} else {
					writeln( new_name_colorize );					                        // prints new_name plus a newline
				}

			} else if( remove_is_correct ) {    // such as: /one/gi
				writef( format( "%%0%dd remove: (" ~ ( file_name.isFile? file_colorize : dir_colorize ) ~ "): %%s", str_argc.length ), index_fd + 1, old_name_colorize );

				// if user applied for removing
				if( action_flag_for_remove ){
					string remove_state;
					try{
						old_name.isFile ? remove( old_name ) : rmdirRecurse( old_name );
						remove_state = " [Succeed]";
					} catch( FileException file_error ){
						remove_state = " [" ~ ( file_error.msg ).split( ": " )[ 1 ] ~ "]";	// has an output like: [Operation not permitted]
					}
					writeln( remove_state );	                                            // prints [Success] or an appropriate Error
				} else {
					writeln();					                                            // just newline
				}

			}
		index = clone_index;
	} // end of for-loop

	// end of the main
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
    ! = invert-match ( only-for-delete file )

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
    '!/_+/b'

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
invert-match only works with remove, not rename |
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
