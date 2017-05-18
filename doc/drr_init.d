/************************************************/
/*            version and license               */
/*						*/
/*       Copyright (C) Shakiba 2017             */
/*                                              */
/*       source: github.com/k-five/drr          */
/*       License:                Boost          */
/************************************************/

immutable char[ 5 ] __DRR_VERSION__ = "0.1.0";

/****************************/
/*     Standard Library     */
/****************************/

import std.array:        array;
import std.path:         baseName;
import core.exception:   AssertError;
import std.stdio:        writeln, writef;
import std.conv:         to, ConvException;
import std.algorithm:    copy, each, filter, map;
import std.string:       split, empty, count, format, indexOf;
import std.file:         FileException, rename, remove, dirEntries, SpanMode, isDir, isFile;
import std.regex:        match, regex, split, matchFirst, matchAll, replaceFirst, replaceAll, Regex, RegexMatch, Captures, RegexException;


/******************************************/
/*            custom color                */
/******************************************/

immutable char[ 6 ]  reset_color     = "\033[m";
immutable char[ 10 ] green_color     = "\033[1;32m";
immutable char[ 10 ] red_color       = "\033[1;31m";
immutable char[ 20 ] file_colorize   = "\033[1;33mfile\033[m";
immutable char[ 20 ] dir_colorize    = "\033[1;34mdir \033[m";
immutable char[ 18 ] red_color_match = "\033[1;31m$&\033[m";
immutable char[ 4 ] prefix_and_match = "$`$&";

/***********************************/
/*          main function          */
/***********************************/

int main( immutable string[] args ){
	
	if( args.length < 2 ){
        writeln( "ERROR: missing the first argument" );
        return 0;
	}
        		
	bool rename_is_correct;
	bool remove_is_correct;
	immutable string rename_pattern = `^(?:rs|sr|[rs]|)(.)(?:(?!\1).)+\1(?:(?!\1).)*\1(?:[fdb](?:\1(?:g|gi|ig)(\1-?[1-9]\d?)|)|)$`;
	immutable string remove_pattern = `^(?:rd|dr|[rd]|)(.)(?:(?!\1).)+\1(?:[fdb](?:\1(?:gi?|ig?)|)|)$`;

	try{
		rename_is_correct = !matchFirst( args[ 1 ], regex( rename_pattern ) ).empty;
		remove_is_correct = !matchFirst( args[ 1 ], regex( remove_pattern ) ).empty;
	} catch( RegexException rxe ){
		writeln( "Error: ", rxe.msg );
		return 0;
	}

	Captures!(string, uint ) delimiter = rename_is_correct ?  matchFirst( args[ 1 ], regex( rename_pattern ) ) : matchFirst( args[ 1 ], regex( remove_pattern ) );

	
	string[] user_apply = [ "", "", "", "", "", "" ];
	int number_of_delimiter = 0;
	
	if( rename_is_correct || remove_is_correct ){
		string arg = args[ 1 ];
		
		immutable bool r = arg[ 0 ] == 'r';
		immutable bool s = arg[ 0 ] == 's';
		immutable bool d = arg[ 0 ] == 'd';
		
		immutable bool rs = arg[ 0 ] == 'r' && arg[ 1 ] == 's';
		immutable bool sr = arg[ 0 ] == 's' && arg[ 1 ] == 'r';
		
		immutable bool rd = arg[ 0 ] == 'r' && arg[ 1 ] == 'd';
		immutable bool dr = arg[ 0 ] == 'd' && arg[ 1 ] == 'r';
		
		try{
			if( rs || sr || dr || rd ){
				split( arg, regex( to!string( arg[ 2 ] ) ) ).copy( user_apply );
				number_of_delimiter = arg.count( arg[ 2 ] );
			} else if( r || s || d ){
				split( arg, regex( to!string( arg[ 1 ] ) ) ).copy( user_apply );
				number_of_delimiter = arg.count( arg[ 1 ] );
			} else {
				split( arg, regex( to!string( arg[ 0 ] ) ) ).copy( user_apply );
				number_of_delimiter = arg.count( arg[ 0 ] );
			}
		} catch( AssertError ar ){
			writeln( "Error: ", ar.msg );
			return 0;
		} catch( RegexException rxe ){
			writeln( "Error: ", rxe.msg );
			return 0;
		}
		/*
		foreach( item; user_apply ){
			writeln( "item: ", item );
		}
		*/
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
	
	if( user_apply[ 5 ] != "" )
		index = to!int( user_apply[ 5 ] );
		
	immutable clone_index = index;
	immutable bool action_flag_for_rename = ( action_flag == "s" || action_flag == "rs" ) && number_of_delimiter >= 3;
	immutable bool action_flag_for_remove = ( action_flag == "d" || action_flag == "rd" );
	
	
	writeln( "--------------------------" );
	writeln( "action_flag: ", action_flag );
	writeln( "match      : ", match );
	writeln( "subs       : ", substitution );
	writeln( "recursive  : ", recursive );
	writeln( "end_flag   : ", end_flag );
	writeln( "index      : ", index );
	writeln( "n-delimiter: ", number_of_delimiter );
	writeln( "c-delimiter: ", delimiter[ 1 ] );
	writeln( "--------------------------" );
	writeln( "rename     : ", rename_is_correct );
	writeln( "remove     : ", remove_is_correct );
		
return 0;
}
