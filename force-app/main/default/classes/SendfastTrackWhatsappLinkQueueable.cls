public without sharing class SendfastTrackWhatsappLinkQueueable implements Queueable {
    
    public String bitlyUrl;
    public String recordId;
    
    public SendfastTrackWhatsappLinkQueueable(String bitlyurl,String recordId) {
        this.bitlyUrl = bitlyurl;
        this.recordId = recordId;
    }
    
    public void execute(QueueableContext context) {
        try{
            Account acc = new Account();
            acc.Id = recordId;
            if(this.bitlyUrl != null){
                acc.bitlyURL__c = this.bitlyUrl;
            }
            acc.WhatsAppDateTime__c = System.now();
            acc.SendFastTrackEmail__c = false;
            update acc;
        }catch(Exception e){
//            LoggerService.save(LoggerService.addApexLog(e,'SendfastTrackWhatsappLinkQueueable','execute',''));
           /* String htmlEmailBody = 'Hello,</br></br> SendfastTrackWhatsappLinkQueueable execute has failed because of below error.</br></br>   <b> ' + e.getMessage() + ' </b> </br>   <b> ' + e.getStackTraceString() + ' </b> ';
            Utilities.sendExceptionEmail('SendfastTrackWhatsappLinkQueueable','execute',htmlEmailBody,'SendfastTrackWhatsappLinkQueueable execute',e); */
            LoggerService.save(LoggerService.addApexLog(e,'Account Update Failed','SendfastTrackWhatsappLinkQueueable','execute')); // Added by Tajinkumar
            
//            htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
//            htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
//            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
//            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'SendfastTrackWhatsappLinkQueueable execute', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
        }
    }
}