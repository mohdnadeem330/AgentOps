trigger ContentDocumentLinkTrigger on ContentDocumentLink (  before insert,before update,after update,after insert) {
  try {    
    new ContentDocumentLinkTriggerHandler().run('ContentDocumentLink'); } catch(Exception e) {  LoggerService.save(LoggerService.addApexLog(e,'ContentDocumentLinkTrigger','ContentDocumentLinkTriggerHandler',''));throw e;
  }
}