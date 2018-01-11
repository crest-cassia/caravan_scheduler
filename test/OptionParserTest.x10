package test;

import caravan.OptionParser;
import x10.lang.System;

class OptionParserTest {

  static public def p( obj:Any ): void {
    Console.ERR.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> OptionParserTest");
    testDefaults();
  }

  static public def testDefaults(): void {
    val opts = OptionParser.availableOptions;
    assert OptionParser.getLong("CARAVAN_NUM_PROC_PER_BUF") == Long.parse(opts(0)(2));
    assert OptionParser.getLong("CARAVAN_TIMEOUT") == Long.parse(opts(1)(2));
    assert OptionParser.getLong("CARAVAN_SEND_RESULT_INTERVAL") == Long.parse(opts(2)(2));
    assert OptionParser.getLong("CARAVAN_LOG_LEVEL") == Long.parse(opts(3)(2));

    val detected = OptionParser.detectedOptions();
    assert detected.size() == 0 : detected;
  }
}

