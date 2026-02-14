public with sharing class WhatsAppLinkGenesysController {
    @InvocableMethod
    public static void sendfastTrackLink(List<Id> recordIds) {
        try{
            System.debug('Flow '+recordIds);
            List<Account> acc = [SELECT Id,EncryptedRecordId__c,SendFastTrackEmail__c FROM Account WHERE Id=:recordIds];
            for(Account ac : acc){
                if(ac.EncryptedRecordId__c == null){
                    Blob cryptoKey = Blob.valueOf(System.Label.EncryptionKey);
                    Blob data = Blob.valueOf(ac.Id);
                    Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);
                    String encryptedString = EncodingUtil.base64encode(encryptedData);
                    ac.EncryptedRecordId__c = encryptedString;
                    
                }
                ac.SendFastTrackEmail__c = true;
                ac.FasttrackSentTime__c = datetime.now();
            }
            update acc;
            Set<Id>accIds = new Set<Id>();
            accIds.addAll(recordIds);
            Database.executeBatch(new SendWhatsAppLinkWithBitly(accIds,''),1);
        }catch(Exception e){
          /*  String htmlEmailBody = 'Hello,</br></br> WhatsAppLinkGenesysController sendfastTrackLink has failed because of below error.</br></br>   <b> ' + e.getMessage() + ' </b> </br>   <b> ' + e.getStackTraceString() + ' </b>  ';
            Utilities.sendExceptionEmail('WhatsAppLinkGenesysController','sendfastTrackLink',htmlEmailBody,'WhatsAppLinkGenesysController sendfastTrackLink',e); */
            LoggerService.save(LoggerService.addApexLog(e,'Account Update Failed','WhatsAppLinkGenesysController','sendfastTrackLink')); // Added by Tajinkumar
            //            String htmlEmailBody = 'Hello,</br></br> SendfastTrackWhatsappLinkQueueable execute has failed because of below error.</br></br>   <b> ' + e.getMessage() + ' </b> </br>   <b> ' + e.getStackTraceString() + ' </b> ';
            //            LoggerService.save(LoggerService.addApexLog(e,'WhatsAppLinkGenesysController','sendfastTrackLink',''));
            //            htmlEmailBody += '' ;
            //          htmlEmailBody +=  '' ;
            //            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            //            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'WhatsAppLinkGenesysController sendfastTrackLink', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
        }
    }
}