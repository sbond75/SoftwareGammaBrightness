// Based on https://gist.github.com/sanekgusev/2c15212db889f1157607d62c19c77da3

// this method ensures that blocks enqueued onto global GCD queues by the previous test method
// have finished executing and can have no side effects on the following test methods
// NOTE: This does not affect any private queues: any queued, but unfinished blocks may still be running off those
// unless properly cancelled by the code managing those queues
func ensureGlobalQueuesDrained() {
    // all of the below only makes sense if we're running on the main thread
    assert(Thread.isMainThread)
    
    // construct an array of all concurrent global queues
    let globalQueues = [
        DispatchQoS.userInteractive,
//        DispatchQoS.userInitiated,
//        DispatchQoS.utility,
//        DispatchQoS.background
        ]
    
    // create a dispatch group
    let dispatchGroup = DispatchGroup()
    
    // submit a barrier block to all of the global concurrent queues
    // the barrier blocks will only be executed after all the previously submitted blocks
    // have finished executing on their respective background queues
    globalQueues.forEach { qos in
//        let block = DispatchWorkItem(qos: qos, flags: .barrier, block: {})
        DispatchQueue.global(qos: qos.qosClass).async(group: dispatchGroup, qos: qos, flags: .barrier, execute: {
            print("Barrier: \(qos)")
        })
    }
    
    // get a reference to main thread's CFRunLoop object
    let runloop = CFRunLoopGetCurrent()
    
    // schedule a block to be submitted onto the main dispatch queue after
    // all background queues have executed our blocks
    
    // by the time out block is called on the main queue, we can safely
    // assume that the global concurrent queues are drained
    // (the barrier blocks we enqueued above were the last ones to be run on them)
    
    // since main queue is a serial queue, it also means that by the time
    // the below block is started executing on the main queue, all the
    // previously submitted to the main queue blocks have finished running,
    // so the main queue is drained as well
    dispatchGroup.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
        CFRunLoopStop(runloop)
    }))
    
    // run a nested runloop on the main thread, so that main GCD queue can continue
    // processing enqueued blocks, including ours above
    
    // this nested runloop will be stopped by a CFRunLoopStop() call from the
    // block we've scheduled onto the main queue
    CFRunLoopRun()
    
    // at this point all global concurrent GCD queues are drained
    // AND the serial main GCD queue is drained as well
}
