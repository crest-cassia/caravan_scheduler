package caravan;

import x10.util.ArrayList;
import x10.compiler.Native;
import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;

@NativeCPPInclude("SubProcess.hpp")
@NativeCPPCompilationUnit("SubProcess.cpp")

class readTaskException extends Exception {}

public class SearchEngine {

  static public val pidFilePointers: Rail[Long] = new Rail[Long](5); // [pid, fp for reading, fp for writing, fd for reading, fd for writing]

  @Native("c++", "launchSubProcessWithPipes( #1, (long*) &((#2)->raw[0]) )")
  private native static def launchSubProcessWithPipes( argv: Rail[String], pid_fps: Rail[Long] ): Long;

  @Native("c++", "waitIncomingData( #1, #2, #3 )")
  private native static def waitIncomingData( fd_r: Long, timeout: Long, pid: Long ): Long;

  @Native("c++", "waitPid( #1 )")
  private native static def waitPid( pid: Long ): void;

  @Native("c++", "readLinesUntilEmpty( (FILE*)(#1) )")
  private native static def readLinesUntilEmpty( fp_r: Long ): Rail[String];

  @Native("c++", "writeLine( (FILE*)(#1), #2 )")
  private native static def writeLine( fp_w: Long, line: String ): void;

  public static def launchSearcher( argv: Rail[String] ): Long {
    return launchSubProcessWithPipes( argv, pidFilePointers );
  }

  public static def waitSearcher() {
    val pid = pidFilePointers(0);
    waitPid(pid);
  }

  public static def createInitialTasks(): ArrayList[Task] {
    return readTasks();
  }

  private static def readTasks(): ArrayList[Task] {
    val rc = waitIncomingData( pidFilePointers(3), 3000, pidFilePointers(0) );
    if( rc != 0 ) { throw new readTaskException(); }
    val lines: Rail[String] = readLinesUntilEmpty( pidFilePointers(1) );
    val tasks = new ArrayList[Task]();
    // Console.ERR.println("[debug] got " + lines.size + " lines");
    for( l in lines ) {
      // Console.ERR.println("[debug] parsing " + l);
      val task = parseLine(l);
      tasks.add(task);
    }
    return tasks;
  }

  private static def parseLine( line: String ): Task {
    val split_at = line.indexOf(" ") as Int;
    assert split_at > 0;
    val taskId = Long.parse( line.substring(0n,split_at) );
    val cmd = line.substring(split_at+1n);
    return Task( taskId, cmd );
  }

  public static def sendResult( resultLine: String ): ArrayList[Task] {
    writeLine( pidFilePointers(2), resultLine );
    return readTasks();
  }

  public static def sendEmptyLine() {
    writeLine(pidFilePointers(2), "");
  }
}

