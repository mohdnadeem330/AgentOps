trigger ContentDocumentTrigger on ContentDocument (before delete){
 try{    
     new ContentDocumentTriggerHandler().run('ContentDocument'); } catch(Exception e) {  LoggerService.save(LoggerService.addApexLog(e,'ContentDocumentTrigger','ContentDocumentTriggerHandler',''));throw e;
  }
}