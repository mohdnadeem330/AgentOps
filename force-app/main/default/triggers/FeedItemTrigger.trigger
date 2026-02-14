trigger FeedItemTrigger on FeedItem (after insert) {
    try{
        if(!FeedItemTriggerHandler.isSkipFeedItemTrigger){
            new FeedItemTriggerHandler().run('FeedItem');
        }
    }catch(Exception e) {LoggerService.save(LoggerService.addApexLog(e,'FeedItemTrigger','FeedItemTriggerHandler',''));throw e;} 
}