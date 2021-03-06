package caravan;

import x10.lang.System;
import x10.compiler.*;
import x10.util.ArrayList;
import x10.util.Timer;
import x10.compiler.Pragma;

class JobConsumer {

  val m_refBuffer: GlobalRef[JobBuffer];
  val m_timer = new Timer();
  var m_timeOut: Long = -1;
  val m_logger: Logger;
  val m_tasks: Deque[Task];
  val m_results: ArrayList[TaskResult];
  val m_sendInterval: Long;
  var m_lastResultSendTime: Long;

  def this( _refBuffer: GlobalRef[JobBuffer], refTimeForLogger: Long, sendInterval: Long ) {
    m_refBuffer = _refBuffer;
    m_logger = new Logger( refTimeForLogger );
    m_tasks = new Deque[Task]();
    m_results = new ArrayList[TaskResult]();
    m_sendInterval = sendInterval;
    saveResultsDone();
  }

  private def d(s:String) {
    // if( here.id == 2 ) { m_logger.d(s); }
    m_logger.d(s);
  }

  private def w(s:String) {
    m_logger.w(s);
  }

  def setExpiration( timeOutMilliTime: Long ) {
    m_timeOut = timeOutMilliTime;
  }

  private def saveResultsDone() {
    m_lastResultSendTime = m_timer.milliTime();
  }

  def warnForLongProc( msg: String, proc: ()=>void ) {
    val from = m_timer.milliTime() - m_logger.m_refTime;
    proc();
    val to = m_timer.milliTime() - m_logger.m_refTime;
    if( (to - from) > 5000 ) {
      w("[Warning] proc takes more than 5 sec: " + from + " - " + to + " : " + msg);
    }
  }

  def run() {
    d("Consumer starting");
    val refBuf = m_refBuffer;

    getTasksFromBufferOrRegisterFreePlace();
    d("Consumer got initial tasks from buffer");

    while( m_tasks.size() > 0 ) {
      val b = isExpired();

      if( !b ) {
        val task = m_tasks.popFirst();
        val result = runTask( task );
        m_results.add( result );
        d("Consumer finished task " + task.taskId);
      }

      if( readyToSendResults() || b ) {
        val results = m_results.toRail();
        m_results.clear();
        warnForLongProc("saveResutls", () => {
          val refCons = new GlobalRef[JobConsumer]( this );
          at( refBuf ) {
            if(b) {
              refBuf().atomicDo( () => {
                refBuf().registerFreePlace( here, m_timeOut );
              });
            }
            refBuf().saveResults( results, refCons.home );
          }
          saveResultsDone();
          d("saveResults done");
        });
        if(b) { return; }
      }

      if( m_tasks.size() == 0 ) {
        d("Consumer task queue is empty. getting tasks");
        getTasksFromBufferOrRegisterFreePlace();
        d("Consumer got " + m_tasks.size() + " tasks from buffer");
      }
    }

    d("Consumer finished");
  }

  private def runTask( task: Task ): TaskResult {
    val taskId = task.taskId;
    val startAt = m_timer.milliTime();
    val runPlace = here.id;
    val duration = remainingTimeInSec();
    val rcResults = task.run(duration, m_logger);
    val rc = rcResults.first;
    val results = rcResults.second;
    val finishAt = m_timer.milliTime();
    val tr = TaskResult( taskId, rc, results, runPlace, startAt, finishAt );
    return tr;
  }

  private def readyToSendResults(): Boolean {
    if( m_tasks.size() == 0 ) { return true; }
    val now = m_timer.milliTime();
    return ( now - m_lastResultSendTime >= m_sendInterval );
  }

  def getTasksFromBufferOrRegisterFreePlace() {
    val refBuf = m_refBuffer;
    val timeOut = m_timeOut;
    val consPlace = here;
    val refCons = new GlobalRef[JobConsumer]( this );
    warnForLongProc("popTasks", () => {
      val tasks = at( refBuf ) {
        return refBuf().popTasksOrRegisterFreePlace( consPlace, timeOut );
      };
      m_tasks.pushLast(tasks);
    });
  }

  private def remainingTimeInSec(): Long {
    if( m_timeOut <= 0 ) { return -1; }
    else {
      val d = (m_timeOut - m_timer.milliTime())/1000 as Long;
      return (d > 0) ? d : 1;
    }
  }

  private def isExpired(): Boolean {
    return ((m_timeOut > 0) && (m_timer.milliTime() > m_timeOut));
  }
}

