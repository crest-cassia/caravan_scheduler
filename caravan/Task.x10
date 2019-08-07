package caravan;

import x10.io.File;
import x10.io.FileReader;
import x10.util.Timer;
import x10.util.ArrayList;
import x10.util.Pair;
import x10.compiler.Native;

import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;

@NativeCPPInclude("SubProcess.hpp")
@NativeCPPCompilationUnit("SubProcess.cpp")

public struct Task( taskId: Long, cmd: String ) {

  @Native("c++", "chdir( (#1)->c_str() )")
  public native static def chdir( path:String ):Int;

  @Native("c++", "system( (#1)->c_str() )")
  public native static def system( cmd:String ):Int;

  public static def mkdir_p( path:String ): Int {
    return system("mkdir -p " + path);
  }

  @Native("c++", "getCWD()")
  public native static def getCWD(): String;

  public def run( duration:Long, logger: Logger ): Pair[Long,Rail[Double]] {
    val cwd = getCWD();
    if( cwd.length() == 0n ) {
      logger.e("[ERROR] failed to cwd");
      throw new Exception("cwd failed");
    }

    var err:Int = 0n;
    val work_dir = workDirPath();
    err = mkdir_p( workDirPath() );
    if( err != 0n ) {
      logger.e("[ERROR] failed to mkdir " + work_dir );
      throw new Exception("mkdir failed");
    }

    err = chdir(work_dir);
    if( err != 0n ) {
      logger.e("[ERROR] failed to chdir " + work_dir );
      throw new Exception("chdir failed");
    }

    val cmd_with_timeout = commandWithTimeout(duration);
    logger.d("executing: " + cmd_with_timeout);
    // if( here.id == 2 ) { logger.d("executing: " + cmd_with_timeout); }
    val rc = system( cmd_with_timeout );

    err = chdir(cwd);
    if( err != 0n ) {
      logger.e("[ERROR] failed to chdir " + cwd );
      throw new Exception("chdir failed");
    }

    if( rc != 0n ) {
      return Pair[Long,Rail[Double]](rc as Long, new Rail[Double]() );
    }

    val f = new File( resultsFilePath() );
    val results = f.exists() ? parseResults() : (new Rail[Double]() );
    return Pair[Long,Rail[Double]]( 0, results );
  }

  private def parseResults(): Rail[Double] {
    val results = new ArrayList[Double]();
    val f = new File( resultsFilePath() );
    val reader = new FileReader(f);
    for( line in reader.lines() ) {
      val trimmed = line.trim();
      if( trimmed.length() > 0 ) {
        val parsed = trimmed.split(" "); // split by white space
        for( s in parsed ) {
          val d = Double.parse(s);
          results.add(d);
        }
      }
    }
    reader.close();
    return results.toRail();
  }

  public def workDirPath(): String {
    val base = OptionParser.getString("CARAVAN_WORK_BASE_DIR");
    return String.format("%s/w%04d/w%07d", [base, taskId/1000, taskId as Any]);
  }

  public def resultsFilePath(): String {
    return workDirPath() + "/_results.txt";
  }

  public def commandWithTimeout(duration:Long): String {
    val toutcmd = OptionParser.getString("CARAVAN_TIMEOUT_CMD");
    if( toutcmd.length() > 0 && duration >= 0 ) {
      return String.format("%s %d %s", [toutcmd, duration, cmd as Any]);
    }
    else {
      return cmd;
    }
  }
  
  public def toString(): String {
    return "{ taskId : " + taskId + ", cmd : " + cmd + " }";
  }
}

