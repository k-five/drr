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

import std.array:		array;
import std.path:        baseName;
import std.stdio:	    writeln, writef;
import std.conv:		to, ConvException;
import std.algorithm: 	copy, each, filter, map;
import std.string: 		split, empty, count, format, indexOf;
import std.file:	    FileException, rename, remove, dirEntries, SpanMode, isDir, isFile;
import std.regex:		match, regex, split, matchFirst, matchAll, replaceFirst, replaceAll, Regex;

/******************************************/
/*            custom color                */
/******************************************/

immutable char[ 6 ]  reset_color = "\033[m";
immutable char[ 10 ] green_color = "\033[1;32m";
immutable char[ 10 ] red_color   = "\033[1;31m";
immutable char[ 20 ] file_colorize = "\033[1;33mfile\033[m";
immutable char[ 20 ] dir_colorize  = "\033[1;34mdir \033[m";
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
	
	/*******************************/
	/* check the synopsis of input */
	/*******************************/
	
	bool recursively_reanme =
	!match( args[ 1 ], regex( `^(?:r|s|rs)?([|@#\/])(?:(?!\1).)+\1(?:(?!\1).)*\1(?:[fdb](?:\1(?:g|gi|ig)(\1-?[1-9]\d?)?)?)$` ) ).empty;
	
	bool recursively_remove =
	!match( args[ 1 ], regex( `^(?:r|d|rd)?([|@#\/])(?:(?!\1).)+\1(?:[fdb](?:\1(?:gi?|ig?))?)$` ) ).empty;
	
	/****************************************************/
	/* find each part and initialize them appropriately */
	/****************************************************/
	
	string[] user_apply = [ "", "", "", "", "", "" ];
	int number_of_delimiter = 0;
	
	if( recursively_reanme || recursively_remove ){
		string arg = args[ 1 ];
		
		immutable bool r = arg[ 0 ] == 'r';
		immutable bool s = arg[ 0 ] == 's';
		immutable bool d = arg[ 0 ] == 'd';
		immutable bool rs = arg[ 0 ] =='r' && arg[ 1 ] == 's';
		immutable bool rd = arg[ 0 ] =='r' && arg[ 1 ] == 'd';
		
		if( rs || rd  ){
			split( arg, regex( to!string( arg[ 2 ] ) ) ).copy( user_apply );
			number_of_delimiter = arg.count( arg[ 2 ] );
		} else if( r || s || d ){
			split( arg, regex( to!string( arg[ 1 ] ) ) ).copy( user_apply );
			number_of_delimiter = arg.count( arg[ 1 ] );
		} else {
			split( arg, regex( to!string( arg[ 0 ] ) ) ).copy( user_apply );
			number_of_delimiter = arg.count( arg[ 0 ] );
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
	immutable string substitution = recursively_reanme ? user_apply[ 2 ] : "";
	immutable string recursive    = recursively_remove ? user_apply[ 2 ] : user_apply[ 3 ];
	immutable string end_flag     = recursively_remove ? user_apply[ 3 ] : user_apply[ 4 ];
	int       index               = 0;
	int       match_count         = 0;
	
	if( user_apply[ 5 ] != "" )
		index = to!int( user_apply[ 5 ] );
		
	immutable clone_index = index;
	immutable bool action_flag_for_rename = ( action_flag == "s" || action_flag == "rs" ) && number_of_delimiter >= 3;
	immutable bool action_flag_for_remove = ( action_flag == "d" || action_flag == "rd" );
	
	/*
		writeln( "--------------------------" );
		writeln( "action_flag: ", action_flag );
		writeln( "match      : ", match );
		writeln( "subs       : ", substitution );
		writeln( "recursive  : ", recursive );
		writeln( "end_flag   : ", end_flag );
		writeln( "index      : ", index );
		writeln( "delimiter  : ", number_of_delimiter );
		writeln( "--------------------------" );
		writeln( "rename     : ", recursively_reanme );
		writeln( "remove     : ", recursively_remove );
		
		return 0;
	*/
	
	/*********************************************************************/
	/* find files and directories based on what the user has applied for */
	/*********************************************************************/
	
	if( recursively_reanme || recursively_remove ){
		// writeln( "applying for rename: ", recursively_reanme );
		files_and_dirs =
		dirEntries( ".", ( action_flag.indexOf( "r" ) != -1 ? SpanMode.depth : SpanMode.shallow ), false )
			.filter!( file => !file.name.matchAll( regex( match, end_flag ) ).empty() )
			.filter!( file => ( recursive == "b" ? !file.isSymlink : ( recursive == "f" ? !file.isDir : !file.isFile ) ) )
			//.map!( file => ( file.isDir ?  baseName( file.name ) : baseName( file.name ) ) )
			.map!( file => file.name )
			.array;
	}
	
	foreach( _, item; files_and_dirs ){
		writeln( _, " : ", item ); 
	}
	return 0;
}
