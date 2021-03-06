package caravan;

import x10.lang.System;

class Main {

  static public def main( args: Rail[String] ) {
    if( args.size == 0 ) {
      Console.ERR.println("  Usage: ./a.out [command of searcher]");
      OptionParser.printHelp();
      throw new Exception("Invalid argument");
    }

    OptionParser.printDetectedOptions();

    val numProcPerBuf: Long = OptionParser.getLong("CARAVAN_NUM_PROC_PER_BUF");
    val timeOut: Long = OptionParser.getLong("CARAVAN_TIMEOUT") * 1000;

    val m = new Administrator();
    m.run( args, timeOut, numProcPerBuf );
  }
}

